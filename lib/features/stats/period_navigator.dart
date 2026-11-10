import 'package:flutter/material.dart';

import '../../core/colors.dart';

void _noop() {}

/// Блок периода в статистике. В обычном виде строка листания: ‹ подпись ›.
/// Работает и стрелками, и свайпом по строке; нажатие на подпись возвращает
/// к текущему периоду. Вариант [PeriodNavigator.fixed] без стрелок: просто
/// показывает подпись (для «Всё время»).
class PeriodNavigator extends StatelessWidget {
  const PeriodNavigator({
    super.key,
    required this.label,
    required this.caption,
    required this.direction,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    required this.onReset,
  }) : showArrows = true;

  /// Тот же блок без листания: стрелок нет, свайп и нажатия отключены.
  const PeriodNavigator.fixed({
    super.key,
    required this.label,
    required this.caption,
  }) : direction = 1,
       canGoPrevious = false,
       canGoNext = false,
       onPrevious = _noop,
       onNext = _noop,
       onReset = _noop,
       showArrows = false;

  final String label;
  final String caption;

  /// В какую сторону листали последний раз: 1 — к новому периоду,
  /// -1 — к старому. От этого зависит, откуда «выезжает» новая подпись.
  final int direction;

  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onReset;
  final bool showArrows;

  @override
  Widget build(BuildContext context) {
    if (!showArrows) {
      return _Card(
        child: Center(
          child: _PeriodLabel(label: label, caption: caption),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Свайп влево открывает следующий (новый) период, вправо предыдущий.
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -250 && canGoNext) onNext();
        if (velocity > 250 && canGoPrevious) onPrevious();
      },
      child: _Card(
        child: Row(
          children: [
            _ArrowButton(
              icon: Icons.chevron_left,
              tooltip: 'Назад',
              onPressed: canGoPrevious ? onPrevious : null,
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: canGoNext ? onReset : null,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(0.15 * direction, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _PeriodLabel(
                      key: ValueKey('$label|$caption'),
                      label: label,
                      caption: caption,
                    ),
                  ),
                ),
              ),
            ),
            _ArrowButton(
              icon: Icons.chevron_right,
              tooltip: 'Вперёд',
              onPressed: canGoNext ? onNext : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Карточка фиксированной высоты: форма не «прыгает» при смене подписи.
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.cardBorder),
      ),
      child: child,
    );
  }
}

class _PeriodLabel extends StatelessWidget {
  const _PeriodLabel({super.key, required this.label, required this.caption});

  final String label;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colors.text,
          ),
        ),
        Text(
          caption,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;

  /// null — стрелка неактивна (серая).
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      color: colors.text,
      disabledColor: colors.disabledText,
      icon: Icon(icon),
    );
  }
}