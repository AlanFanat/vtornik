import 'package:flutter/material.dart';

import '../../core/colors.dart';
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
    final int badDaysCount = ratingsOnly.where((r) => r <= 4).length;

    // Форматирование среднего: 4.333... → "4.3"
    final averageText = averageRating.toStringAsFixed(1).replaceAll('.', ',');

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true, // если GridView внутри Column/SingleChildScrollView
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: [
        StatCard(
          title: 'Средний балл',
          value: averageText,
          bottomText: 'Из 10,0 возможных',
          iconData: Icons.trending_up_rounded,
          mainColor: ratingsOnly.isEmpty
              ? colors.disabledText
              : ratingColor(averageRating.round()),
        ),
        StatCard(
          title: 'Всего дней',
          value: '$daysCount',
          bottomText: 'Оценено: $ratingDaysCount',
          iconData: Icons.event_note_rounded,
          mainColor: accentColor,
        ),
        StatCard(
          title: 'Отличных дней',
          value: '$goodDaysCount',
          bottomText: 'Оценка ≥ 8',
          iconData: Icons.thumb_up_rounded,
          mainColor: ratingColor(10),
        ),
        StatCard(
          title: 'Плохих дней',
          value: '$badDaysCount',
          bottomText: 'Оценка ≤ 4',
          iconData: Icons.thumb_down_rounded,
          mainColor: ratingColor(1),
        ),
      ],
    );
  }
}

