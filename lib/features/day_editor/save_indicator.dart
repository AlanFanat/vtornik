import 'package:flutter/material.dart';

import '../../core/colors.dart';

enum SaveStatus { idle, saved, failed }

/// Маленький индикатор в форме дня: день сохранился или нет.
class SaveIndicator extends StatelessWidget {
  const SaveIndicator({super.key, required this.status});

  final SaveStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case SaveStatus.idle:
        return const SizedBox.shrink();
      case SaveStatus.saved:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, size: 14, color: impactPositiveColor),
            SizedBox(width: 4),
            Text(
              'Сохранено',
              style: TextStyle(color: impactPositiveColor, fontSize: 12),
            ),
          ],
        );
      case SaveStatus.failed:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 14, color: impactNegativeColor),
            SizedBox(width: 4),
            Text(
              'Не сохранилось',
              style: TextStyle(color: impactNegativeColor, fontSize: 12),
            ),
          ],
        );
    }
  }
}