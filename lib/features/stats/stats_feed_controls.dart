import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../widgets/section_title.dart';
import 'feed_filter.dart';

class StatsFeedControls extends StatefulWidget {
  const StatsFeedControls({
    super.key,
    required this.availableTags,
    required this.allUsedTags,
    required this.filter,
    required this.filteredCount,
    required this.periodBaseCount,
    required this.onFilterChanged,
  });

  final List<String> availableTags;
  final Set<String> allUsedTags;
  final FeedFilterState filter;
  final int filteredCount;
  final int periodBaseCount;
  final ValueChanged<FeedFilterState> onFilterChanged;

  @override
  State<StatsFeedControls> createState() => _StatsFeedControlsState();
}

class _StatsFeedControlsState extends State<StatsFeedControls> {
  bool _filtersOpen = false;
  late final TextEditingController _searchController = TextEditingController(
    text: widget.filter.query,
  );

  @override
  void didUpdateWidget(covariant StatsFeedControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filter.query != _searchController.text) {
      _searchController.text = widget.filter.query;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _allTags {
    final merged = [...widget.availableTags];
    final seen = merged.toSet();
    for (final tag in widget.allUsedTags) {
      if (seen.add(tag)) merged.add(tag);
    }
    return merged;
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final current = isFrom ? widget.filter.customFrom : widget.filter.customTo;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? today,
      firstDate: DateTime(2000),
      lastDate: today,
    );
    if (picked == null) return;
    final clean = DateUtils.dateOnly(picked);
    widget.onFilterChanged(
      isFrom
          ? widget.filter.copyWith(customFrom: () => clean)
          : widget.filter.copyWith(customTo: () => clean),
    );
  }

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day.$month.${d.year}';
  }

  String _formatRatingsSummary() {
    final sorted = [...widget.filter.selectedRatings]..sort();
    final parts = <String>[];
    if (sorted.isNotEmpty) {
      var start = sorted.first;
      var prev = sorted.first;
      final groups = <String>[];
      for (var i = 1; i < sorted.length; i++) {
        if (sorted[i] == prev + 1) {
          prev = sorted[i];
        } else {
          groups.add(start == prev ? '$start' : '$start–$prev');
          start = sorted[i];
          prev = sorted[i];
        }
      }
      groups.add(start == prev ? '$start' : '$start–$prev');
      parts.add('Оценка: ${groups.join(', ')}');
    }
    if (widget.filter.onlyUnrated) parts.add('Без оценки');
    return parts.join(' · ');
  }

  bool _isPresetActive(List<int> ratings, {bool unrated = false}) {
    if (widget.filter.onlyUnrated != unrated) return false;
    if (widget.filter.selectedRatings.length != ratings.length) return false;
    for (var i = 0; i < ratings.length; i++) {
      if (widget.filter.selectedRatings[i] != ratings[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final f = widget.filter;
    final activeCount = f.activeFilterCount;
    final hasCustomDates = f.customFrom != null || f.customTo != null;
    final hasRatingSelection = f.selectedRatings.isNotEmpty || f.onlyUnrated;
    final filterHighlight = _filtersOpen || activeCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Поиск + кнопка Фильтр
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                style: TextStyle(fontSize: 13, color: colors.text),
                onChanged: (value) =>
                    widget.onFilterChanged(f.copyWith(query: value)),
                decoration: InputDecoration(
                  hintText: 'Поиск по заметкам...',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                  isDense: true,
                  filled: true,
                  fillColor: colors.card,
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: Colors.grey,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  suffixIcon: f.query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.grey,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            widget.onFilterChanged(f.copyWith(query: ''));
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: accentColor),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => _filtersOpen = !_filtersOpen),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: filterHighlight
                      ? accentColor.withValues(alpha: 0.12)
                      : colors.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: filterHighlight ? accentColor : colors.cardBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune,
                      size: 16,
                      color: filterHighlight ? accentColor : colors.text,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Фильтр',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: filterHighlight ? accentColor : colors.text,
                      ),
                    ),
                    if (activeCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$activeCount',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),

        // Встроенная панель фильтров
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _filtersOpen
              ? Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Оценка
                      _FilterGroupHeader(
                        title: 'Оценка',
                        showReset: hasRatingSelection,
                        onReset: () => widget.onFilterChanged(
                          f.copyWith(selectedRatings: const [], onlyUnrated: false),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _FilterChipPill(
                            label: 'Любая',
                            selected: !hasRatingSelection,
                            onTap: () => widget.onFilterChanged(
                              f.copyWith(
                                selectedRatings: const [],
                                onlyUnrated: false,
                              ),
                            ),
                          ),
                          _FilterChipPill(
                            label: 'Без оценки',
                            selected: f.onlyUnrated,
                            onTap: () => widget.onFilterChanged(
                              f.copyWith(onlyUnrated: !f.onlyUnrated),
                            ),
                          ),
                          _FilterChipPill(
                            label: '1–4',
                            selected: _isPresetActive(const [1, 2, 3, 4]),
                            onTap: () => widget.onFilterChanged(
                              f.copyWith(
                                selectedRatings: const [1, 2, 3, 4],
                                onlyUnrated: false,
                              ),
                            ),
                          ),
                          _FilterChipPill(
                            label: '5–7',
                            selected: _isPresetActive(const [5, 6, 7]),
                            onTap: () => widget.onFilterChanged(
                              f.copyWith(
                                selectedRatings: const [5, 6, 7],
                                onlyUnrated: false,
                              ),
                            ),
                          ),
                          _FilterChipPill(
                            label: '8–10',
                            selected: _isPresetActive(const [8, 9, 10]),
                            onTap: () => widget.onFilterChanged(
                              f.copyWith(
                                selectedRatings: const [8, 9, 10],
                                onlyUnrated: false,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (var r = 1; r <= 10; r++) ...[
                            if (r > 1) const SizedBox(width: 4),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  final next = [...f.selectedRatings];
                                  if (next.contains(r)) {
                                    next.remove(r);
                                  } else {
                                    next.add(r);
                                    next.sort();
                                  }
                                  widget.onFilterChanged(
                                    f.copyWith(selectedRatings: next),
                                  );
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 120),
                                  height: 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: ratingColor(r).withValues(
                                      alpha: (hasRatingSelection &&
                                              !f.selectedRatings.contains(r))
                                          ? 0.35
                                          : 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(7),
                                    border: f.selectedRatings.contains(r)
                                        ? Border.all(
                                            color: accentColor,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                  child: Text(
                                    '$r',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: colors.onRatingColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Теги
                      _FilterGroupHeader(
                        title: f.selectedTags.length > 1
                            ? 'Теги (все выбранные)'
                            : 'Теги',
                        showReset: f.selectedTags.isNotEmpty,
                        onReset: () => widget.onFilterChanged(
                          f.copyWith(selectedTags: const []),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (_allTags.isEmpty)
                        const Text(
                          'Нет доступных тегов',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        )
                      else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 140),
                          child: SingleChildScrollView(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final tag in _allTags)
                                  _FilterChipPill(
                                    label: tag,
                                    selected: f.selectedTags.contains(tag),
                                    onTap: () {
                                      final next = [...f.selectedTags];
                                      if (next.contains(tag)) {
                                        next.remove(tag);
                                      } else {
                                        next.add(tag);
                                      }
                                      widget.onFilterChanged(
                                        f.copyWith(selectedTags: next),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 14),

                      // Точные даты
                      _FilterGroupHeader(
                        title: 'Точные даты',
                        showReset: hasCustomDates,
                        onReset: () => widget.onFilterChanged(
                          f.copyWith(
                            customFrom: () => null,
                            customTo: () => null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _DateButton(
                              label: 'От',
                              value: f.customFrom != null
                                  ? _formatDate(f.customFrom!)
                                  : 'Выбрать',
                              hasValue: f.customFrom != null,
                              onTap: () => _pickDate(isFrom: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _DateButton(
                              label: 'До',
                              value: f.customTo != null
                                  ? _formatDate(f.customTo!)
                                  : 'Выбрать',
                              hasValue: f.customTo != null,
                              onTap: () => _pickDate(isFrom: false),
                            ),
                          ),
                        ],
                      ),

                      if (f.hasAnyFilter) ...[
                        const SizedBox(height: 12),
                        Divider(height: 1, color: colors.cardBorder),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Найдено дней: ${widget.filteredCount}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                widget.onFilterChanged(const FeedFilterState());
                              },
                              child: const Text(
                                'Сбросить все фильтры',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: accentColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // Чипы активных фильтров
        if (activeCount > 0) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (hasCustomDates)
                _ActiveChip(
                  label:
                      '${f.customFrom != null ? _formatDate(f.customFrom!) : '...'} – ${f.customTo != null ? _formatDate(f.customTo!) : '...'}',
                  onRemove: () => widget.onFilterChanged(
                    f.copyWith(customFrom: () => null, customTo: () => null),
                  ),
                ),
              if (hasRatingSelection)
                _ActiveChip(
                  label: _formatRatingsSummary(),
                  onRemove: () => widget.onFilterChanged(
                    f.copyWith(selectedRatings: const [], onlyUnrated: false),
                  ),
                ),
              for (final tag in f.selectedTags)
                _ActiveChip(
                  label: '#$tag',
                  onRemove: () => widget.onFilterChanged(
                    f.copyWith(
                      selectedTags:
                          f.selectedTags.where((t) => t != tag).toList(),
                    ),
                  ),
                ),
            ],
          ),
        ],

        // Заголовок со счётчиком
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 6),
          child: Row(
            children: [
              const SectionTitle('Дни'),
              const SizedBox(width: 8),
              Text(
                f.hasAnyFilter && !hasCustomDates
                    ? '${widget.filteredCount} из ${widget.periodBaseCount}'
                    : '${widget.filteredCount}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.disabledText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterGroupHeader extends StatelessWidget {
  const _FilterGroupHeader({
    required this.title,
    required this.showReset,
    required this.onReset,
  });

  final String title;
  final bool showReset;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        if (showReset)
          GestureDetector(
            onTap: onReset,
            child: const Text(
              'Сбросить',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: accentColor,
              ),
            ),
          ),
      ],
    );
  }
}

class _FilterChipPill extends StatelessWidget {
  const _FilterChipPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? accentColor : colors.surface,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : colors.text,
          ),
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.hasValue,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool hasValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: colors.inputFill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$label: $value',
              style: TextStyle(
                fontSize: 12,
                color: hasValue ? colors.text : Colors.grey,
              ),
            ),
            const Icon(Icons.calendar_today, size: 13, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onRemove,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: colors.text)),
            const SizedBox(width: 4),
            const Icon(Icons.close, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}