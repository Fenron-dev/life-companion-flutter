import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:llamadart/llamadart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Download progress callback: (bytesReceived, totalBytes)
typedef DownloadProgressCallback = void Function(int received, int total);

/// Status of the local LLM engine
enum LocalLLMStatus {
  notDownloaded,
  downloading,
  loading,
  ready,
  error,
}

/// Configuration for a downloadable local GGUF model.
class LocalModelConfig {
  final String id;
  final String displayName;
  final String description;
  final String fileName;
  final String downloadUrl;
  final int sizeBytes;

  const LocalModelConfig({
    required this.id,
    required this.displayName,
    required this.description,
    required this.fileName,
    required this.downloadUrl,
    required this.sizeBytes,
  });
}

/// Available local model options.
class LocalModelConfigs {
  static const qwen35 = LocalModelConfig(
    id: 'qwen35_0.8b',
    displayName: 'Qwen 3.5 0.8B',
    description: 'Q4_K_M · ~533 MB',
    fileName: 'Qwen3.5-0.8B-Q4_K_M.gguf',
    downloadUrl:
        'https://huggingface.co/unsloth/Qwen3.5-0.8B-GGUF/resolve/main/Qwen3.5-0.8B-Q4_K_M.gguf',
    sizeBytes: 559000000,
  );

  static const bonsai17b = LocalModelConfig(
    id: 'bonsai_1.7b',
    displayName: 'Bonsai 1.7B',
    description: 'Q4_K_M · ~1.1 GB',
    fileName: 'Bonsai-1.7B-Q4_K_M.gguf',
    downloadUrl:
        'https://huggingface.co/prism-ml/Bonsai-1.7B-gguf/resolve/main/Bonsai-1.7B-Q4_K_M.gguf',
    sizeBytes: 1100000000,
  );

  static const bonsai4b = LocalModelConfig(
    id: 'bonsai_4b',
    displayName: 'Bonsai 4B',
    description: 'Q4_K_M · ~2.6 GB',
    fileName: 'Bonsai-4B-Q4_K_M.gguf',
    downloadUrl:
        'https://huggingface.co/prism-ml/Bonsai-4B-gguf/resolve/main/Bonsai-4B-Q4_K_M.gguf',
    sizeBytes: 2600000000,
  );

  static const all = [qwen35, bonsai17b, bonsai4b];

  static LocalModelConfig fromId(String id) =>
      all.firstWhere((m) => m.id == id, orElse: () => qwen35);
}

/// Service for running a local GGUF model on-device via llamadart (llama.cpp).
class LocalLLMService {
  LocalModelConfig _selectedModel = LocalModelConfigs.qwen35;
  LocalModelConfig get selectedModel => _selectedModel;

  LlamaEngine? _engine;
  ChatSession? _chatSession;
  LocalLLMStatus _status = LocalLLMStatus.notDownloaded;
  String? _errorMessage;
  String? _modelPath;
  int? _loadedGpuLayers;
  int? _loadedContextSize;

  LocalLLMStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isReady => _status == LocalLLMStatus.ready;

  /// Switch to a different model. Disposes the loaded engine if needed.
  Future<void> setModel(LocalModelConfig model) async {
    if (_selectedModel.id == model.id) return;
    await dispose();
    _selectedModel = model;
    _modelPath = null;
  }

  /// Get the local model file path for the currently selected model.
  Future<String> get _modelFilePath async {
    if (_modelPath != null) return _modelPath!;
    final dir = await getApplicationDocumentsDirectory();
    _modelPath = p.join(dir.path, 'models', _selectedModel.fileName);
    return _modelPath!;
  }

  /// Check if the model file exists on device
  Future<bool> isModelDownloaded() async {
    final path = await _modelFilePath;
    final file = File(path);
    if (!await file.exists()) return false;
    // Verify file isn't truncated (at least 90% of expected size)
    final size = await file.length();
    return size > _selectedModel.sizeBytes * 0.9;
  }

  /// Download the GGUF model file with progress reporting
  Future<void> downloadModel({DownloadProgressCallback? onProgress}) async {
    _status = LocalLLMStatus.downloading;
    _errorMessage = null;

    try {
      final path = await _modelFilePath;
      final dir = Directory(p.dirname(path));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final file = File(path);
      final request = http.Request('GET', Uri.parse(_selectedModel.downloadUrl));
      final client = http.Client();

      try {
        final response = await client.send(request);

        if (response.statusCode != 200) {
          throw Exception('Download failed: HTTP ${response.statusCode}');
        }

        final totalBytes = response.contentLength ?? _selectedModel.sizeBytes;
        int receivedBytes = 0;
        final sink = file.openWrite();

        await for (final chunk in response.stream) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          onProgress?.call(receivedBytes, totalBytes);
        }

        await sink.flush();
        await sink.close();
      } finally {
        client.close();
      }

      // Verify download
      final downloadedSize = await file.length();
      if (downloadedSize < _selectedModel.sizeBytes * 0.9) {
        await file.delete();
        throw Exception('Download incomplete: $downloadedSize bytes');
      }

      _status = LocalLLMStatus.notDownloaded; // Will be set to ready on load
    } catch (e) {
      _status = LocalLLMStatus.error;
      _errorMessage = e.toString();
      rethrow;
    }
  }

  /// Delete the downloaded model file
  Future<void> deleteModel() async {
    await dispose();
    final path = await _modelFilePath;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    _status = LocalLLMStatus.notDownloaded;
  }

  /// Get downloaded model file size in bytes
  Future<int> getModelFileSize() async {
    final path = await _modelFilePath;
    final file = File(path);
    if (await file.exists()) {
      return file.length();
    }
    return 0;
  }

  /// Initialize the engine and load the model.
  /// [gpuLayers]: 0 = CPU-only (safe default), 999 = all layers on GPU.
  /// [contextSize]: context window in tokens.
  /// If already loaded with the same params, this is a no-op.
  Future<void> loadModel({int gpuLayers = 0, int contextSize = 2048}) async {
    // Already loaded with same params → nothing to do
    if (_engine != null &&
        _loadedGpuLayers == gpuLayers &&
        _loadedContextSize == contextSize) {
      _status = LocalLLMStatus.ready;
      return;
    }

    // Params changed → unload first
    if (_engine != null) await dispose();

    final downloaded = await isModelDownloaded();
    if (!downloaded) {
      _status = LocalLLMStatus.notDownloaded;
      throw Exception('Model not downloaded yet');
    }

    _status = LocalLLMStatus.loading;
    _errorMessage = null;

    try {
      final path = await _modelFilePath;
      _engine = LlamaEngine(LlamaBackend());
      await _engine!.loadModel(
        path,
        modelParams: ModelParams(
          gpuLayers: gpuLayers,
          contextSize: contextSize,
        ),
      );
      _loadedGpuLayers = gpuLayers;
      _loadedContextSize = contextSize;
      _status = LocalLLMStatus.ready;
    } catch (e) {
      _status = LocalLLMStatus.error;
      _errorMessage = e.toString();
      _engine = null;
      rethrow;
    }
  }

  /// Create or reuse a chat session
  ChatSession _getOrCreateSession({String? systemPrompt}) {
    if (_chatSession != null) return _chatSession!;
    _chatSession = ChatSession(
      _engine!,
      systemPrompt: systemPrompt ??
          'You are "The Companion", a personal AI in a life tracking app. '
              'You are warm, slightly philosophical, and supportive. '
              'Respond in the same language the user writes in. '
              'Keep responses concise.',
    );
    return _chatSession!;
  }

  /// Chat with the local model (streaming).
  Stream<String> chatStream({
    required String message,
    String? systemPrompt,
    String? context,
    int maxTokens = 512,
    double temperature = 0.7,
    bool enableThinking = false,
  }) async* {
    if (_engine == null) {
      throw Exception('Engine not loaded');
    }

    final userMessage = StringBuffer();
    if (context != null && context.isNotEmpty) {
      userMessage.writeln('Context about the user\'s day:');
      userMessage.writeln(context);
      userMessage.writeln();
    }
    userMessage.write(message);

    final session = _getOrCreateSession(systemPrompt: systemPrompt);

    try {
      await for (final chunk in session.create(
        [LlamaTextContent(userMessage.toString())],
        enableThinking: enableThinking,
        params: GenerationParams(maxTokens: maxTokens, temp: temperature),
      )) {
        final content = chunk.choices.firstOrNull?.delta.content;
        if (content != null && content.isNotEmpty) {
          yield content;
        }
      }
    } catch (e) {
      // Reset session on any error so the next call starts fresh.
      _chatSession = null;
      rethrow;
    }
  }

  /// Chat with the local model (non-streaming, returns full response).
  Future<String> chat({
    required String message,
    String? systemPrompt,
    String? context,
    int maxTokens = 512,
    double temperature = 0.7,
    bool enableThinking = false,
  }) async {
    final buffer = StringBuffer();
    await for (final chunk in chatStream(
      message: message,
      systemPrompt: systemPrompt,
      context: context,
      maxTokens: maxTokens,
      temperature: temperature,
      enableThinking: enableThinking,
    )) {
      buffer.write(chunk);
    }
    return buffer.toString();
  }

  /// Summarize the day
  Future<String> summarizeDay({
    required List<String> notes,
    required List<Map<String, dynamic>> logs,
  }) async {
    final context = StringBuffer()
      ..writeln('[BEGIN USER NOTES]')
      ..writeln(notes.join('\n'))
      ..writeln('[END USER NOTES]')
      ..writeln('[BEGIN AUTO LOGS]')
      ..writeln(logs.toString())
      ..writeln('[END AUTO LOGS]');

    return chat(
      message:
          'Provide a warm, insightful summary of my day. Mention the weather or activity if relevant. Keep it personal and encouraging. Be concise.',
      systemPrompt:
          'You are a life companion AI. Summarize the user\'s day based on their notes and logs. '
          'Be warm, slightly philosophical, and supportive. '
          'Respond in the same language the user writes in.',
      context: context.toString(),
    );
  }

  /// Reset the chat session (clears conversation history)
  void resetSession() {
    _chatSession = null;
  }

  /// Dispose engine and free memory
  Future<void> dispose() async {
    _chatSession = null;
    if (_engine != null) {
      await _engine!.dispose();
      _engine = null;
    }
    _status = LocalLLMStatus.notDownloaded;
  }
}
