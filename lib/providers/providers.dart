import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/ai_service.dart';
import '../services/database.dart';
import '../services/local_llm_service.dart';
import '../services/ollama_service.dart';
import '../utils/streak_calculator.dart';

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

// --- Unified AI Service ---

final aiServiceProvider = Provider<AIService>((ref) {
  final ollama = ref.watch(ollamaServiceProvider);
  final localLLM = ref.watch(localLLMServiceProvider);
  return AIService(ollama: ollama, localLLM: localLLM);
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
