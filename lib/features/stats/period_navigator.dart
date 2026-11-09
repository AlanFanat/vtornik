import 'package:flutter/material.dart';

import '../../core/colors.dart';

/// Строка листания периода: ‹ подпись ›.
/// Работает и стрелками, и свайпом по строке; нажатие на подпись возвращает
/// к текущему периоду.
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
  });

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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Свайп влево открывает следующий (новый) период, вправо предыдущий.
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -250 && canGoNext) onNext();
        if (velocity > 250 && canGoPrevious) onPrevious();
      },
      child: Container(
        // Фиксированная высота: форма не «прыгает» при смене подписи.
        height: 56,
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.cardBorder),
        ),
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
                    child: Column(
                      key: ValueKey('$label|$caption'),
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
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
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