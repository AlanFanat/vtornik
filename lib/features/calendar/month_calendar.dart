import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/date_format.dart';
import '../../data/day_entry.dart';
import 'day_cell.dart';

/// Карточка календаря: строка навигации, подписи дней недели и сетка дней.
/// Заголовок «Календарь» и кнопки «Сегодня» / «Свернуть» находятся в HomePage,
/// состояние (месяц, режим) тоже хранится там.
class MonthCalendar extends StatefulWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.isCollapsed,
    required this.selectedDate,
    required this.entries,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    required this.onDateSelected,
  });

  final DateTime month;
  final bool isCollapsed;
  final DateTime selectedDate;
  final Map<DateTime, DayEntry> entries;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar>
    with SingleTickerProviderStateMixin {
  static const _spacing = 6.0;
  static const _aspectRatio = 1.4;

  /// 0 — показан весь месяц, 1 — одна неделя.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    value: widget.isCollapsed ? 1.0 : 0.0,
  );

  /// Остальные недели гаснут в первой части сворачивания.
  late final Animation<double> _otherRowsOpacity = Tween<double>(
    begin: 1,
    end: 0,
  ).animate(
    CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6)),
  );

  /// Дни соседних месяцев в выбранной неделе проявляются ближе к концу.
  late final Animation<double> _edgeCellsOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.4, 1.0),
  );

  /// Куда сейчас едет (или уже приехала) анимация.
  late bool _goal = widget.isCollapsed;

  // --- Переменные для обработки горизонтальных свайпов ---
  double _dragDistance = 0;

  @override
  void didUpdateWidget(MonthCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Состояние поменяли снаружи (кнопка в заголовке, восстановление).
    if (widget.isCollapsed != _goal) _settle(widget.isCollapsed);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _settle(bool collapsed) {
    _goal = collapsed;
    _controller.animateTo(
      collapsed ? 1.0 : 0.0,
      curve: Curves.easeOutCubic,
    );
  }

  // ----- Логика свайпов -----

  void _onHorizontalDragStart(DragStartDetails details) {
    _dragDistance = 0;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    _dragDistance += details.primaryDelta ?? 0;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    const velocityThreshold = 250.0;
    const distanceThreshold = 50.0; // Сдвиг от 50 пикселей

    final velocity = details.primaryVelocity ?? 0;

    if (velocity > velocityThreshold || _dragDistance > distanceThreshold) {
      // Свайп вправо -> назад
      widget.onPrevious();
    } else if (velocity < -velocityThreshold || _dragDistance < -distanceThreshold) {
      // Свайп влево -> вперёд (если можно)
      if (widget.canGoNext) {
        widget.onNext();
      }
    }
    _dragDistance = 0;
  }

  // ----- Построение -----

  Widget _buildCell({
    required DateTime date,
    required bool inMonth,
    required bool isSelectedRow,
    required DateTime today,
    required DateTime selected,
  }) {
    if (!inMonth && !isSelectedRow) return const SizedBox.shrink();

    final entry = widget.entries[date];
    final cell = DayCell(
      date: date,
      rating: entry?.rating,
      isSelected: date == selected,
      isToday: date == today,
      isFuture: date.isAfter(today),
      hasDetails: entry?.hasDetails ?? false,
      onTap: () => widget.onDateSelected(date),
    );

    if (inMonth) return cell;

    return AnimatedBuilder(
      animation: _controller,
      child: FadeTransition(opacity: _edgeCellsOpacity, child: cell),
      builder: (context, child) =>
          IgnorePointer(ignoring: _controller.value < 0.5, child: child),
    );
  }

  Widget _buildRow({
    required int row,
    required int selectedRow,
    required DateTime gridStart,
    required double cellHeight,
    required DateTime today,
    required DateTime selected,
  }) {
    final isSelectedRow = row == selectedRow;

    final rowWidget = Row(
      children: [
        for (var c = 0; c < 7; c++) ...[
          if (c > 0) const SizedBox(width: _spacing),
          Expanded(
            child: SizedBox(
              height: cellHeight,
              child: _buildCell(
                date: DateUtils.addDaysToDate(gridStart, row * 7 + c),
                inMonth:
                    DateUtils.addDaysToDate(gridStart, row * 7 + c).month ==
                    widget.month.month,
                isSelectedRow: isSelectedRow,
                today: today,
                selected: selected,
              ),
            ),
          ),
        ],
      ],
    );

    return isSelectedRow
        ? rowWidget
        : FadeTransition(opacity: _otherRowsOpacity, child: rowWidget);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final month = widget.month;
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = DateUtils.dateOnly(widget.selectedDate);

    // Геометрия месяца: понедельник первой недели и число недель.
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final startOffset = firstOfMonth.weekday - 1; // Пн = 1
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final rowCount = ((startOffset + daysInMonth) / 7).ceil();
    final gridStart = DateUtils.addDaysToDate(firstOfMonth, -startOffset);

    // Неделя, в которой лежит выбранный день.
    final selectedRow = selected.month == month.month
        ? ((startOffset + selected.day - 1) ~/ 7).clamp(0, rowCount - 1)
        : 0;

    final buttonConstraints = BoxConstraints.tightFor(
      width: 40,
      height: kMinInteractiveDimension,
    );

    // Уникальный ключ для плавного перехода через AnimatedSwitcher
    final currentWeekStart = gridStart.add(Duration(days: selectedRow * 7));
    final viewKey = widget.isCollapsed
        ? ValueKey('week_${currentWeekStart.year}_${currentWeekStart.month}_${currentWeekStart.day}')
        : ValueKey('month_${month.year}_${month.month}');

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
                onPressed: widget.onPrevious,
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
                onPressed: widget.canGoNext ? widget.onNext : null,
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
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 6),

          // Сетка с поддержкой жестов (свайпы) и плавной анимации
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: _onHorizontalDragStart,
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cellWidth = (constraints.maxWidth - 6 * _spacing) / 7;
                final cellHeight = cellWidth / _aspectRatio;
                final rowStep = cellHeight + _spacing;
                final fullHeight =
                    rowCount * cellHeight + (rowCount - 1) * _spacing;

                // Оборачиваем ряды в AnimatedSwitcher для плавного кросс-фейда
                final rows = AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: Column(
                    key: viewKey,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var r = 0; r < rowCount; r++) ...[
                        if (r > 0) const SizedBox(height: _spacing),
                        _buildRow(
                          row: r,
                          selectedRow: selectedRow,
                          gridStart: gridStart,
                          cellHeight: cellHeight,
                          today: today,
                          selected: selected,
                        ),
                      ],
                    ],
                  ),
                );

                // Плавное изменение высоты и сворачивание/разворачивание
                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: fullHeight),
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: rows,
                  builder: (context, animatedFullHeight, child) {
                    return AnimatedBuilder(
                      animation: _controller,
                      child: child,
                      builder: (context, child) {
                        final t = _controller.value;
                        final height =
                            animatedFullHeight + (cellHeight - animatedFullHeight) * t;

                        return SizedBox(
                          height: height,
                          child: ClipRect(
                            child: OverflowBox(
                              alignment: Alignment.topCenter,
                              minHeight: 0,
                              maxHeight: double.infinity,
                              child: Transform.translate(
                                offset: Offset(0, -selectedRow * rowStep * t),
                                child: child,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}