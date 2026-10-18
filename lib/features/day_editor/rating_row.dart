import 'package:flutter/material.dart';

import '../../core/colors.dart';

/// Ровно одна строка из 10 плиток оценки при любой ширине экрана.
class RatingRow extends StatelessWidget {
  const RatingRow({super.key, required this.selected, required this.onSelected});

  final int? selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var rating = 1; rating <= 10; rating++) ...[
          if (rating > 1) const SizedBox(width: 4),
          Expanded(
            child: _RatingTile(
              rating: rating,
              isSelected: selected == rating,
              onTap: () => onSelected(rating),
            ),
          ),
        ],
      ],
    );
  }
}

class _RatingTile extends StatelessWidget {
  const _RatingTile({
    required this.rating,
    required this.isSelected,
    required this.onTap,
  });

  final int rating;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    return Semantics(
      button: true,
      selected: isSelected,
      excludeSemantics: true,
      label: 'Оценка $rating из 10',
      child: Material(
        // Без анимации: цвет оценки появляется сразу, а не проявляется из серого.
        animationDuration: Duration.zero,
        color: isSelected ? ratingColor(rating) : colors.surface,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          // Без ряби и затемнения при нажатии: именно они давали «тусклый» цвет.
          splashFactory: NoSplash.splashFactory,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: SizedBox(
            height: 40,
            child: Center(
              child: Text(
                '$rating',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? colors.onRatingColor : colors.text,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
