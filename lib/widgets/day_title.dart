import 'package:flutter/material.dart';
import 'package:vtornik/widgets/section_title.dart';

import '../core/date_format.dart';

/// Заголовок дня: дата крупно, под ней день недели серым.
/// Один вид для формы дня и ленты статистики.
class DayTitle extends StatelessWidget {
  const DayTitle({super.key, required this.date, this.fontSize = 16});

  final DateTime date;
  final double fontSize;

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(formatDate(date)),
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