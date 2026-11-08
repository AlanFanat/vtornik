import 'package:flutter/material.dart';

import '../../core/colors.dart';

/// Крупная плитка оценки дня: цвет оценки или серая «—».
/// Общая для карточки ([DaySummary]) и формы ([DayEditor]).
class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.rating});

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