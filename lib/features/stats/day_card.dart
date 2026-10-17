import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/date_format.dart';
import '../../data/day_entry.dart';

/// Карточка одного дня: дата, оценка, заметка и теги.
class DayCard extends StatelessWidget {
  const DayCard({super.key, required this.date, required this.entry});

  final DateTime date;
  final DayEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rating = entry.rating;
    final note = entry.note.trim();
    final tags = entry.tags.toList()..sort();

    // Цветная полоска слева и плитка оценки: цвет оценки или нейтральный серый.
    final accent = rating != null ? ratingColor(rating) : context.colors.surface;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(date: date, rating: rating, color: accent),
                    if (note.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        note,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, height: 1.35),
                      ),
                    ],
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: [for (final tag in tags) _TagLabel(tag)],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Дата со днём недели слева и плитка оценки справа.
class _Header extends StatelessWidget {
  const _Header({
    required this.date,
    required this.rating,
    required this.color,
  });

  final DateTime date;
  final int? rating;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;
    final rating = this.rating;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatDate(date),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                weekdayName(date),
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            rating?.toString() ?? '—',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: rating != null ? onRatingColor : colors.disabledText,
            ),
          ),
        ),
      ],
    );
  }
}

class _TagLabel extends StatelessWidget {
  const _TagLabel(this.tag);

  final String tag;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        tag,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11, height: 1.2, color: colors.text),
      ),
    );
  }
}
