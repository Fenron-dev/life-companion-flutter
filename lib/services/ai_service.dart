import '../providers/providers.dart' show LlmSettings;
import 'local_llm_service.dart';
import 'ollama_service.dart';

/// Which AI backend is currently active
enum AIBackend {
  ollama,
  local,
  none,
}

/// Unified AI service that auto-detects Ollama availability
/// and falls back to the local on-device LLM when the server is unreachable.
///
/// Priority: Ollama (when reachable) → Local Qwen 3.5 0.8B (always available)
class AIService {
  final OllamaService _ollama;
  final LocalLLMService _localLLM;
  final LlmSettings settings;

  AIBackend _currentBackend = AIBackend.none;
  AIBackend get currentBackend => _currentBackend;

  bool autoFallback = true;

  /// Force a specific backend (null = auto)
  AIBackend? forcedBackend;

  AIService({
    required OllamaService ollama,
    required LocalLLMService localLLM,
    required this.settings,
  })  : _ollama = ollama,
        _localLLM = localLLM;

  OllamaService get ollama => _ollama;
  LocalLLMService get localLLM => _localLLM;

  /// Determine which backend to use right now
  Future<AIBackend> resolveBackend() async {
    if (forcedBackend != null) {
      _currentBackend = forcedBackend!;
      return _currentBackend;
    }

    // Try Ollama first
    try {
      final connected = await _ollama.testConnection().timeout(
        const Duration(seconds: 3),
        onTimeout: () => false,
      );
      if (connected) {
        _currentBackend = AIBackend.ollama;
        return AIBackend.ollama;
      }
    } catch (_) {
      // Ollama not reachable
    }

    // Fallback to local if model is ready
    if (autoFallback && _localLLM.isReady) {
      _currentBackend = AIBackend.local;
      return AIBackend.local;
    }

    // Try loading local model if downloaded but not loaded
    if (autoFallback && await _localLLM.isModelDownloaded()) {
      try {
        await _localLLM.loadModel(
          gpuLayers: settings.gpuLayers,
          contextSize: settings.contextSize,
        );
        _currentBackend = AIBackend.local;
        return AIBackend.local;
      } catch (_) {
        // Error stored in _localLLM.errorMessage
      }
    }

    _currentBackend = AIBackend.none;
    return AIBackend.none;
  }

  /// Chat with auto-backend selection (non-streaming)
  Future<String> chat({
    required String message,
    String? context,
  }) async {
    final backend = await resolveBackend();

    switch (backend) {
      case AIBackend.ollama:
        return _ollama.chatWithCompanion(
          message: message,
          dayContext: context ?? '',
        );
      case AIBackend.local:
        return _localLLM.chat(
          message: message,
          context: context,
          maxTokens: settings.maxTokens,
          temperature: settings.temperature,
          enableThinking: settings.enableThinking,
        );
      case AIBackend.none:
        final err = _localLLM.errorMessage;
        if (err != null) {
          return 'Lokales Modell konnte nicht geladen werden: $err';
        }
        return 'Kein AI-Backend verfügbar. Bitte Ollama-Server starten oder lokales Modell herunterladen.';
    }
  }

  /// Stream chat with auto-backend selection
  Stream<String> chatStream({
    required String message,
    String? context,
  }) async* {
    final backend = await resolveBackend();

    switch (backend) {
      case AIBackend.ollama:
        yield* _ollama.chatStream(
          message: message,
          systemPrompt:
              'You are "The Companion", a personal AI in the user\'s life tracking app. '
              'You are warm, slightly philosophical, and very supportive. '
              'Respond in the same language the user writes in.',
          context: context,
        );
      case AIBackend.local:
        yield* _localLLM.chatStream(
          message: message,
          context: context,
          maxTokens: settings.maxTokens,
          temperature: settings.temperature,
          enableThinking: settings.enableThinking,
        );
      case AIBackend.none:
        final err = _localLLM.errorMessage;
        if (err != null) {
          yield 'Lokales Modell konnte nicht geladen werden: $err';
        } else {
          yield 'Kein AI-Backend verfügbar. Bitte Ollama-Server starten oder lokales Modell herunterladen.';
        }
    }
  }

  /// Summarize the day with auto-backend selection
  Future<String> summarizeDay({
    required List<String> notes,
    required List<Map<String, dynamic>> logs,
  }) async {
    final backend = await resolveBackend();

    switch (backend) {
      case AIBackend.ollama:
        return _ollama.summarizeDay(notes: notes, logs: logs);
      case AIBackend.local:
        return _localLLM.summarizeDay(notes: notes, logs: logs);
      case AIBackend.none:
        return 'Kein AI-Backend verfügbar.';
    }
  }

  /// Get a human-readable status string
  String get statusText {
    switch (_currentBackend) {
      case AIBackend.ollama:
        return 'Ollama (${_ollama.config.model})';
      case AIBackend.local:
        return 'Lokal (Qwen 3.5 0.8B)';
      case AIBackend.none:
        return 'Nicht verbunden';
    }
  }

  Future<void> dispose() async {
    await _localLLM.dispose();
    _ollama.dispose();
  }
}
