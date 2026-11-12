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
        padding: EdgeInsets.symmetric(vertical: 8),
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
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.text,
          ),
        ),
        Text(caption, style: const TextStyle(fontSize: 14, color: Colors.grey)),
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;

    // Только непустые оценки
    final ratingsOnly = days
        .map((d) => d.rating)
        .whereType<int>() // короче, чем where + cast
        .toList();

    // Среднее — с защитой от пустого списка
    final double averageRating = ratingsOnly.isEmpty
        ? 0
        : ratingsOnly.reduce((a, b) => a + b) / ratingsOnly.length;

    final int daysCount = days.length; // всего (включая null)
    final int ratingDaysCount = ratingsOnly.length; // с оценкой

    // Форматирование среднего: 4.333... → "4.3"
    final averageText = formatAverage(averageRating);

    final avgColor = ratingsOnly.isEmpty
        ? colors.disabledText
        : ratingColor(averageRating.round().clamp(1, 10));

    return Row(
      children: [
        // Кольцевая диаграмма среднего балла
        SizedBox(
          width: 76,
          height: 76,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: CircularProgressIndicator(
                  value: ratingsOnly.isEmpty
                      ? 0.0
                      : (averageRating / 10).clamp(0.0, 1.0),
                  strokeWidth: 7,
                  strokeCap: StrokeCap.round,
                  backgroundColor: colors.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(avgColor),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ratingsOnly.isEmpty ? '—' : averageText,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: avgColor,
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
                  Icon(Icons.trending_up_rounded, size: 20, color: avgColor),
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
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
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
