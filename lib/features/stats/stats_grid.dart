import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/format_number.dart';
import '../../data/day_entry.dart';
import '../../features/stats/stat_card.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key, required this.days});

  final List<DayEntry> days;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Только непустые оценки
    final ratingsOnly = days
        .map((d) => d.rating)
        .whereType<int>() // короче, чем where + cast
        .toList();

    // Среднее — с защитой от пустого списка
    final double averageRating = ratingsOnly.isEmpty
        ? 0
        : ratingsOnly.reduce((a, b) => a + b) / ratingsOnly.length;

    final int daysCount = days.length; // всего (включая null)
    final int ratingDaysCount = ratingsOnly.length; // с оценкой
    final int goodDaysCount = ratingsOnly.where((r) => r >= 8).length;
    final int badDaysCount = ratingsOnly.where((r) => r <= 3).length;

    // Форматирование среднего: 4.333... → "4.3"
    final averageText = formatAverage(averageRating);

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: StatCard(
                  title: 'Средний балл',
                  value: averageText,
                  bottomText: 'Из 10,0 возможных',
                  iconData: Icons.trending_up_rounded,
                  mainColor: ratingsOnly.isEmpty
                      ? colors.disabledText
                      : ratingColor(averageRating.round()),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: StatCard(
                  title: 'Всего дней',
                  value: '$daysCount',
                  bottomText: 'С оценкой: $ratingDaysCount',
                  iconData: Icons.event_note_rounded,
                  mainColor: accentColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: StatCard(
                  title: 'Отличных дней',
                  value: '$goodDaysCount',
                  bottomText: 'Оценка ≥ 8',
                  iconData: Icons.thumb_up_rounded,
                  mainColor: ratingColor(10),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: StatCard(
                  title: 'Трудных дней',
                  value: '$badDaysCount',
                  bottomText: 'Оценка ≤ 4',
                  iconData: Icons.thumb_down_rounded,
                  mainColor: ratingColor(1),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
