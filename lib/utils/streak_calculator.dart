import '../services/database.dart';

/// Fixed streak calculation.
/// Original bug: treated 1-day gaps as continuing the streak.
/// Fix: only truly consecutive days count.
class StreakCalculator {
  static int calculate(List<DailyNote> notes) {
    if (notes.isEmpty) return 0;

    // Get unique dates, sorted descending
    final dates = notes.map((n) => n.date).toSet().toList()
      ..sort((a, b) => b.compareTo(a)); // newest first

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int streak = 0;
    var expectedDate = today;

    for (final dateStr in dates) {
      final parts = dateStr.split('-');
      final noteDate = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );

      final diff = expectedDate.difference(noteDate).inDays;

      if (diff == 0) {
        // This date matches what we expect
        streak++;
        expectedDate = expectedDate.subtract(const Duration(days: 1));
      } else if (diff == 1 && streak == 0) {
        // No entry today, but yesterday exists — still counts as active streak
        streak++;
        expectedDate = noteDate.subtract(const Duration(days: 1));
      } else {
        // Gap found — streak broken
        break;
      }
    }

    return streak;
  }
}
