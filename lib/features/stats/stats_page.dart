import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../data/day_entry.dart';
import '../../widgets/section_title.dart';
import 'day_card.dart';
import 'period_navigator.dart';
import 'period_selector.dart';
import 'stats_grid.dart';
import 'stats_period.dart';
import 'stats_tags.dart';
import 'stats_weekdays.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({
    super.key,
    required this.entries,
    required this.onDaySelected,
  });

  final Map<DateTime, DayEntry> entries;
  final ValueChanged<DateTime> onDaySelected;

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  StatsPeriod _period = StatsPeriod.allTime;

  /// На сколько периодов (недель или месяцев) назад от текущего. 0 — текущий.
  /// Хранится именно число, а не дата: «текущий» сам пересчитывается от
  /// сегодняшней даты, даже если приложение пролежало всю ночь.
  int _pagesBack = 0;

  /// Куда листали в последний раз: от этого зависит сторона анимации.
  int _direction = 1;

  void _changePeriod(StatsPeriod period) {
    setState(() {
      _period = period;
      _pagesBack = 0;
      _direction = 1;
    });
  }

  void _goBack() => setState(() {
    _pagesBack++;
    _direction = -1;
  });

  void _goForward() => setState(() {
    _pagesBack--;
    _direction = 1;
  });

  void _goToCurrent() => setState(() {
    _pagesBack = 0;
    _direction = 1;
  });

  /// Записи, попавшие в период. Без границ — все.
  Map<DateTime, DayEntry> _filterEntries(DateTimeRange? range) {
    if (range == null) return widget.entries;

    return Map.fromEntries(
      widget.entries.entries.where((e) {
        final day = DateUtils.dateOnly(e.key);
        return !day.isBefore(range.start) && !day.isAfter(range.end);
      }),
    );
  }

  /// Первый и последний записанный день. null, если записей нет.
  /// Дальше первого дня назад листать незачем.
  DateTimeRange? _dateBounds() {
    if (widget.entries.isEmpty) return null;

    final days = widget.entries.keys.map(DateUtils.dateOnly);
    return DateTimeRange(
      start: days.reduce((a, b) => a.isBefore(b) ? a : b),
      end: days.reduce((a, b) => a.isAfter(b) ? a : b),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final today = DateUtils.dateOnly(DateTime.now());

    final range = statsRange(_period, today, _pagesBack);
    final filtered = _filterEntries(range);
    final bounds = _dateBounds();

    // Новые дни сверху.
    final sortedEntries = filtered.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return ListView.separated(
      padding: const EdgeInsets.all(10),
      // +1: нулевой элемент списка — шапка с переключателем и графиками
      itemCount: sortedEntries.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageTitle('Статистика'),
              const SizedBox(height: 6),
              PeriodSelector(selected: _period, onChanged: _changePeriod),
              const SizedBox(height: 8),
              if (range != null)
                PeriodNavigator(
                  label: periodLabel(_period, range),
                  caption: periodCaption(_period, _pagesBack),
                  direction: _direction,
                  canGoPrevious:
                      bounds != null && range.start.isAfter(bounds.start),
                  canGoNext: _pagesBack > 0,
                  onPrevious: _goBack,
                  onNext: _goForward,
                  onReset: _goToCurrent,
                )
              else
                // «Всё время»: тот же блок, но без листания.
                PeriodNavigator.fixed(
                  label: allTimeLabel(bounds),
                  caption: 'Всё время',
                ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 36,
                    horizontal: 16,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'За выбранный период записей нет',
                    style: TextStyle(color: colors.disabledText, fontSize: 14),
                  ),
                )
              else ...[
                StatsGrid(days: filtered.values.toList()),
                const SizedBox(height: 12),
                StatsWeekdays(entries: filtered),
                const SizedBox(height: 12),
                StatsTags(days: filtered.values.toList()),
                const SizedBox(height: 12),
              ],
            ],
          );
        }

        final item = sortedEntries[index - 1];
        return DayCard(
          date: item.key,
          entry: item.value,
          onTap: () => widget.onDaySelected(item.key),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 4),
    );
  }
}
