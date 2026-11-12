import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/date_format.dart';
import '../../core/format_number.dart';
import '../../data/day_entry.dart';

class StatsWeekdays extends StatelessWidget {
  const StatsWeekdays({super.key, required this.entries});

  final Map<DateTime, DayEntry> entries;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    //7 массовов для каждого дня недели, в которых будут храниться оценки
    final ratingsByWeekday = List.generate(7, (_) => <int>[]);

    for (final entry in entries.entries) {
      final rating = entry.value.rating;
      if (rating != null) {
        ratingsByWeekday[entry.key.weekday - 1].add(rating);
      }
    }

    final averages = ratingsByWeekday.map((ratings) {
      if (ratings.isEmpty) return null;
      return ratings.reduce((a, b) => a + b) / ratings.length;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WeekdayHeader(textColor: colors.text),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 12,
            children: [
              for (var index = 0; index < 7; index++)
                Expanded(
                  child: _WeekdayBar(
                    label: weekdaysShort[index],
                    average: averages[index],
                    sampleCount: ratingsByWeekday[index].length,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.textColor});

  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.bar_chart_rounded, color: textColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Оценки по дням недели',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Средняя оценка за каждый день недели',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeekdayBar extends StatelessWidget {
  const _WeekdayBar({
    required this.label,
    required this.average,
    required this.sampleCount,
  });

  final String label;
  final double? average;
  final int sampleCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final value = average;

    const double maxBarHeight = 100;
    final barHeight = value == null
        ? 0.0
        : (maxBarHeight * (value / 10)).clamp(0.0, maxBarHeight);

    return Column(
      children: [
        SizedBox(
          height: 126,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value == null ? '—' : formatAverage(value),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: value == null ? Colors.grey : colors.text,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic, // плавное замедление к концу
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: value == null
                        ? Colors.transparent
                        : ratingColor(value.round()),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: colors.text)),
        Text(
          '$sampleCount дн.',
          style: const TextStyle(fontSize: 9, color: Colors.grey),
        ),
      ],
    );
  }
}
