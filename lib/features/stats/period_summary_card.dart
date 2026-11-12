import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/format_number.dart';
import '../../data/day_entry.dart';

/// Блок периода в статистике. В обычном виде строка листания: ‹ подпись ›.
/// Работает и стрелками, и свайпом по строке; нажатие на подпись возвращает
/// к текущему периоду. Вариант [PeriodNavigator.fixed] без стрелок: просто
/// показывает подпись (для «Всё время»).
class PeriodSummaryCard extends StatelessWidget {
  const PeriodSummaryCard({
    super.key,
    required this.label,
    required this.caption,
    required this.direction,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    required this.onReset,
    required this.days,
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

  final List<DayEntry> days;

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
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.cardBorder),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            _PeriodNavigator(
              label: label,
              caption: caption,
              direction: direction,
              canGoPrevious: canGoPrevious,
              canGoNext: canGoNext,
              onPrevious: onPrevious,
              onNext: onNext,
              onReset: onReset,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: _SummaryCard(days: days),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodNavigator extends StatelessWidget {
  const _PeriodNavigator({
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
  final int direction;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final currentKey = ValueKey('$label|$caption');

    return Row(
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
              // ClipRect: подписи не вылезают за границы зоны при сдвиге.
              child: ClipRect(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.linear,
                  switchOutCurve: Curves.linear,
                  // Чтобы не было «призрака» (две подписи видны одновременно):
                  // уходящая гаснет в первую треть анимации и почти не
                  // двигается, входящая начинает проявляться после неё и
                  // въезжает со стороны direction.
                  // direction == 0 (смена типа периода) — фейд без сдвига.
                  // AnimatedSwitcher пересобирает transition и для уходящих
                  // виджетов, поэтому currentKey и direction актуальны.
                  transitionBuilder: (child, animation) {
                    final isIncoming = child.key == currentKey;

                    // У уходящей animation идёт от 1 к 0, поэтому её
                    // непрозрачность падает, пока animation > 0.7.
                    final opacity = animation.drive(
                      CurveTween(
                        curve: isIncoming
                            ? const Interval(0.25, 0.65)
                            : const Interval(0.7, 1.0),
                      ),
                    );
                    final slide = animation.drive(
                      CurveTween(
                        curve: isIncoming
                            ? Curves.easeOutCubic
                            : Curves.easeInCubic,
                      ),
                    );
                    final begin = Offset(
                      (isIncoming ? 0.3 : -0.1) * direction,
                      0,
                    );

                    return FadeTransition(
                      opacity: opacity,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: begin,
                          end: Offset.zero,
                        ).animate(slide),
                        child: child,
                      ),
                    );
                  },
                  // Во всю ширину зоны: тогда смещение считается от неё,
                  // а не от ширины самого текста.
                  child: SizedBox(
                    key: currentKey,
                    width: double.infinity,
                    child: _PeriodLabel(label: label, caption: caption),
                  ),
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
    );
  }
}

class _PeriodLabel extends StatelessWidget {
  const _PeriodLabel({required this.label, required this.caption});

  final String label;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.text,
          ),
        ),
        Text(
          caption,
          style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.days});

  final List<DayEntry> days;

  // Общие параметры анимации: у кольца, числа и иконок они одинаковые,
  // поэтому всё движется синхронно.
  static const _animDuration = Duration(milliseconds: 240);
  static const _animCurve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;

    // Только непустые оценки
    final ratingsOnly = days.map((d) => d.rating).whereType<int>().toList();

    // Среднее — с защитой от пустого списка
    final double averageRating = ratingsOnly.isEmpty
        ? 0
        : ratingsOnly.reduce((a, b) => a + b) / ratingsOnly.length;

    final int daysCount = days.length; // всего (включая null)
    final int ratingDaysCount = ratingsOnly.length; // с оценкой
    final bool hasRatings = ratingsOnly.isNotEmpty;

    final avgColor = hasRatings
        ? ratingColor(averageRating.round().clamp(1, 10))
        : colors.disabledText;

    // Целевая доля кольца: 0..1
    final double targetProgress =
        hasRatings ? (averageRating / 10).clamp(0.0, 1.0) : 0.0;

    return Row(
      children: [
        // Кольцо, цвет и число в центре анимируются одним и тем же
        // движком, поэтому «докручиваются» вместе.
        AnimatedDonut(
          value: targetProgress,
          color: avgColor,
          size: 76,
          strokeWidth: 7,
          duration: _animDuration,
          curve: _animCurve,
          backgroundColor: colors.surface,
          centerBuilder: (context, animatedValue, animatedColor) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                // Без оценок показываем прочерк сразу, не считая до нуля
                hasRatings ? formatAverage(animatedValue * 10) : '—',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: animatedColor,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'из 10',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Дополнительная информация справа
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Средний балл',
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _AnimatedColorIcon(
                    icon: Icons.trending_up_rounded,
                    size: 20,
                    color: avgColor,
                    duration: _animDuration,
                    curve: _animCurve,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _MetricRow(
                icon: Icons.event_note_rounded,
                iconColor: accentColor,
                label: 'Заполнено дней',
                value: '$daysCount',
              ),
              const SizedBox(height: 6),
              _MetricRow(
                icon: Icons.star_rounded,
                iconColor: avgColor,
                label: 'С оценкой',
                value: '$ratingDaysCount',
                animateIconColor: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Иконка с плавной сменой цвета.
class _AnimatedColorIcon extends StatelessWidget {
  const _AnimatedColorIcon({
    required this.icon,
    required this.size,
    required this.color,
    required this.duration,
    required this.curve,
  });

  final IconData icon;
  final double size;
  final Color color;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: color),
      duration: duration,
      curve: curve,
      builder: (context, animatedColor, _) =>
          Icon(icon, size: size, color: animatedColor ?? color),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.animateIconColor = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  /// Плавно менять цвет иконки (для иконок, цвет которых зависит от среднего).
  final bool animateIconColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        if (animateIconColor)
          _AnimatedColorIcon(
            icon: icon,
            size: 16,
            color: iconColor,
            duration: _SummaryCard._animDuration,
            curve: _SummaryCard._animCurve,
          )
        else
          Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.text,
          ),
        ),
      ],
    );
  }
}

/// Кольцевая диаграмма с плавной анимацией значения и цвета.
///
/// В отличие от голого [CircularProgressIndicator], который при каждом
/// rebuild сразу рисует новую дугу, этот виджет анимирует переход от
/// предыдущего значения и цвета к новым. При первом показе кольцо сразу
/// стоит на нужном значении (без анимации «с нуля»).
///
/// Через [centerBuilder] можно нарисовать содержимое в центре кольца: оно
/// получает текущие анимированные значение (0..1) и цвет, так что число
/// и цвет текста идут синхронно с дугой.
class AnimatedDonut extends StatelessWidget {
  const AnimatedDonut({
    super.key,
    required this.value,
    required this.color,
    required this.backgroundColor,
    this.size = 76,
    this.strokeWidth = 7,
    this.duration = const Duration(milliseconds: 450),
    this.curve = Curves.easeOutCubic,
    this.centerBuilder,
  });

  /// Целевое значение 0.0..1.0.
  final double value;

  /// Цвет дуги (обычно ratingColor по средней).
  final Color color;

  /// Цвет фонового трека.
  final Color backgroundColor;

  final double size;
  final double strokeWidth;
  final Duration duration;
  final Curve curve;

  /// Содержимое в центре: (context, анимированное значение, анимированный цвет).
  final Widget Function(BuildContext context, double value, Color color)?
      centerBuilder;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value),
      duration: duration,
      curve: curve,
      builder: (context, animatedValue, _) => TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: color),
        duration: duration,
        curve: curve,
        builder: (context, animatedColorOrNull, _) {
          final animatedColor = animatedColorOrNull ?? color;
          return SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: size,
                  height: size,
                  child: CircularProgressIndicator(
                    value: animatedValue,
                    strokeWidth: strokeWidth,
                    strokeCap: StrokeCap.round,
                    backgroundColor: backgroundColor,
                    valueColor: AlwaysStoppedAnimation<Color>(animatedColor),
                  ),
                ),
                if (centerBuilder != null)
                  centerBuilder!(context, animatedValue, animatedColor),
              ],
            ),
          );
        },
      ),
    );
  }
}