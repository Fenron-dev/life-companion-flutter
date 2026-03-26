import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/providers.dart';
import 'screens/home_screen.dart';
import 'services/database.dart';
import 'services/local_llm_service.dart';
import 'utils/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  final database = await AppDatabase.getInstance();

  // Load persisted preferences
  final ollamaNotifier = OllamaConfigNotifier();
  await ollamaNotifier.loadFromPrefs();

  final locationNotifier = LocationConsentNotifier();
  await locationNotifier.loadFromPrefs();

  final llmSettingsNotifier = LlmSettingsNotifier();
  await llmSettingsNotifier.loadFromPrefs();

  // Initialize local LLM service (model loaded lazily on first use)
  final localLLM = LocalLLMService();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        ollamaConfigProvider.overrideWith((_) => ollamaNotifier),
        locationConsentProvider.overrideWith((_) => locationNotifier),
        llmSettingsProvider.overrideWith((_) => llmSettingsNotifier),
        localLLMServiceProvider.overrideWithValue(localLLM),
      ],
      child: const LifeCompanionApp(),
    ),
  );
}

class LifeCompanionApp extends StatelessWidget {
  const LifeCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Life Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomeScreen(),
    );
  }
}
