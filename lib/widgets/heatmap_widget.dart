import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/theme.dart';

class HeatmapWidget extends StatelessWidget {
  final List<String> noteDates;

  const HeatmapWidget({super.key, required this.noteDates});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(28, (i) {
      return now.subtract(Duration(days: 27 - i));
    });
    final dateFormat = DateFormat('yyyy-MM-dd');

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: 28,
      itemBuilder: (context, i) {
        final dateStr = dateFormat.format(days[i]);
        final hasEntry = noteDates.contains(dateStr);

        return Tooltip(
          message: dateStr,
          child: Container(
            decoration: BoxDecoration(
              color: hasEntry ? AppColors.accent : AppColors.cardBorder,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );
  }
}
