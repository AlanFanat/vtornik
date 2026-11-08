import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/date_format.dart';
import '../../data/day_entry.dart';
import '../../widgets/section_title.dart';

/// Заполненный день в режиме чтения: оформлен как редактор, но не редактируется.
class DaySummary extends StatelessWidget {
  const DaySummary({
    super.key,
    required this.date,
    required this.entry,
    this.onEdit,
  });

  final DateTime date;
  final DayEntry entry;

  /// Нажатие на ✏️. Если null, кнопка не показывается.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rating = entry.rating;
    final note = entry.note.trim();
    final tags = entry.tags.toList()..sort();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RatingBadge(rating: rating),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatDate(date),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                    ),
                    Text(
                      weekdayName(date),
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  tooltip: 'Изменить',
                  icon: Icon(Icons.edit_outlined, color: colors.text),
                  onPressed: onEdit,
                ),
            ],
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            const SectionTitle('Теги дня'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [for (final tag in tags) _TagLabel(tag)],
            ),
          ],
          if (note.isNotEmpty) ...[
            const SizedBox(height: 12),
            const SectionTitle('Заметка'),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.inputFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                note,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: colors.text,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Крупная плитка оценки: цвет оценки или серая «—».
class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final int? rating;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rating = this.rating;

    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: rating != null ? ratingColor(rating) : colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        rating?.toString() ?? '—',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: rating != null ? colors.onRatingColor : colors.disabledText,
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        tag,
        style: TextStyle(fontSize: 12, color: colors.text),
      ),
    );
  }
}