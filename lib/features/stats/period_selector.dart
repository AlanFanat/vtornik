import 'package:flutter/material.dart';

import '../../core/colors.dart';
import 'stats_period.dart';

/// Переключатель масштаба статистики: «Неделя», «Месяц», «Всё время».
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final StatsPeriod selected;
  final ValueChanged<StatsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.cardBorder),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _PeriodTab(
            title: 'Неделя',
            isSelected: selected == StatsPeriod.week,
            onTap: () => onChanged(StatsPeriod.week),
          ),
          _PeriodTab(
            title: 'Месяц',
            isSelected: selected == StatsPeriod.month,
            onTap: () => onChanged(StatsPeriod.month),
          ),
          _PeriodTab(
            title: 'Всё время',
            isSelected: selected == StatsPeriod.allTime,
            onTap: () => onChanged(StatsPeriod.allTime),
          ),
        ],
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  const _PeriodTab({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : colors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
