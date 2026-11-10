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
    final scheme = Theme.of(context).colorScheme;

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

    final avgColor = ratingsOnly.isEmpty
        ? colors.disabledText
        : ratingColor(averageRating.round().clamp(1, 10));

    return Column(
      children: [
        // Объединённый верхний блок: кольцевая диаграмма + доп. инфо
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.cardBorder),
          ),
          child: Row(
            children: [
              // Кольцевая диаграмма среднего балла
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 76,
                      height: 76,
                      child: CircularProgressIndicator(
                        value: ratingsOnly.isEmpty
                            ? 0.0
                            : (averageRating / 10).clamp(0.0, 1.0),
                        strokeWidth: 7,
                        strokeCap: StrokeCap.round,
                        backgroundColor: colors.surface,
                        valueColor: AlwaysStoppedAnimation<Color>(avgColor),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ratingsOnly.isEmpty ? '—' : averageText,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: avgColor,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'из 10',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Дополнительная информация справа
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Средний балл',
                            style: TextStyle(
                              color: colors.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.trending_up_rounded,
                          size: 20,
                          color: avgColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _MetricRow(
                      icon: Icons.event_note_rounded,
                      iconColor: accentColor,
                      label: 'Заполнено дней',
                      value: '$daysCount',
                    ),
                    const SizedBox(height: 6),
                    _MetricRow(
                      icon: Icons.star_rounded,
                      iconColor: avgColor,
                      label: 'С оценкой',
                      value: '$ratingDaysCount',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Нижний ряд: отличные и трудные дни
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
                  bottomText: 'Оценка ≤ 3',
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

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.text,
          ),
        ),
      ],
    );
  }
}
