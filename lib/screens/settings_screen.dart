import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../services/ai_service.dart';
import '../services/local_llm_service.dart';
import '../utils/theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _urlController = TextEditingController();
  bool _connectionOk = false;
  bool _testing = false;
  List<String> _availableModels = [];

  // Local LLM state
  bool _isDownloading = false;
  double _downloadProgress = 0;
  bool _modelDownloaded = false;
  int _modelFileSize = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final config = ref.read(ollamaConfigProvider);
      _urlController.text = config.baseUrl;
      _checkLocalModel();
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _checkLocalModel() async {
    final localLLM = ref.read(localLLMServiceProvider);
    final downloaded = await localLLM.isModelDownloaded();
    final size = await localLLM.getModelFileSize();
    if (mounted) {
      setState(() {
        _modelDownloaded = downloaded;
        _modelFileSize = size;
      });
    }
  }

  Future<void> _downloadModel() async {
    final localLLM = ref.read(localLLMServiceProvider);
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    try {
      await localLLM.downloadModel(
        onProgress: (received, total) {
          if (mounted) {
            setState(() {
              _downloadProgress = total > 0 ? received / total : 0;
            });
          }
        },
      );
      await _checkLocalModel();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Modell erfolgreich heruntergeladen!'),
          backgroundColor: AppColors.accent,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Download fehlgeschlagen: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _deleteModel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lokales Modell löschen?'),
        content: const Text(
          'Das Modell (~533 MB) wird vom Gerät entfernt. '
          'Du kannst es jederzeit erneut herunterladen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final localLLM = ref.read(localLLMServiceProvider);
      await localLLM.deleteModel();
      await _checkLocalModel();
    }
  }

  Future<void> _testConnection() async {
    setState(() => _testing = true);
    final ollama = ref.read(ollamaServiceProvider);

    final ok = await ollama.testConnection();
    List<String> models = [];
    if (ok) {
      models = await ollama.getModels();
    }

    if (mounted) {
      setState(() {
        _connectionOk = ok;
        _testing = false;
        _availableModels = models;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Verbindung erfolgreich! ${models.length} Modelle gefunden.'
            : 'Verbindung fehlgeschlagen.'),
        backgroundColor: ok ? AppColors.accent : AppColors.error,
      ));
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final config = ref.watch(ollamaConfigProvider);
    final locationConsent = ref.watch(locationConsentProvider);
    final ai = ref.watch(aiServiceProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: theme.headlineLarge),
          const SizedBox(height: 4),
          Text('CONFIGURE YOUR COMPANION.', style: theme.labelMedium),
          const SizedBox(height: 32),

          // --- AI Status ---
          _SettingsCard(
            children: [
              Text('AI STATUS', style: theme.labelSmall),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ai.currentBackend == AIBackend.none
                            ? AppColors.mutedText
                            : AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ai.statusText,
                            style: theme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ollama (Server) → Lokal (Qwen 3.5) → Offline',
                            style: theme.bodySmall?.copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // --- Local LLM ---
          _SettingsCard(
            children: [
              Text('LOKALES MODELL', style: theme.labelSmall),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.memory, size: 20, color: AppColors.accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Qwen 3.5 0.8B',
                                style: theme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                'Q4_K_M Quantisierung · ~533 MB',
                                style: theme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Läuft direkt auf deinem Gerät — kein Server nötig. '
                      'Wird automatisch genutzt wenn der Ollama-Server nicht erreichbar ist.',
                      style: theme.bodySmall,
                    ),
                    const SizedBox(height: 16),

                    if (_isDownloading) ...[
                      // Download progress
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _downloadProgress,
                          backgroundColor: AppColors.cardBorder,
                          color: AppColors.accent,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_downloadProgress * 100).toStringAsFixed(1)}% · '
                        '${_formatBytes((LocalLLMService.modelSizeBytes * _downloadProgress).round())} / '
                        '${_formatBytes(LocalLLMService.modelSizeBytes)}',
                        style: theme.bodySmall,
                      ),
                    ] else if (_modelDownloaded) ...[
                      // Downloaded — show status + delete
                      Row(
                        children: [
                          const Icon(Icons.check_circle, size: 16, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Heruntergeladen (${_formatBytes(_modelFileSize)})',
                              style: theme.bodySmall?.copyWith(color: AppColors.accent),
                            ),
                          ),
                          TextButton(
                            onPressed: _deleteModel,
                            child: Text(
                              'LÖSCHEN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Not downloaded
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _downloadModel,
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('MODELL HERUNTERLADEN'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // --- Ollama Connection ---
          _SettingsCard(
            children: [
              Text('OLLAMA SERVER', style: theme.labelSmall),
              const SizedBox(height: 16),

              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  hintText: 'http://192.168.1.x:11434',
                  suffixIcon: _testing
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          onPressed: () async {
                            await ref
                                .read(ollamaConfigProvider.notifier)
                                .setUrl(_urlController.text.trim());
                            _testConnection();
                          },
                          icon: const Icon(Icons.check_circle_outline),
                        ),
                ),
                onSubmitted: (value) async {
                  await ref
                      .read(ollamaConfigProvider.notifier)
                      .setUrl(value.trim());
                  _testConnection();
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Wird bevorzugt genutzt wenn erreichbar.',
                style: theme.bodySmall,
              ),
              const SizedBox(height: 16),

              // Model selector
              if (_availableModels.isNotEmpty) ...[
                Text('MODEL', style: theme.labelSmall),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: DropdownButton<String>(
                    value: _availableModels.contains(config.model)
                        ? config.model
                        : _availableModels.first,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: _availableModels
                        .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(ollamaConfigProvider.notifier).setModel(value);
                      }
                    },
                  ),
                ),
              ] else ...[
                Text('MODEL', style: theme.labelSmall),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(config.model, style: theme.bodyMedium),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _connectionOk ? 'CONNECTED' : 'NOT CONNECTED',
                        style: theme.labelSmall?.copyWith(
                          color: _connectionOk
                              ? AppColors.accent
                              : AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // --- Location ---
          _SettingsCard(
            children: [
              Text('LOCATION TRACKING', style: theme.labelSmall),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Enable Location',
                              style: theme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                            'Logs approximate location once per day. Data stays on device.',
                            style: theme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: locationConsent,
                      activeTrackColor: AppColors.accent,
                      onChanged: (value) {
                        ref
                            .read(locationConsentProvider.notifier)
                            .setConsent(value);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // --- Storage ---
          _SettingsCard(
            children: [
              Text('STORAGE', style: theme.labelSmall),
              const SizedBox(height: 16),
              Text(
                'Local SQLite database is active. All data stays on your device.',
                style: theme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // --- Backup ---
          _SettingsCard(
            children: [
              Text('BACKUP (PHASE 3)', style: theme.labelSmall),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.cardBorder),
                  ),
                  child: Text(
                    'CONFIGURE WEBDAV',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                      color: AppColors.mutedText,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
