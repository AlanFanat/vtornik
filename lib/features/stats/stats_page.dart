import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../data/day_entry.dart';
import '../../widgets/section_title.dart';
import 'day_card.dart';
import 'stats_grid.dart';
import 'stats_tags.dart';
import 'stats_weekdays.dart';

enum StatsPeriod {
  week,
  month,
  allTime,
}

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
  StatsPeriod _selectedPeriod = StatsPeriod.allTime;

  Map<DateTime, DayEntry> _filterEntries(DateTime today) {
    switch (_selectedPeriod) {
      case StatsPeriod.week:
        final start = today.subtract(const Duration(days: 6));
        return Map.fromEntries(
          widget.entries.entries.where((e) {
            final d = DateUtils.dateOnly(e.key);
            return !d.isBefore(start) && !d.isAfter(today);
          }),
        );
      case StatsPeriod.month:
        final start = today.subtract(const Duration(days: 29));
        return Map.fromEntries(
          widget.entries.entries.where((e) {
            final d = DateUtils.dateOnly(e.key);
            return !d.isBefore(start) && !d.isAfter(today);
          }),
        );
      case StatsPeriod.allTime:
        return widget.entries;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final today = DateUtils.dateOnly(DateTime.now());
    final filtered = _filterEntries(today);

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
              const SizedBox(height: 10),
              _PeriodSelector(
                selected: _selectedPeriod,
                onChanged: (period) => setState(() => _selectedPeriod = period),
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
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

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selected,
    required this.onChanged,
  });

  final StatsPeriod selected;
  final ValueChanged<StatsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.cardBorder),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _buildItem(context, StatsPeriod.week, 'Неделя'),
          _buildItem(context, StatsPeriod.month, '30 дней'),
          _buildItem(context, StatsPeriod.allTime, 'Всё время'),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, StatsPeriod period, String title) {
    final isSelected = selected == period;
    final colors = context.colors;

    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(period),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : colors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
