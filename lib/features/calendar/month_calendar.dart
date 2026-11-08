import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/date_format.dart';
import '../../data/day_entry.dart';
import 'day_cell.dart';

/// Карточка календаря: строка навигации, подписи дней недели и сетка дней.
/// Заголовок «Календарь» и кнопки «Сегодня» / «Свернуть» находятся в HomePage,
/// всё состояние (месяц, неделя, режим) тоже хранится там.
///
/// Параметры:
/// - [month]          — месяц, показываемый в заголовке карточки
///                      (в свёрнутом режиме — «четверговый» месяц недели).
/// - [weekStart]      — понедельник показанной недели (для свёрнутого режима).
/// - [isCollapsed]    — true: одна неделя, false: весь месяц.
/// - [selectedDate]   — выбранная дата (подсвечивается).
/// - [entries]        — записи по датам (ключи — dateOnly).
/// - [canGoNext]      — можно ли листать вперёд.
/// - [onPrevious]     — листать назад (месяц или неделя).
/// - [onNext]         — листать вперёд (месяц или неделя).
/// - [onDateSelected] — выбор конкретного дня.
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.weekStart,
    required this.isCollapsed,
    required this.selectedDate,
    required this.entries,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    required this.onDateSelected,
  });

  final DateTime month;
  final DateTime weekStart;
  final bool isCollapsed;
  final DateTime selectedDate;
  final Map<DateTime, DayEntry> entries;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onDateSelected;

  /// Список дат для сетки. null означает пустую ячейку (только в развёрнутом режиме).
  List<DateTime?> get _cells {
    if (isCollapsed) {
      // Ровно 7 дней начиная с weekStart, пустых ячеек нет.
      return List.generate(7, (i) => weekStart.add(Duration(days: i)));
    }
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    // Dart: weekday 1 = Пн, поэтому отступ = weekday - 1.
    final startOffset = DateTime(month.year, month.month, 1).weekday - 1;
    return [
      // Пустые ячейки перед первым числом.
      ...List<DateTime?>.filled(startOffset, null),
      // Дни месяца.
      ...List.generate(
        daysInMonth,
        (i) => DateTime(month.year, month.month, i + 1),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = DateUtils.dateOnly(selectedDate);

    final buttonConstraints = BoxConstraints.tightFor(
      width: 40,
      height: kMinInteractiveDimension,
    );

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        children: [
          // Строка навигации: ‹ «Месяц Год» ›
          Row(
            children: [
              IconButton(
                constraints: buttonConstraints,
                padding: EdgeInsets.zero,
                tooltip: 'Назад',
                icon: const Icon(Icons.chevron_left),
                onPressed: onPrevious,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${months[month.month - 1]} ${month.year}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                    ),
                  ),
                ),
              ),
              IconButton(
                constraints: buttonConstraints,
                padding: EdgeInsets.zero,
                tooltip: 'Вперёд',
                icon: const Icon(Icons.chevron_right),
                // null отключает кнопку, если листать вперёд нельзя.
                onPressed: canGoNext ? onNext : null,
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Подписи дней недели.
          Row(
            children: [
              for (final day in weekdaysShort)
                Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 6),

          // Сетка дней с анимацией изменения высоты.
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Builder(
              builder: (context) {
                final cells = _cells;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cells.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    childAspectRatio: 1.4,
                  ),
                  itemBuilder: (context, index) {
                    final date = cells[index];

                    // Пустая ячейка (только в развёрнутом режиме).
                    if (date == null) return const SizedBox.shrink();

                    final dateOnly = DateUtils.dateOnly(date);
                    final entry = entries[dateOnly];

                    return DayCell(
                      date: dateOnly,
                      rating: entry?.rating,
                      isSelected: dateOnly == selected,
                      isToday: dateOnly == today,
                      isFuture: dateOnly.isAfter(today),
                      hasDetails: entry?.hasDetails ?? false,
                      onTap: () => onDateSelected(dateOnly),
                    );
                  },
                );
              },
            ),
          ),
          // Нижний padding обеспечивается EdgeInsets.all(10) контейнера.
        ],
      ),
    );
  }
}