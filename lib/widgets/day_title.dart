import 'package:flutter/material.dart';

import '../core/colors.dart';
import '../core/date_format.dart';

/// Заголовок дня: дата крупно, под ней день недели серым.
/// Один вид для формы дня и ленты статистики.
class DayTitle extends StatelessWidget {
  const DayTitle({super.key, required this.date, this.fontSize = 22});

  final DateTime date;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formatDate(date),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
        Text(
          weekdayName(date),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ],
    );
  }
}