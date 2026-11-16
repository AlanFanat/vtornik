import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../data/day_entry.dart';
import '../../widgets/section_title.dart';
import 'day_card.dart';
import 'feed_filter.dart';
import 'period_math.dart';
import 'period_selector.dart';
import 'period_summary_card.dart';
import 'stats_feed_controls.dart';
import 'stats_tags.dart';
import 'stats_weekdays.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({
    super.key,
    required this.entries,
    required this.availableTags,
    required this.onDaySelected,
  });

  final Map<DateTime, DayEntry> entries;
  final List<String> availableTags;
  final ValueChanged<DateTime> onDaySelected;

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  StatsPeriod _period = StatsPeriod.allTime;
  int _pagesBack = 0;
  int _direction = 1;

  bool _isFeedMode = false;
  FeedFilterState _feedFilter = const FeedFilterState();

  void _changePeriod(StatsPeriod period) {
    setState(() {
      _period = period;
      _pagesBack = 0;
      _direction = 0;
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
    final colors = context.colors;
    final today = DateUtils.dateOnly(DateTime.now());
    final range = statsRange(_period, today, _pagesBack);
    final filtered = filterEntriesByRange(widget.entries, range);
    final bounds = entriesDateBounds(widget.entries);
    final days = filtered.values.toList();

    final label = range != null
        ? periodLabel(_period, range)
        : allTimeLabel(bounds);
    final caption = _period == StatsPeriod.allTime
        ? 'Всё время'
        : periodCaption(_period, _pagesBack);
    final canGoPrevious =
        range != null && bounds != null && range.start.isAfter(bounds.start);
    final canGoNext = _pagesBack > 0;

    // Список для обычного режима статистики
    final sortedEntries = filtered.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    // Список для режима ленты с фильтрами
    final feedItems = _isFeedMode
        ? filterFeedEntries(widget.entries, range, _feedFilter)
        : const <MapEntry<DateTime, DayEntry>>[];

    final allUsedTags = {
      for (final entry in widget.entries.values) ...entry.tags,
    };

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Шапка с переключателем "Лента / Статистика"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    PageTitle(_isFeedMode ? 'Лента' : 'Статистика'),
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => setState(() => _isFeedMode = !_isFeedMode),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _isFeedMode
                              ? accentColor.withValues(alpha: 0.14)
                              : colors.card,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: _isFeedMode
                                ? accentColor
                                : colors.cardBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isFeedMode
                                  ? Icons.bar_chart
                                  : Icons.view_agenda_outlined,
                              size: 16,
                              color: _isFeedMode ? accentColor : colors.text,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isFeedMode ? 'Статистика' : 'Лента',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _isFeedMode ? accentColor : colors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Селектор периода и карточка периода остаются сверху всегда
                PeriodSelector(selected: _period, onChanged: _changePeriod),
                const SizedBox(height: 6),
                PeriodSummaryCard(
                  label: label,
                  caption: caption,
                  direction: _direction,
                  canGoPrevious: canGoPrevious,
                  canGoNext: canGoNext,
                  onPrevious: _goBack,
                  onNext: _goForward,
                  onReset: _goToCurrent,
                  days: days,
                ),
                const SizedBox(height: 6),

                if (_isFeedMode)
                  StatsFeedControls(
                    availableTags: widget.availableTags,
                    allUsedTags: allUsedTags,
                    filter: _feedFilter,
                    filteredCount: feedItems.length,
                    periodBaseCount: filtered.length,
                    onFilterChanged: (next) =>
                        setState(() => _feedFilter = next),
                  )
                else ...[
                  StatsWeekdays(entries: filtered),
                  const SizedBox(height: 6),
                  StatsTags(days: days),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),

        if (_isFeedMode) ...[
          if (feedItems.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _feedFilter.hasAnyFilter
                            ? 'Ничего не найдено'
                            : 'Нет записей за этот период',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.text,
                        ),
                      ),
                      if (_feedFilter.hasAnyFilter) ...[
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: () => setState(
                            () => _feedFilter = const FeedFilterState(),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Сбросить фильтры'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              sliver: SliverList.separated(
                itemCount: feedItems.length,
                itemBuilder: (context, index) {
                  final item = feedItems[index];
                  return DayCard(
                    date: item.key,
                    entry: item.value,
                    maxNoteLines: 4,
                    highlightQuery: _feedFilter.query,
                    onTap: () => widget.onDaySelected(item.key),
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(height: 4),
              ),
            ),
        ] else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const SectionTitle('Дни за период'),
                      const SizedBox(width: 8),
                      Text(
                        '${sortedEntries.length}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.disabledText,
                        ),
                      ),
                    ],
                  ),
                  if (sortedEntries.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(() => _isFeedMode = true),
                      child: const Text(
                        'Поиск и фильтры',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: accentColor,
                        ),
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
                    style: TextStyle(color: colors.disabledText, fontSize: 14),
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
      ],
    );
  }
}