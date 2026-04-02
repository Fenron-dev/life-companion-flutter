import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../services/ai_service.dart';
import '../services/local_llm_service.dart';
import '../utils/theme.dart';

// Discrete GPU layer options: 0=CPU, low, mid, high, all
const _gpuLayerOptions = [0, 10, 20, 33, 999];

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
    final llmSettings = ref.watch(llmSettingsProvider);

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
                                'Q4_K_M · ~533 MB',
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
                        '${_formatBytes((LocalModelConfigs.qwen35.sizeBytes * _downloadProgress).round())} / '
                        '${_formatBytes(LocalModelConfigs.qwen35.sizeBytes)}',
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

          // --- LLM Generation Settings ---
          _SettingsCard(
            children: [
              Text('GENERATION EINSTELLUNGEN', style: theme.labelSmall),
              const SizedBox(height: 4),
              Text(
                'Änderungen von GPU Layers / Context Size erfordern ein Neu-Laden des Modells.',
                style: theme.bodySmall,
              ),
              const SizedBox(height: 20),

              // GPU Layers
              _SliderRow(
                label: 'GPU LAYERS',
                valueLabel: llmSettings.gpuLayers == 0
                    ? 'CPU only'
                    : llmSettings.gpuLayers == 999
                        ? 'Alle (GPU)'
                        : '${llmSettings.gpuLayers} Layer',
                value: _gpuLayerOptions
                    .indexOf(llmSettings.gpuLayers)
                    .toDouble()
                    .clamp(0, _gpuLayerOptions.length - 1),
                min: 0,
                max: (_gpuLayerOptions.length - 1).toDouble(),
                divisions: _gpuLayerOptions.length - 1,
                hint: '0 = kein Absturz, höher = schneller (wenn Vulkan unterstützt)',
                onChanged: (v) {
                  final idx = v.round().clamp(0, _gpuLayerOptions.length - 1);
                  final layers = _gpuLayerOptions[idx];
                  ref.read(llmSettingsProvider.notifier).update(gpuLayers: layers);
                  // Unload model so it reloads with new params
                  ref.read(localLLMServiceProvider).dispose();
                },
              ),
              const SizedBox(height: 16),

              // Context Size
              _SliderRow(
                label: 'CONTEXT SIZE',
                valueLabel: '${llmSettings.contextSize} Tokens',
                value: llmSettings.contextSize.toDouble(),
                min: 512,
                max: 4096,
                divisions: 7,
                hint: 'Mehr = längeres Gedächtnis, mehr RAM',
                onChanged: (v) {
                  final size = (v / 512).round() * 512;
                  ref.read(llmSettingsProvider.notifier).update(contextSize: size);
                  ref.read(localLLMServiceProvider).dispose();
                },
              ),
              const SizedBox(height: 16),

              // Max Tokens
              _SliderRow(
                label: 'MAX TOKENS',
                valueLabel: '${llmSettings.maxTokens}',
                value: llmSettings.maxTokens.toDouble(),
                min: 64,
                max: 1024,
                divisions: 15,
                hint: 'Maximale Länge der Antwort',
                onChanged: (v) {
                  ref
                      .read(llmSettingsProvider.notifier)
                      .update(maxTokens: v.round());
                },
              ),
              const SizedBox(height: 16),

              // Temperature
              _SliderRow(
                label: 'TEMPERATURE',
                valueLabel: llmSettings.temperature.toStringAsFixed(1),
                value: llmSettings.temperature,
                min: 0.1,
                max: 1.5,
                divisions: 14,
                hint: '0.1 = präzise, 1.5 = kreativ',
                onChanged: (v) {
                  final t = (v * 10).round() / 10;
                  ref.read(llmSettingsProvider.notifier).update(temperature: t);
                },
              ),
              const SizedBox(height: 16),

              // Thinking Mode
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
                          Text('THINKING MODE',
                              style: theme.labelSmall?.copyWith(fontSize: 10)),
                          const SizedBox(height: 4),
                          Text(
                            'Qwen3 interner Denkprozess. Kann auf kleinen Geräten OOM-Abstürze verursachen.',
                            style: theme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: llmSettings.enableThinking,
                      activeTrackColor: AppColors.accent,
                      onChanged: (v) {
                        ref
                            .read(llmSettingsProvider.notifier)
                            .update(enableThinking: v);
                      },
                    ),
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

class _SliderRow extends StatelessWidget {
  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String hint;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.labelSmall?.copyWith(fontSize: 10)),
            Text(
              valueLabel,
              style: theme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.accent,
            inactiveTrackColor: AppColors.cardBorder,
            thumbColor: AppColors.accent,
            overlayColor: AppColors.accent.withValues(alpha: 0.1),
            trackHeight: 3,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        Text(hint, style: theme.bodySmall?.copyWith(fontSize: 10)),
      ],
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
