import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/constants.dart';
import '../../core/format_number.dart';
import '../../data/day_entry.dart';
import 'tag_stat.dart';

/// Блок «Теги»: средняя оценка дней с тегом и влияние тега на оценку.
class StatsTags extends StatelessWidget {
  const StatsTags({super.key, required this.days});
  final List<DayEntry> days;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final stats = computeTagStats(days);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.cardBorder),
          ),
          child: Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TagStatsHeader(textColor: colors.text),
              if (stats.isEmpty)
                const Text(
                  'Пока нет тегов',
                  style: TextStyle(color: Colors.grey),
                )
              else
                for (final stat in stats) _TagStatRow(stat: stat),
            ],
          ),
        ),
      ],
    );
  }
}

class _TagStatsHeader extends StatelessWidget {
  const _TagStatsHeader({required this.textColor});

  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.insights_rounded, color: textColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Влияние тегов',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Разница средней оценки в дни с тегом и без него.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TagStatRow extends StatelessWidget {
  const _TagStatRow({required this.stat});

  final TagStat stat;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final average = stat.average;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Левая часть: тег + счетчик дней
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    stat.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${stat.days} дн.)',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Правая часть: влияние средняя оценка
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ImpactChip(impact: stat.impact),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: average == null
                      ? colors.surface
                      : ratingColor(average.round()),
                  borderRadius: BorderRadius.circular(4), // rounded
                ),
                child: Text(
                  average == null ? '—' : '★ ${formatAverage(average)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: colors.onRatingColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Плашка с дельтой влияния тега или пометка «мало данных».
class _ImpactChip extends StatelessWidget {
  const _ImpactChip({required this.impact});

  final double? impact;

  @override
  Widget build(BuildContext context) {
    final impact = this.impact;

    if (impact == null) {
      return const Text(
        'мало данных',
        style: TextStyle(color: Colors.grey, fontSize: 11),
      );
    }

    final isPositive = impact > neutralImpact;
    final isNegative = impact < -neutralImpact;

    final Color textColor = isPositive
        ? impactPositiveColor
        : isNegative
        ? impactNegativeColor
        : Colors.grey;

    final formattedText = formatImpact(impact);

    return Text(
      formattedText,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
    );
  }
}
