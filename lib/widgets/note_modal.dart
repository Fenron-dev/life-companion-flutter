import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/providers.dart';
import '../utils/theme.dart';

class NoteModal extends ConsumerStatefulWidget {
  const NoteModal({super.key});

  @override
  ConsumerState<NoteModal> createState() => _NoteModalState();
}

class _NoteModalState extends ConsumerState<NoteModal> {
  final _controller = TextEditingController();
  bool _saving = false;

  static const int _maxLength = 50000;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final content = _controller.text.trim();
    if (content.isEmpty || content.length > _maxLength) return;

    setState(() => _saving = true);

    try {
      final db = ref.read(databaseProvider);
      final now = DateTime.now();
      await db.addNote(
        date: DateFormat('yyyy-MM-dd').format(now),
        content: content,
        timestamp: now.millisecondsSinceEpoch,
      );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Speichern: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasContent = _controller.text.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'New Entry',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.mutedText),
                ),
              ],
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 6,
              maxLength: _maxLength,
              buildCounter: (_, {required currentLength, required isFocused, required maxLength}) => null,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: "What's on your mind?",
                hintStyle: TextStyle(
                  color: AppColors.cardBorder,
                  fontStyle: FontStyle.italic,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: hasContent && !_saving ? _handleSubmit : null,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, size: 16),
                label: Text(
                  'SAVE ENTRY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
