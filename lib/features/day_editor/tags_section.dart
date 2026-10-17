import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../widgets/section_title.dart';

const VisualDensity _chipDensity = VisualDensity(horizontal: -3, vertical: -3);

/// Блок «Теги дня»: заголовок, подсказка и сами теги с кнопкой «+ Тег».
class TagsSection extends StatelessWidget {
  const TagsSection({
    super.key,
    required this.availableTags,
    required this.selectedTags,
    required this.onToggle,
    required this.onAdd,
    required this.onManage,
  });

  final List<String> availableTags;
  final Set<String> selectedTags;
  final void Function(String tag, bool selected) onToggle;
  final VoidCallback onAdd;

  /// Долгое нажатие на тег: переименовать или удалить.
  final ValueChanged<String> onManage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SectionTitle('Теги дня'),
            const SizedBox(width: 8),
            if (availableTags.isNotEmpty)
              const Expanded(
                child: Text(
                  'удерживайте тег, чтобы изменить',
                  textAlign: TextAlign.end,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final tag in availableTags)
              _TagChip(
                tag: tag,
                selected: selectedTags.contains(tag),
                onSelected: (selected) => onToggle(tag, selected),
                onLongPress: () => onManage(tag),
              ),
            _AddTagChip(onPressed: onAdd),
          ],
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.tag,
    required this.selected,
    required this.onSelected,
    required this.onLongPress,
  });

  final String tag;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onLongPress: onLongPress,
      child: FilterChip(
        label: Text(
          tag,
          style: TextStyle(
            fontSize: 12,
            // На акценте текст тёмный в любой теме.
            color: selected ? onAccentColor : colors.text,
          ),
        ),
        selected: selected,
        onSelected: onSelected,
        selectedColor: accentColor,
        backgroundColor: colors.surface,
        showCheckmark: false,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        visualDensity: _chipDensity,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}

/// Кнопка добавления нового тега.
class _AddTagChip extends StatelessWidget {
  const _AddTagChip({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ActionChip(
      avatar: Icon(Icons.add, size: 16, color: colors.text),
      label: Text('Тег', style: TextStyle(fontSize: 12, color: colors.text)),
      onPressed: onPressed,
      backgroundColor: Colors.transparent,
      side: BorderSide(color: colors.cardBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      visualDensity: _chipDensity,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      labelPadding: const EdgeInsets.only(right: 4),
    );
  }
}
