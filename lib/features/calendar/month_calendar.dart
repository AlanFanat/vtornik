import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/date_format.dart';
import '../../data/day_entry.dart';
import 'day_cell.dart';

class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.selectedDate,
    required this.entries,
    required this.onMonthChanged,
    required this.onToday,
    required this.onDateSelected,
  });

  /// Любая дата нужного месяца (используем первое число).
  final DateTime month;
  final DateTime selectedDate;
  final Map<DateTime, DayEntry> entries;
  final ValueChanged<DateTime> onMonthChanged;
  final VoidCallback onToday;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final today = DateUtils.dateOnly(DateTime.now());

    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    // Dart: Monday = 1 ... Sunday = 7, поэтому неделя начинается с Пн.
    final startOffset = DateTime(month.year, month.month).weekday - 1;

    // В будущие месяцы листать нельзя.
    final canGoNext = month.isBefore(DateTime(today.year, today.month));

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
          _MonthHeader(
            month: month,
            showToday: month.year != today.year || month.month != today.month,
            onPrevious: () =>
                onMonthChanged(DateUtils.addMonthsToMonthDate(month, -1)),
            onNext: canGoNext
                ? () => onMonthChanged(DateUtils.addMonthsToMonthDate(month, 1))
                : null,
            onToday: onToday,
          ),
          const SizedBox(height: 4),
          const _WeekdayLabels(),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: startOffset + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1.4,
            ),
            itemBuilder: (context, index) {
              // Пустые ячейки перед первым числом.
              if (index < startOffset) return const SizedBox.shrink();

              final date = DateTime(
                month.year,
                month.month,
                index - startOffset + 1,
              );

              return DayCell(
                date: date,
                rating: entries[date]?.rating,
                isSelected: date == selectedDate,
                isToday: date == today,
                isFuture: date.isAfter(today),
                hasDetails: entries[date]?.hasDetails ?? false,
                onTap: () => onDateSelected(date),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Название месяца со стрелками. `onNext == null` — стрелка отключена.
class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.showToday,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final DateTime month;
  final bool showToday;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    const buttonSize = 40.0;
    final buttonConstraints = BoxConstraints.tightFor(
      width: buttonSize,
      height: kMinInteractiveDimension,
    );

    return Row(
      children: [
        IconButton(
          constraints: buttonConstraints,
          padding: EdgeInsets.zero,
          tooltip: 'Предыдущий месяц',
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrevious,
        ),
        const SizedBox(width: buttonSize),
        Expanded(
          child: Center(
            child: Text(
              '${months[month.month - 1]} ${month.year}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: context.colors.text,
              ),
            ),
          ),
        ),
        if (showToday)
          IconButton(
            constraints: buttonConstraints,
            padding: EdgeInsets.zero,
            tooltip: 'Сегодня',
            icon: const Icon(Icons.today),
            onPressed: onToday,
          )
        else
          const SizedBox(width: buttonSize),
        IconButton(
          constraints: buttonConstraints,
          padding: EdgeInsets.zero,
          tooltip: 'Следующий месяц',
          icon: const Icon(Icons.chevron_right),
          onPressed: onNext,
        ),
      ],
    );
  }
}

/// Строка «Пн Вт Ср ...» над сеткой.
class _WeekdayLabels extends StatelessWidget {
  const _WeekdayLabels();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final day in weekdaysShort)
          Expanded(
            child: Center(
              child: Text(
                day,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}
