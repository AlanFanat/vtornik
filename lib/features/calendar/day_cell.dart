import 'package:flutter/material.dart';

import '../../core/colors.dart';

/// Одна ячейка календаря.
class DayCell extends StatelessWidget {
  const DayCell({
    super.key,
    required this.date,
    required this.rating,
    required this.isSelected,
    required this.isToday,
    required this.isFuture,
    required this.hasDetails,
    required this.onTap,
  });

  final DateTime date;
  final int? rating;
  final bool isSelected;
  final bool isToday;
  final bool isFuture;
  final bool
  hasDetails; //Для отличия дня, у которого стоит заметка или тег, но не стоит оценка
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rating = this.rating;

    // Оценённый день — цвет оценки, будущий — пустая рамка, остальные — серый.
    final Color background = isFuture
        ? Colors.transparent
        : rating != null
        ? ratingColor(rating)
        : colors.surface;

    // Выбранный день обводим цветом текста: акцент терялся бы на цветных оценках.
    final BorderSide border = isSelected
        ? BorderSide(color: accentColor, width: 2)
        : isFuture
        ? BorderSide(color: colors.cardBorder)
        : BorderSide.none;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: border,
    );

    // На цветной заливке оценки текст всегда тёмный, в любой теме.
    final Color foreground = isFuture
        ? colors.disabledText
        : rating != null
        ? colors.onRatingColor
        : colors.text;

    final bool detailsWithoutRating = hasDetails && rating == null;

    final dayStyle = TextStyle(
      fontSize: 14,
      color: foreground,
      fontWeight: FontWeight.w800,
      // Сегодняшний день подчёркнут: не конфликтует с рамкой выбора.
      decoration: isToday ? TextDecoration.underline : null,
      decorationColor: foreground,
    );

    return Semantics(
      button: !isFuture,
      enabled: !isFuture,
      selected: isSelected,
      excludeSemantics: true,
      label: isFuture
          ? '${date.day}, день ещё не наступил'
          : rating != null
          ? '${date.day}, оценка $rating'
          : detailsWithoutRating
          ? '${date.day}, без оценки, с записью'
          : '${date.day}, без оценки',
      child: Material(
        color: background,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          // null у будущих дней: ни нажатия, ни ряби.
          onTap: isFuture ? null : onTap,
          child: Stack(
            children: [
              Center(child: Text('${date.day}', style: dayStyle)),
              if (detailsWithoutRating)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: SizedBox.square(
                      dimension: 3,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: foreground,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
