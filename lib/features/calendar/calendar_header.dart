import 'package:flutter/material.dart';

import '../../widgets/section_title.dart';

/// Заголовок вкладки «Календарь» с кнопками «Сегодня» и «Свернуть / Развернуть».
class CalendarHeader extends StatelessWidget {
  const CalendarHeader({
    super.key,
    required this.isCollapsed,
    required this.showToday,
    required this.onToday,
    required this.onToggle,
  });

  /// Календарь свёрнут до одной недели.
  final bool isCollapsed;

  /// Показывать ли кнопку «Сегодня». Место под неё занято всегда,
  /// чтобы остальные элементы не сдвигались.
  final bool showToday;

  final VoidCallback onToday;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    const buttonConstraints = BoxConstraints.tightFor(width: 40, height: 40);

    // Высоту строки задаёт только заголовок; кнопки лежат поверх справа
    // и не влияют на его положение.
    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          PageTitle('Календарь'),
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedOpacity(
                    opacity: showToday ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: IgnorePointer(
                      ignoring: !showToday,
                      child: IconButton(
                        constraints: buttonConstraints,
                        padding: EdgeInsets.zero,
                        tooltip: 'Сегодня',
                        icon: const Icon(Icons.today),
                        onPressed: onToday,
                      ),
                    ),
                  ),
                  // Стрелка разворачивается на 180° в свёрнутом режиме.
                  AnimatedRotation(
                    turns: isCollapsed ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: IconButton(
                      constraints: buttonConstraints,
                      padding: EdgeInsets.zero,
                      tooltip: isCollapsed
                          ? 'Показать месяц'
                          : 'Свернуть до недели',
                      icon: const Icon(Icons.expand_less),
                      onPressed: onToggle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}