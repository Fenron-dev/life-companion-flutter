import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/providers.dart';
import '../services/database.dart';
import '../utils/theme.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/heatmap_widget.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String? _summary;
  bool _isSummarizing = false;

  Future<void> _handleSummarize() async {
    setState(() => _isSummarizing = true);

    try {
      final db = ref.read(databaseProvider);
      final ai = ref.read(aiServiceProvider);
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final dayNotes = await db.getNotesForDate(today);
      final dayLogs = await db.getLogsForDate(today);

      final result = await ai.summarizeDay(
        notes: dayNotes.map((n) => n.content).toList(),
        logs: dayLogs.map((l) => parseLogData(l)).toList(),
      );

      if (mounted) setState(() => _summary = result);
    } catch (e) {
      if (mounted) {
        setState(() => _summary = 'Fehler: Kein AI-Backend erreichbar.');
      }
    } finally {
      if (mounted) setState(() => _isSummarizing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final streak = ref.watch(streakProvider);
    final logsAsync = ref.watch(todayLogsProvider);
    final noteDatesAsync = ref.watch(noteDatesProvider);
    final recentNotesAsync = ref.watch(recentNotesProvider);
    final theme = Theme.of(context).textTheme;

    final weather = logsAsync.whenOrNull(
      data: (logs) {
        final weatherLog = logs.where((l) => l.type == 'weather').firstOrNull;
        return weatherLog != null ? parseLogData(weatherLog) : null;
      },
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // --- Header ---
          const AvatarWidget(mood: 'happy'),
          const SizedBox(height: 16),
          Text(
            DateFormat('EEEE, MMMM d').format(DateTime.now()).toUpperCase(),
            style: theme.labelSmall,
          ),
          const SizedBox(height: 8),
          Text('Guten Tag, Companion.', style: theme.headlineLarge),
          const SizedBox(height: 32),

          // --- Stats Grid ---
          Row(
            children: [
              Expanded(child: _StatCard(
                icon: Icons.local_fire_department_outlined,
                label: 'STREAK',
                value: '$streak',
                subtitle: 'DAYS ACTIVE',
              )),
              const SizedBox(width: 16),
              Expanded(child: _StatCard(
                icon: Icons.cloud_outlined,
                label: 'WEATHER',
                value: '${weather?['temp'] ?? '--'}°',
                subtitle: (weather?['condition'] as String?) ?? 'Loading...',
              )),
            ],
          ),
          const SizedBox(height: 24),

          // --- Heatmap ---
          _CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ACTIVITY HEATMAP', style: theme.labelSmall),
                const SizedBox(height: 16),
                noteDatesAsync.when(
                  data: (dates) => HeatmapWidget(noteDates: dates),
                  loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
                  error: (_, _) => const Text('Error loading heatmap'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- AI Summary ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.1)),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.surface, AppColors.background],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Text('DAILY INSIGHT', style: theme.labelSmall),
                  ],
                ),
                const SizedBox(height: 16),
                if (_summary != null) ...[
                  MarkdownBody(
                    data: _summary!,
                    styleSheet: MarkdownStyleSheet(
                      p: theme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => setState(() => _summary = null),
                    child: Text(
                      'CLOSE',
                      style: theme.labelMedium?.copyWith(fontSize: 10),
                    ),
                  ),
                ] else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSummarizing ? null : _handleSummarize,
                      child: Text(
                        _isSummarizing ? 'CONSULTING THE COMPANION...' : 'SUMMARIZE MY DAY',
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Activity Trend (mock) ---
          _CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ACTIVITY TREND', style: theme.labelSmall),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _SimpleChartPainter(
                      data: [400, 1200, 3500, 4200, 5100],
                      labels: ['08:00', '10:00', '12:00', '14:00', '16:00'],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Recent Notes ---
          Align(
            alignment: Alignment.centerLeft,
            child: Text('RECENT JOURNAL', style: theme.labelSmall),
          ),
          const SizedBox(height: 16),
          recentNotesAsync.when(
            data: (notes) {
              if (notes.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'No entries yet. Start your journey.',
                    style: theme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return Column(
                children: notes.map((note) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _CardContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '"${note.content}"',
                          style: theme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          DateFormat('HH:mm').format(
                            DateTime.fromMillisecondsSinceEpoch(note.timestamp),
                          ),
                          style: theme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                )).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Text('Error loading notes'),
          ),
          const SizedBox(height: 80), // Bottom nav padding
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: AppColors.accent),
            const SizedBox(width: 8),
            Text(label, style: theme.labelSmall?.copyWith(fontSize: 10)),
          ]),
          const SizedBox(height: 16),
          Text(value, style: theme.displayMedium),
          const SizedBox(height: 4),
          Text(subtitle.toUpperCase(), style: theme.labelMedium?.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  final Widget child;
  const _CardContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
  }
}

/// Lightweight chart replacing heavy Recharts dependency
class _SimpleChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;

  _SimpleChartPainter({required this.data, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final paint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = const Color(0xFFF0F0F0)
      ..strokeWidth = 1;

    // Draw grid lines
    for (var i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Plot data
    final path = Path();
    final points = <Offset>[];

    for (var i = 0; i < data.length; i++) {
      final x = size.width * i / (data.length - 1);
      final y = size.height - (data[i] / maxVal * size.height * 0.9);
      points.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw dots
    for (final point in points) {
      canvas.drawCircle(point, 6, dotBorderPaint);
      canvas.drawCircle(point, 4, dotPaint);
    }

    // Draw labels
    final labelStyle = TextStyle(
      color: AppColors.mutedText,
      fontSize: 10,
    );
    for (var i = 0; i < labels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      final x = size.width * i / (labels.length - 1) - tp.width / 2;
      tp.paint(canvas, Offset(x.clamp(0, size.width - tp.width), size.height + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _SimpleChartPainter old) =>
      data != old.data;
}
