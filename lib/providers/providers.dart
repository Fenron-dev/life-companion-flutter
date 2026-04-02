import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/ai_service.dart';
import '../services/database.dart';
import '../services/local_llm_service.dart';
import '../services/ollama_service.dart';
import '../utils/streak_calculator.dart';

// --- LLM Settings ---

class LlmSettings {
  /// GPU layers to offload (0 = CPU-only, 999 = all layers on GPU).
  /// Default 0 to avoid Vulkan crashes on unsupported devices.
  final int gpuLayers;

  /// Context window size in tokens (affects RAM usage).
  final int contextSize;

  /// Max tokens to generate per response.
  final int maxTokens;

  /// Sampling temperature (0.1 = deterministic, 1.5 = creative).
  final double temperature;

  /// Enable Qwen3 thinking mode (think blocks). Can cause OOM on small devices.
  final bool enableThinking;

  const LlmSettings({
    this.gpuLayers = 0,
    this.contextSize = 2048,
    this.maxTokens = 512,
    this.temperature = 0.7,
    this.enableThinking = false,
  });

  LlmSettings copyWith({
    int? gpuLayers,
    int? contextSize,
    int? maxTokens,
    double? temperature,
    bool? enableThinking,
  }) =>
      LlmSettings(
        gpuLayers: gpuLayers ?? this.gpuLayers,
        contextSize: contextSize ?? this.contextSize,
        maxTokens: maxTokens ?? this.maxTokens,
        temperature: temperature ?? this.temperature,
        enableThinking: enableThinking ?? this.enableThinking,
      );
}

class LlmSettingsNotifier extends StateNotifier<LlmSettings> {
  LlmSettingsNotifier() : super(const LlmSettings());

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = LlmSettings(
      gpuLayers: prefs.getInt('llm_gpu_layers') ?? 0,
      contextSize: prefs.getInt('llm_context_size') ?? 2048,
      maxTokens: prefs.getInt('llm_max_tokens') ?? 512,
      temperature: prefs.getDouble('llm_temperature') ?? 0.7,
      enableThinking: prefs.getBool('llm_enable_thinking') ?? false,
    );
  }

  Future<void> update({
    int? gpuLayers,
    int? contextSize,
    int? maxTokens,
    double? temperature,
    bool? enableThinking,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (gpuLayers != null) await prefs.setInt('llm_gpu_layers', gpuLayers);
    if (contextSize != null) await prefs.setInt('llm_context_size', contextSize);
    if (maxTokens != null) await prefs.setInt('llm_max_tokens', maxTokens);
    if (temperature != null) await prefs.setDouble('llm_temperature', temperature);
    if (enableThinking != null) {
      await prefs.setBool('llm_enable_thinking', enableThinking);
    }
    state = state.copyWith(
      gpuLayers: gpuLayers,
      contextSize: contextSize,
      maxTokens: maxTokens,
      temperature: temperature,
      enableThinking: enableThinking,
    );
  }
}

final llmSettingsProvider =
    StateNotifierProvider<LlmSettingsNotifier, LlmSettings>((ref) {
  return LlmSettingsNotifier();
});

// --- Database ---

final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Database must be initialized before use');
});

// --- Ollama ---

final ollamaConfigProvider =
    StateNotifierProvider<OllamaConfigNotifier, OllamaConfig>((ref) {
  return OllamaConfigNotifier();
});

class OllamaConfigNotifier extends StateNotifier<OllamaConfig> {
  OllamaConfigNotifier()
      : super(const OllamaConfig(baseUrl: 'http://localhost:11434'));

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = OllamaConfig(
      baseUrl: prefs.getString('ollama_url') ?? 'http://localhost:11434',
      model: prefs.getString('ollama_model') ?? 'llama3.2',
    );
  }

  Future<void> setUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ollama_url', url);
    state = state.copyWith(baseUrl: url);
  }

  Future<void> setModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ollama_model', model);
    state = state.copyWith(model: model);
  }
}

final ollamaServiceProvider = Provider<OllamaService>((ref) {
  final config = ref.watch(ollamaConfigProvider);
  return OllamaService(config: config);
});

// --- Local LLM ---

final localLLMServiceProvider = Provider<LocalLLMService>((ref) {
  throw UnimplementedError('LocalLLMService must be initialized before use');
});

class SelectedLocalModelNotifier extends StateNotifier<LocalModelConfig> {
  SelectedLocalModelNotifier() : super(LocalModelConfigs.qwen35);

  LocalModelConfig get current => state;

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('local_model_id') ?? LocalModelConfigs.qwen35.id;
    state = LocalModelConfigs.fromId(id);
  }

  Future<void> selectModel(LocalModelConfig model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_model_id', model.id);
    state = model;
  }
}

final selectedLocalModelProvider =
    StateNotifierProvider<SelectedLocalModelNotifier, LocalModelConfig>((ref) {
  return SelectedLocalModelNotifier();
});

// --- Unified AI Service ---

final aiServiceProvider = Provider<AIService>((ref) {
  final ollama = ref.watch(ollamaServiceProvider);
  final localLLM = ref.watch(localLLMServiceProvider);
  final settings = ref.watch(llmSettingsProvider);
  return AIService(ollama: ollama, localLLM: localLLM, settings: settings);
});

// --- Location Consent ---

final locationConsentProvider =
    StateNotifierProvider<LocationConsentNotifier, bool>((ref) {
  return LocationConsentNotifier();
});

class LocationConsentNotifier extends StateNotifier<bool> {
  LocationConsentNotifier() : super(false);

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('location_consent') ?? false;
  }

  Future<void> setConsent(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_consent', value);
    state = value;
  }
}

// --- Active Tab ---

final activeTabProvider = StateProvider<int>((ref) => 0);

// --- Notes Streams ---

final allNotesProvider = StreamProvider<List<DailyNote>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllNotes();
});

final recentNotesProvider = StreamProvider<List<DailyNote>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchRecentNotes(limit: 3);
});

final noteDatesProvider = StreamProvider<List<String>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchNoteDates();
});

// --- Logs ---

final todayLogsProvider = StreamProvider<List<RawLog>>((ref) {
  final db = ref.watch(databaseProvider);
  final today = DateTime.now();
  final dateStr =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  return db.watchLogsForDate(dateStr);
});

// --- Streak ---

final streakProvider = Provider<int>((ref) {
  final notesAsync = ref.watch(allNotesProvider);
  return notesAsync.when(
    data: (notes) => StreakCalculator.calculate(notes),
    loading: () => 0,
    error: (_, _) => 0,
  );
});
