import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../data/day_entry.dart';
import '../../widgets/section_title.dart';
import 'day_card.dart';
import 'period_math.dart';
import 'period_selector.dart';
import 'period_summary_card.dart';
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

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());

    final range = statsRange(_period, today, _pagesBack);
    final filtered = filterEntriesByRange(widget.entries, range);
    final bounds = entriesDateBounds(widget.entries);

    // Новые дни сверху.
    final sortedEntries = filtered.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          sliver: SliverToBoxAdapter(
            child: _StatsHeader(
              period: _period,
              pagesBack: _pagesBack,
              direction: _direction,
              range: range,
              bounds: bounds,
              filtered: filtered,
              onPeriodChanged: _changePeriod,
              onPrevious: _goBack,
              onNext: _goForward,
              onReset: _goToCurrent,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
            child: Row(
              children: [
                const SectionTitle('Дни за период'),
                const SizedBox(width: 8),
                Text(
                  '${sortedEntries.length}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.colors.disabledText,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (sortedEntries.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  'Нет записей за этот период',
                  style: TextStyle(
                    color: context.colors.disabledText,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            sliver: SliverList.separated(
              itemCount: sortedEntries.length,
              itemBuilder: (context, index) {
                final item = sortedEntries[index];
                return DayCard(
                  date: item.key,
                  entry: item.value,
                  onTap: () => widget.onDaySelected(item.key),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 4),
            ),
          ),
      ],
    );
  }
}

/// Шапка экрана статистики: заголовок, выбор периода, навигатор и блоки графиков.
class _StatsHeader extends StatelessWidget {
  const _StatsHeader({
    required this.period,
    required this.pagesBack,
    required this.direction,
    required this.range,
    required this.bounds,
    required this.filtered,
    required this.onPeriodChanged,
    required this.onPrevious,
    required this.onNext,
    required this.onReset,
  });

  final StatsPeriod period;
  final int pagesBack;
  final int direction;
  final DateTimeRange? range;
  final DateTimeRange? bounds;
  final Map<DateTime, DayEntry> filtered;
  final ValueChanged<StatsPeriod> onPeriodChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final days = filtered.values.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle('Статистика'),
        const SizedBox(height: 6),
        PeriodSelector(selected: period, onChanged: onPeriodChanged),
        const SizedBox(height: 6),

        PeriodSummaryCard(
          label: range != null
              ? periodLabel(period, range!)
              : allTimeLabel(bounds),
          caption: range != null
              ? periodCaption(period, pagesBack)
              : 'Всё время',
          direction: direction,
          canGoPrevious:
              range != null &&
              bounds != null &&
              range!.start.isAfter(bounds!.start),
          canGoNext: pagesBack > 0,
          onPrevious: onPrevious,
          onNext: onNext,
          onReset: onReset,
          days: days,
        ),

        const SizedBox(height: 8),
        StatsWeekdays(entries: filtered),
        const SizedBox(height: 8),
        StatsTags(days: days),
        const SizedBox(height: 8),
      ],
    );
  }
}
