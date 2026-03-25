import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/providers.dart';
import '../services/database.dart';
import '../utils/theme.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(allNotesProvider);
    final logsAsync = ref.watch(todayLogsProvider);
    final theme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Journal', style: theme.headlineLarge),
          const SizedBox(height: 4),
          Text(
            'YOUR TIMELINE OF BEING.',
            style: theme.labelMedium,
          ),
          const SizedBox(height: 32),

          notesAsync.when(
            data: (notes) {
              if (notes.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text(
                      'The pages are waiting for your story.',
                      style: theme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
                );
              }

              return _Timeline(
                notes: notes,
                logs: logsAsync.valueOrNull ?? [],
                theme: theme,
                onDelete: (id) async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete this entry?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref.read(databaseProvider).deleteNote(id);
                  }
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, _) => const Text('Error loading journal'),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final List<dynamic> notes;
  final List<RawLog> logs;
  final TextTheme theme;
  final Future<void> Function(int id) onDelete;

  const _Timeline({
    required this.notes,
    required this.logs,
    required this.theme,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Get actual weather/location from logs instead of hardcoded values
    final weatherLog = logs.where((l) => l.type == 'weather').firstOrNull;
    final locationLog = logs.where((l) => l.type == 'location').firstOrNull;
    final weather = weatherLog != null ? parseLogData(weatherLog) : null;
    final location = locationLog != null ? parseLogData(locationLog) : null;

    return Stack(
      children: [
        // Timeline line
        Positioned(
          left: 16,
          top: 0,
          bottom: 0,
          child: Container(width: 1, color: AppColors.cardBorder),
        ),

        Column(
          children: notes.map<Widget>((note) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline dot
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      width: 33,
                      alignment: Alignment.center,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent,
                          border: Border.all(color: AppColors.background, width: 3),
                        ),
                      ),
                    ),
                  ),

                  // Note card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('MMM d, HH:mm').format(
                                  DateTime.fromMillisecondsSinceEpoch(note.timestamp),
                                ).toUpperCase(),
                                style: theme.labelSmall,
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (note.id != null) onDelete(note.id!);
                                },
                                child: const Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: AppColors.cardBorder,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(note.content, style: theme.bodyLarge),
                          const SizedBox(height: 24),

                          // Related logs — uses real data instead of hardcoded
                          Container(
                            padding: const EdgeInsets.only(top: 24),
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Color(0xFFF5F5F5)),
                              ),
                            ),
                            child: Wrap(
                              spacing: 16,
                              children: [
                                if (location != null)
                                  _LogChip(
                                    icon: Icons.location_on_outlined,
                                    label: '${location['latitude']?.toStringAsFixed(2)}, ${location['longitude']?.toStringAsFixed(2)}',
                                  ),
                                if (weather != null)
                                  _LogChip(
                                    icon: Icons.cloud_outlined,
                                    label: '${weather['temp']}° ${weather['condition']}',
                                  ),
                                if (location == null && weather == null)
                                  _LogChip(
                                    icon: Icons.info_outline,
                                    label: 'No logs',
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _LogChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _LogChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.mutedText),
        const SizedBox(width: 4),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: AppColors.mutedText,
          ),
        ),
      ],
    );
  }
}
