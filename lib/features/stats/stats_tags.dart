import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/constants.dart';
import '../../core/format_number.dart';
import '../../data/day_entry.dart';
import '../../widgets/section_title.dart';
import 'tag_stat.dart';

/// Блок «Теги»: средняя оценка дней с тегом и влияние тега на оценку.
class StatsTags extends StatelessWidget {
  const StatsTags({super.key, required this.days});

  final List<DayEntry> days;

  @override
  Widget build(BuildContext context) {
    final stats = computeTagStats(days);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Теги'),
        const SizedBox(height: 4),
        if (stats.isEmpty)
          const Text(
            'Пока нет тегов',
            style: TextStyle(color: Colors.grey),
          )
        else ...[
          for (final stat in stats)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _TagStatRow(stat: stat),
            ),
          const Text(
            'Влияние — разница со средней оценкой дней без этого тега. '
            'Это совпадения, а не доказательство причины.',
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
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

    final daysText = stat.ratedDays == stat.days
        ? 'Дней: ${stat.days}'
        : 'Дней: ${stat.days}, с оценкой: ${stat.ratedDays}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  daysText,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            average == null ? '—' : formatAverage(average),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: average == null
                  ? colors.disabledText
                  : ratingColor(average.round()),
            ),
          ),
          const SizedBox(width: 8),
          _ImpactChip(impact: stat.impact),
        ],
      ),
    );
  }
}

/// Плашка с влиянием тега или пометка «мало данных».
class _ImpactChip extends StatelessWidget {
  const _ImpactChip({required this.impact});

  final double? impact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final impact = this.impact;

    if (impact == null) {
      return const SizedBox(
        width: 64,
        child: Text(
          'мало данных',
          textAlign: TextAlign.end,
          style: TextStyle(color: Colors.grey, fontSize: 11),
        ),
      );
    }

    final Color background;
    final Color foreground;
    if (impact > neutralImpact) {
      background = ratingColor(10);
      foreground =  colors.onRatingColor;
    } else if (impact < -neutralImpact) {
      background = ratingColor(1);
      foreground = colors.onRatingColor;
    } else {
      background = colors.surface;
      foreground = colors.text;
    }

    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        formatImpact(impact),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: foreground,
        ),
      ),
    );
  }
}