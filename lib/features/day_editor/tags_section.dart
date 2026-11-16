import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/constants.dart';
import '../../widgets/section_title.dart';

/// Один стиль текста тега и для расчёта ширины, и для отрисовки.
/// letterSpacing задан явно: иначе тема Material 3 добавляет к тексту свой
/// межбуквенный интервал, и реальная ширина тегов получается больше
/// расчётной (из-за этого кнопка «+ Тег» уезжала в четвёртый ряд).
const TextStyle _chipTextStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w500,
  height: 1.2,
  letterSpacing: 0,
);

/// Блок «Теги дня»: до [maxTagRows] рядов тегов (упакованных с Lookahead),
/// кнопка «+ Тег» и встроенная панель выбора редких / создания новых тегов.
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
  static const double _chipSpacing = 6.0;
  static const double _chipRunSpacing = 6.0;
  static const double _chipHorizontalPadding = 24.0;
  late List<String> _sessionOrder = [...widget.availableTags];
  bool _isPanelOpen = false;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _panelKey = GlobalKey();

  @override
  void didUpdateWidget(covariant TagsSection oldWidget) {
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
    _searchController.dispose();
    super.dispose();
  }

  void _openPanel() {
    setState(() {
      _isPanelOpen = true;
      _searchController.clear();
    });
    // Ждём завершения AnimatedSize (200 мс), чтобы у панели уже была полная высота
    _ensurePanelVisible(delayMs: 220);
  }

  void _closePanel() {
    FocusScope.of(context).unfocus();
    setState(() {
      _isPanelOpen = false;
      _searchController.clear();
    });
  }

  void _togglePanel() {
    if (_isPanelOpen) {
      _closePanel();
    } else {
      _openPanel();
    }
  }

  void _ensurePanelVisible({int delayMs = 280}) {
    Future.delayed(Duration(milliseconds: delayMs), () {
      final panelContext = _panelKey.currentContext;
      if (panelContext == null || !panelContext.mounted) return;

      Scrollable.ensureVisible(
        panelContext,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: 1.0,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  // ----- Расчёт вместимости с Lookahead -----

  final Map<String, double> _widthCache = {};
  TextScaler? _cachedScaler;

  double _measureTextWidth(String text, TextScaler textScaler) {
    if (_cachedScaler != textScaler) {
      _widthCache.clear();
      _cachedScaler = textScaler;
    }
    return _widthCache.putIfAbsent(text, () {
      final painter = TextPainter(
        text: TextSpan(text: text, style: _chipTextStyle),
        maxLines: 1,
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
      )..layout();
      return painter.width.ceilToDouble();
    });
  }

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

  _TagLayoutResult _computeLayout(double maxWidth, TextScaler textScaler) {
    final sessionSet = _sessionOrder.toSet();
    final allOrdered = [
      ..._sessionOrder,
      for (final tag in widget.selectedTags)
        if (!sessionSet.contains(tag)) tag,
    ];

    if (maxWidth <= 0) {
      return _TagLayoutResult(visibleTags: allOrdered, hiddenTags: const []);
    }

    // +1 px на тег: запас на субпиксельные округления.
    double tagWidth(String tag) =>
        _measureTextWidth(tag, textScaler) + _chipHorizontalPadding + 1.0;

    // Точная ширина кнопки "+ Тег" с запасом на округления субпикселей и рамку:
    // icon (14) + gap (4) + text + padding (20) + border (2) + запас (6)
    final addWidth =
        14.0 + 4.0 + _measureTextWidth('Тег', textScaler) + 20.0 + 8.0;

    // Упаковываем базовые теги в maxTagRows (3 ряда),
    // жёстко резервируя в 3-м ряду место под кнопку "+ Тег"
    final packedRows = _packRows(
      tags: _sessionOrder,
      maxWidth: maxWidth,
      tagWidth: tagWidth,
      maxRows: maxTagRows,
      reserveInLastRow: addWidth + _chipSpacing,
    );

    final baseVisible = packedRows.expand((r) => r).toList();
    final baseSet = baseVisible.toSet();

    // Выбранные из панели (или созданные) теги добавляются сверх базовых 3 рядов
    final extraSelected = [
      for (final tag in allOrdered)
        if (widget.selectedTags.contains(tag) && !baseSet.contains(tag)) tag,
    ];

    final visibleTags = [...baseVisible, ...extraSelected];
    final visibleSet = visibleTags.toSet();
    final hiddenTags = _sessionOrder
        .where((tag) => !visibleSet.contains(tag))
        .toList();

    return _TagLayoutResult(visibleTags: visibleTags, hiddenTags: hiddenTags);
  }

  void _handleCreateFromSearch() {
    final trimmed = _searchController.text.trim();
    if (trimmed.isEmpty || trimmed.length > maxTagLength) return;

    final lower = trimmed.toLowerCase();
    final existing = widget.availableTags.cast<String?>().firstWhere(
      (t) => t!.toLowerCase() == lower,
      orElse: () => null,
    );

    if (existing != null) {
      if (!widget.selectedTags.contains(existing)) {
        widget.onToggle(existing, true);
      }
      _closePanel();
      return;
    }

    setState(() {
      if (!_sessionOrder.contains(trimmed)) {
        _sessionOrder = [..._sessionOrder, trimmed];
      }
    });
    widget.onCreateAndSelectTag(trimmed);
    _closePanel();
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
            const SizedBox(height: 8),

            // Основное облако тегов + кнопка "+ Тег"
            Wrap(
              spacing: _chipSpacing,
              runSpacing: _chipRunSpacing,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final tag in layout.visibleTags)
                  _TagPill(
                    label: tag,
                    isSelected: widget.selectedTags.contains(tag),
                    onTap: () => widget.onToggle(
                      tag,
                      !widget.selectedTags.contains(tag),
                    ),
                    onLongPress: () => widget.onManageTag(tag),
                  ),
                _ActionPill(
                  icon: Icons.add,
                  label: 'Тег',
                  isActive: _isPanelOpen,
                  onTap: _togglePanel,
                ),
              ],
            ),

            // Встроенная панель выбора/поиска/создания
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _isPanelOpen
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _buildPanel(context, layout),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPanel(BuildContext context, _TagLayoutResult layout) {
    final colors = context.colors;
    final trimmed = _searchController.text.trim();
    final lower = trimmed.toLowerCase();

    // Только теги, которые НЕ попали в основной блок
    final filtered = lower.isEmpty
        ? layout.hiddenTags
        : layout.hiddenTags
              .where((t) => t.toLowerCase().contains(lower))
              .toList();

    final exactExists = widget.availableTags.any(
      (t) => t.toLowerCase() == lower,
    );
    final canCreate =
        trimmed.isNotEmpty && !exactExists && trimmed.length <= maxTagLength;
    final tooLong =
        trimmed.isNotEmpty && !exactExists && trimmed.length > maxTagLength;

    return Container(
      key: _panelKey,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Шапка панели с заголовком и крестиком
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                layout.hiddenTags.isNotEmpty
                    ? 'Другие теги и создание'
                    : 'Новый тег',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _closePanel,
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close, size: 16, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Поле поиска / создания тега (без автофокуса, с прокруткой при тапе)
          TextField(
            controller: _searchController,
            autofocus: false,
            onTap: _ensurePanelVisible,
            scrollPadding: const EdgeInsets.only(bottom: 180),
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            style: TextStyle(fontSize: 13, color: colors.text),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _handleCreateFromSearch(),
            decoration: InputDecoration(
              hintText: 'Найти или создать тег',
              hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
              isDense: true,
              filled: true,
              fillColor: colors.card,
              prefixIcon: const Icon(
                Icons.search,
                size: 16,
                color: Colors.grey,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 34,
                minHeight: 34,
              ),
              suffixIcon: _searchController.text.isNotEmpty
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
                      onPressed: () =>
                          setState(() => _searchController.clear()),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: accentColor),
              ),
            ),
          ),

          if (filtered.isNotEmpty || canCreate) ...[
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: _chipSpacing,
                  runSpacing: _chipRunSpacing,
                  children: [
                    for (final tag in filtered)
                      _TagPill(
                        label: tag,
                        isSelected: false,
                        mutedSurface: true,
                        onTap: () {
                          widget.onToggle(tag, true);
                          if (_searchController.text.isNotEmpty) {
                            setState(() => _searchController.clear());
                          }
                        },
                        onLongPress: () => widget.onManageTag(tag),
                      ),
                    if (canCreate)
                      GestureDetector(
                        onTap: _handleCreateFromSearch,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.add,
                                size: 14,
                                color: accentColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Создать тег «$trimmed»',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colors.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],

          if (filtered.isEmpty && !canCreate && !tooLong && trimmed.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                exactExists
                    ? 'Тег «$trimmed» уже есть выше'
                    : 'Ничего не найдено',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),

          if (tooLong)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Название тега не должно превышать $maxTagLength символов',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}

class _TagLayoutResult {
  const _TagLayoutResult({required this.visibleTags, required this.hiddenTags});

  final List<String> visibleTags;
  final List<String> hiddenTags;
}

class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    this.mutedSurface = false,
  });

  final String label;
  final bool isSelected;
  final bool mutedSurface;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bg = isSelected
        ? accentColor
        : mutedSurface
        ? colors.cardBorder
        : colors.surface;
    final fg = isSelected ? Colors.white : colors.text;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: _chipTextStyle.copyWith(color: fg)),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData? icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: icon != null ? 10 : 12,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? accentColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: isActive ? accentColor : colors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isActive ? accentColor : colors.text),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: _chipTextStyle.copyWith(
                color: isActive ? accentColor : colors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
