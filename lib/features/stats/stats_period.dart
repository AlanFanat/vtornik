import 'package:flutter/material.dart';

import '../../core/date_format.dart';
import '../../core/date_math.dart';

/// Период статистики. Неделя и месяц календарные, их можно листать.
enum StatsPeriod { week, month, allTime }

/// Границы периода (включительно). [pagesBack] — на сколько периодов назад
/// от текущего (0 — текущий). Для «Всё время» границ нет: null.
DateTimeRange? statsRange(StatsPeriod period, DateTime today, int pagesBack) {
  switch (period) {
    case StatsPeriod.week:
      final start = DateUtils.addDaysToDate(mondayOf(today), -7 * pagesBack);
      return DateTimeRange(
        start: start,
        end: DateUtils.addDaysToDate(start, 6),
      );
    case StatsPeriod.month:
      final start = DateUtils.addMonthsToMonthDate(monthOf(today), -pagesBack);
      return DateTimeRange(start: start, end: endOfMonth(start));
    case StatsPeriod.allTime:
      return null;
  }
}

/// Крупная подпись периода: «3 – 9 ноября» или «Ноябрь 2025».
String periodLabel(StatsPeriod period, DateTimeRange range) {
  switch (period) {
    case StatsPeriod.week:
      return formatDayRange(range.start, range.end);
    case StatsPeriod.month:
      return formatMonthYear(range.start);
    case StatsPeriod.allTime:
      return '';
  }
}

/// Мелкая подпись под ней: «Эта неделя», «Прошлый месяц», «3 нед. назад».
String periodCaption(StatsPeriod period, int pagesBack) {
  final isWeek = period == StatsPeriod.week;
  if (pagesBack == 0) return isWeek ? 'Эта неделя' : 'Этот месяц';
  if (pagesBack == 1) return isWeek ? 'Прошлая неделя' : 'Прошлый месяц';
  return isWeek ? '$pagesBack нед. назад' : '$pagesBack мес. назад';
}