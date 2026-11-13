import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/constants.dart';
import '../../widgets/section_title.dart';

/// Блок «Теги дня»: до [maxTagRows] рядов тегов по частоте,
/// кнопка «Ещё» (раскрывает все теги с «+ Тег» в конце) и инлайн-панель создания тега.
class TagsSection extends StatefulWidget {
  const TagsSection({
    super.key,
    required this.availableTags,
    required this.selectedTags,
    required this.onToggle,
    required this.onAddTag,
    required this.onCreateAndSelectTag,
    required this.onManageTag,
  });

  final List<String> availableTags;
  final Set<String> selectedTags;
  final void Function(String tag, bool selected) onToggle;
  final ValueChanged<String> onAddTag;
  final ValueChanged<String> onCreateAndSelectTag;
  final ValueChanged<String> onManageTag;

  @override
  State<TagsSection> createState() => _TagsSectionState();
}

class _TagsSectionState extends State<TagsSection> {
  static const double _chipSpacing = 6;
  static const double _chipRunSpacing = 4;
  static const double _chipHorizontalPadding = 24; // 22 (11 слева + 11 справа) + 2 запас
  static const TextStyle _chipTextStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  /// Порядок тегов фиксируется на время редактирования этого дня,
  /// чтобы выбор тега не перестраивал уже показанные чипы.
  late List<String> _sessionOrder = [...widget.availableTags];

  bool _isExpanded = false;
  bool _isAdding = false;
  final TextEditingController _inputController = TextEditingController();

  @override
  void didUpdateWidget(TagsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.availableTags != oldWidget.availableTags) {
      final currentSet = widget.availableTags.toSet();
      final kept = _sessionOrder.where(currentSet.contains).toList();
      final keptSet = kept.toSet();
      final added = [
        for (final tag in widget.availableTags)
          if (!keptSet.contains(tag)) tag,
      ];
      _sessionOrder = [...kept, ...added];
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  // ----- Расчёт вместимости в 3 ряда -----

  double _measureTextWidth(String text, TextScaler textScaler) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: _chipTextStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
    return painter.width.ceilToDouble();
  }

  /// Упаковывает теги по строкам с заполнением пустот (Lookahead / Best-Fit).
  List<List<String>> _packRows({
    required List<String> tags,
    required double maxWidth,
    required double Function(String) tagWidth,
    int? maxRows,
    double reserveInLastRow = 0.0,
  }) {
    if (tags.isEmpty || maxWidth <= 0) return const [];

    final rows = <List<String>>[];
    final pool = [...tags];

    while (pool.isNotEmpty) {
      if (maxRows != null && rows.length >= maxRows) break;

      final isLastRow = maxRows != null && rows.length == maxRows - 1;
      final limit = isLastRow && reserveInLastRow > 0
          ? maxWidth - reserveInLastRow
          : maxWidth;

      final currentRow = <String>[];
      var currentWidth = 0.0;

      while (pool.isNotEmpty) {
        final first = pool.first;
        final firstWidth = tagWidth(first);
        final neededWidth = currentRow.isEmpty
            ? firstWidth
            : _chipSpacing + firstWidth;

        if (currentWidth + neededWidth <= limit) {
          currentRow.add(first);
          currentWidth += neededWidth;
          pool.removeAt(0);
          continue;
        }

        // Lookahead / Best-Fit: ищем среди следующих тегов тот,
        // который максимально заполнит оставшееся пустое место в этой строке
        final availableSpace = limit - currentWidth;
        var bestIndex = -1;
        var bestWidth = 0.0;

        for (var i = 1; i < pool.length; i++) {
          final candidate = pool[i];
          final candidateWidth = currentRow.isEmpty
              ? tagWidth(candidate)
              : _chipSpacing + tagWidth(candidate);

          if (candidateWidth <= availableSpace && candidateWidth > bestWidth) {
            bestWidth = candidateWidth;
            bestIndex = i;
          }
        }

        if (bestIndex != -1) {
          final candidate = pool.removeAt(bestIndex);
          currentRow.add(candidate);
          currentWidth += bestWidth;
        } else {
          break;
        }
      }

      if (currentRow.isEmpty) {
        currentRow.add(pool.removeAt(0));
      }

      rows.add(currentRow);
    }

    return rows;
  }

  _TagsLayout _computeLayout(double maxWidth, TextScaler textScaler) {
    if (maxWidth <= 0) {
      return _TagsLayout(
        visibleTags: _sessionOrder,
        moreCount: 0,
        showAddButton: true,
        showMoreButton: false,
        showCollapseButton: false,
      );
    }

    final sessionSet = _sessionOrder.toSet();
    final allOrdered = [
      ..._sessionOrder,
      for (final tag in widget.selectedTags)
        if (!sessionSet.contains(tag)) tag,
    ];

    double tagWidth(String tag) =>
        _measureTextWidth(tag, textScaler) + _chipHorizontalPadding;

    final addWidth = _measureTextWidth('Тег', textScaler) + 44.0;
    final moreWidth =
        _measureTextWidth('Ещё · ${allOrdered.length}', textScaler) + 30.0;

    // 1. Упаковка базовых тегов по строкам с Lookahead
    final baseRows = _packRows(
      tags: _sessionOrder,
      maxWidth: maxWidth,
      tagWidth: tagWidth,
      maxRows: maxTagRows,
      reserveInLastRow: moreWidth + _chipSpacing,
    );

    final baseVisible = baseRows.expand((r) => r).toList();
    final baseSet = baseVisible.toSet();
    final tagsFromMore = [
      for (final tag in _sessionOrder)
        if (!baseSet.contains(tag)) tag,
    ];

    // Есть ли среди тегов из «Ещё» хотя бы один невыбранный
    final hasUnselectedInMore = tagsFromMore.any(
      (tag) => !widget.selectedTags.contains(tag),
    );

    // Если всё поместилось в 3 ряда без кнопки «Ещё»
    if (tagsFromMore.isEmpty) {
      final packedWithAdd = _packRows(
        tags: allOrdered,
        maxWidth: maxWidth,
        tagWidth: tagWidth,
        maxRows: maxTagRows,
        reserveInLastRow: addWidth + _chipSpacing,
      );
      final allPacked = packedWithAdd.expand((r) => r).toList();

      return _TagsLayout(
        visibleTags: allPacked,
        moreCount: 0,
        showAddButton: true,
        showMoreButton: false,
        showCollapseButton: false,
      );
    }

    // Если блок уже раскрыт пользователем:
    // Пакуем ВСЕ теги с Lookahead, чтобы и в раскрытом виде не было дыр
    if (_isExpanded) {
      final expandedRows = _packRows(
        tags: allOrdered,
        maxWidth: maxWidth,
        tagWidth: tagWidth,
      );
      return _TagsLayout(
        visibleTags: expandedRows.expand((r) => r).toList(),
        moreCount: 0,
        showAddButton: true,
        showMoreButton: false,
        showCollapseButton: hasUnselectedInMore,
      );
    }

    // В свернутом виде при переполнении:
    // Базовые теги (плотно уложенные в 3 ряда с резервом под «Ещё»)
    // плюс выбранные из «Ещё» теги
    final extraSelected = [
      for (final tag in allOrdered)
        if (widget.selectedTags.contains(tag) && !baseSet.contains(tag)) tag,
    ];

    final visibleTags = [...baseVisible, ...extraSelected];
    final visibleSet = visibleTags.toSet();
    final moreCount =
        _sessionOrder.where((t) => !visibleSet.contains(t)).length;

    return _TagsLayout(
      visibleTags: visibleTags,
      moreCount: moreCount,
      showAddButton: moreCount == 0,
      showMoreButton: moreCount > 0,
      showCollapseButton: false,
    );
  }

  // ----- Действия инлайн-панели добавления -----

  void _closeAdd() {
    setState(() {
      _isAdding = false;
      _inputController.clear();
    });
  }

  void _toggleAdd() {
    setState(() {
      _isAdding = !_isAdding;
      _inputController.clear();
    });
  }

  void _submitAdd() {
    final name = _inputController.text.trim();
    if (name.isEmpty) return;
    if (!_sessionOrder.contains(name)) {
      _sessionOrder = [..._sessionOrder, name];
    }
    widget.onCreateAndSelectTag(name);
    _closeAdd();
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _computeLayout(constraints.maxWidth, textScaler);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SectionTitle('Теги дня'),
                const SizedBox(width: 8),
                if (layout.visibleTags.isNotEmpty)
                  const Expanded(
                    child: Text(
                      'удерживайте тег, чтобы изменить',
                      textAlign: TextAlign.end,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: _chipSpacing,
              runSpacing: _chipRunSpacing,
              children: [
                for (final tag in layout.visibleTags)
                  _TagChip(
                    label: tag,
                    selected: widget.selectedTags.contains(tag),
                    onTap: () => widget.onToggle(
                      tag,
                      !widget.selectedTags.contains(tag),
                    ),
                    onLongPress: () => widget.onManageTag(tag),
                  ),
                if (layout.showMoreButton)
                  _SecondaryChip(
                    label: layout.moreCount > 0
                        ? 'Ещё · ${layout.moreCount}'
                        : 'Ещё',
                    active: false,
                    onTap: () => setState(() => _isExpanded = true),
                  ),
                if (layout.showAddButton)
                  _SecondaryChip(
                    icon: Icons.add,
                    label: 'Тег',
                    active: _isAdding,
                    onTap: _toggleAdd,
                  ),
                if (layout.showCollapseButton)
                  _SecondaryChip(
                    icon: Icons.expand_less,
                    label: 'Свернуть',
                    active: false,
                    onTap: () => setState(() => _isExpanded = false),
                  ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _isAdding
                  ? _buildAddPanel(context)
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddPanel(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              autofocus: true,
              maxLength: maxTagLength,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              style: TextStyle(color: colors.text, fontSize: 13),
              onSubmitted: (_) => _submitAdd(),
              decoration: InputDecoration(
                counterText: '',
                hintText: 'Новый тег (например, Спорт)',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                isDense: true,
                filled: true,
                fillColor: colors.card,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.cardBorder),
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
          FilledButton(
            onPressed: _submitAdd,
            style: FilledButton.styleFrom(
              backgroundColor: accentColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Добавить', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: _closeAdd,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _TagsLayout {
  const _TagsLayout({
    required this.visibleTags,
    required this.moreCount,
    required this.showAddButton,
    required this.showMoreButton,
    required this.showCollapseButton,
  });

  final List<String> visibleTags;
  final int moreCount;
  final bool showAddButton;
  final bool showMoreButton;
  final bool showCollapseButton;
}

/// Чип тега с точными отступами (совпадает с расчётом ширины в _computeLayout).
class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );

    return Material(
      color: selected ? accentColor : colors.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : colors.text,
            ),
          ),
        ),
      ),
    );
  }
}

/// Кнопка «Ещё · K», «+ Тег» или «Свернуть».
class _SecondaryChip extends StatelessWidget {
  const _SecondaryChip({
    this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData? icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: active ? accentColor : colors.cardBorder),
    );

    return Material(
      color: active ? accentColor.withValues(alpha: 0.12) : Colors.transparent,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: icon != null ? 10 : 12,
            vertical: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: active ? accentColor : colors.text),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: active ? accentColor : colors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
