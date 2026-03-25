import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OllamaConfig {
  final String baseUrl;
  final String model;
  final Duration timeout;

  const OllamaConfig({
    required this.baseUrl,
    this.model = 'llama3.2',
    this.timeout = const Duration(seconds: 120),
  });

  OllamaConfig copyWith({String? baseUrl, String? model, Duration? timeout}) {
    return OllamaConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      timeout: timeout ?? this.timeout,
    );
  }
}

class OllamaService {
  OllamaConfig _config;
  final http.Client _client;

  OllamaService({required OllamaConfig config, http.Client? client})
      : _config = config,
        _client = client ?? http.Client();

  OllamaConfig get config => _config;

  void updateConfig(OllamaConfig config) {
    _config = config;
  }

  /// Test connection to Ollama server
  Future<bool> testConnection() async {
    try {
      final uri = Uri.parse('${_config.baseUrl}/api/tags');
      final response = await _client.get(uri).timeout(_config.timeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Get list of available models
  Future<List<String>> getModels() async {
    try {
      final uri = Uri.parse('${_config.baseUrl}/api/tags');
      final response = await _client.get(uri).timeout(_config.timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final models = data['models'] as List<dynamic>? ?? [];
        return models.map((m) => m['name'] as String).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Send a chat completion request (non-streaming)
  Future<String> chat({
    required String message,
    String? systemPrompt,
    String? context,
  }) async {
    final prompt = _buildPrompt(
      message: message,
      systemPrompt: systemPrompt,
      context: context,
    );

    final uri = Uri.parse('${_config.baseUrl}/api/chat');
    final body = jsonEncode({
      'model': _config.model,
      'messages': prompt,
      'stream': false,
    });

    final response = await _client
        .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(_config.timeout);

    if (response.statusCode != 200) {
      throw OllamaException(
        'Server responded with ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = data['message']?['content'] as String?;
    if (content == null || content.isEmpty) {
      throw OllamaException('Empty response from model');
    }
    return content;
  }

  /// Stream a chat response
  Stream<String> chatStream({
    required String message,
    String? systemPrompt,
    String? context,
  }) async* {
    final prompt = _buildPrompt(
      message: message,
      systemPrompt: systemPrompt,
      context: context,
    );

    final uri = Uri.parse('${_config.baseUrl}/api/chat');
    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'model': _config.model,
        'messages': prompt,
        'stream': true,
      });

    final streamedResponse =
        await _client.send(request).timeout(_config.timeout);

    if (streamedResponse.statusCode != 200) {
      throw OllamaException(
        'Server responded with ${streamedResponse.statusCode}',
      );
    }

    await for (final chunk
        in streamedResponse.stream.transform(utf8.decoder)) {
      for (final line in chunk.split('\n')) {
        if (line.trim().isEmpty) continue;
        try {
          final data = jsonDecode(line) as Map<String, dynamic>;
          final content = data['message']?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            yield content;
          }
        } catch (_) {
          // Skip malformed JSON chunks
        }
      }
    }
  }

  /// Summarize the day's data
  Future<String> summarizeDay({
    required List<String> notes,
    required List<Map<String, dynamic>> logs,
  }) async {
    final context = StringBuffer();
    context.writeln('[BEGIN USER NOTES]');
    for (final note in notes) {
      context.writeln(note);
    }
    context.writeln('[END USER NOTES]');
    context.writeln('[BEGIN AUTO LOGS]');
    context.writeln(jsonEncode(logs));
    context.writeln('[END AUTO LOGS]');

    return chat(
      message:
          'Provide a warm, insightful summary of my day. Mention the weather or activity if relevant. Keep it personal and encouraging.',
      systemPrompt:
          'You are a life companion AI. Summarize the user\'s day based on their notes and automatic logs. Be warm, slightly philosophical, and supportive. Respond in the same language the user writes in.',
      context: context.toString(),
    );
  }

  /// Chat with the companion
  Future<String> chatWithCompanion({
    required String message,
    required String dayContext,
  }) async {
    return chat(
      message: message,
      systemPrompt:
          'You are "The Companion", a personal AI that lives in the user\'s life tracking app. You are warm, slightly philosophical, and very supportive. Respond in the same language the user writes in.',
      context: dayContext,
    );
  }

  List<Map<String, String>> _buildPrompt({
    required String message,
    String? systemPrompt,
    String? context,
  }) {
    final messages = <Map<String, String>>[];

    if (systemPrompt != null) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }

    if (context != null && context.isNotEmpty) {
      messages.add({
        'role': 'system',
        'content': 'Context about the user\'s day:\n$context',
      });
    }

    messages.add({'role': 'user', 'content': message});

    return messages;
  }

  void dispose() {
    _client.close();
  }
}

class OllamaException implements Exception {
  final String message;
  const OllamaException(this.message);

  @override
  String toString() => 'OllamaException: $message';
}
