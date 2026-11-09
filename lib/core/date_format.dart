import 'package:flutter/material.dart';

const List<String> weekdaysShort = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

const List<String> _weekdaysFull = [
  'Понедельник',
  'Вторник',
  'Среда',
  'Четверг',
  'Пятница',
  'Суббота',
  'Воскресенье',
];

const List<String> months = [
  'Январь',
  'Февраль',
  'Март',
  'Апрель',
  'Май',
  'Июнь',
  'Июль',
  'Август',
  'Сентябрь',
  'Октябрь',
  'Ноябрь',
  'Декабрь',
];

const List<String> _monthsGenitive = [
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

/// «17 октября», «17 октября 2025» (если год не текущий),
/// «Сегодня, 17 октября» для сегодняшнего дня.
String formatDate(DateTime date) {
  final now = DateTime.now();

  var label = '${date.day} ${_monthsGenitive[date.month - 1]}';
  if (date.year != now.year) label = '$label ${date.year}';

  return DateUtils.isSameDay(date, now) ? 'Сегодня, $label' : label;
}

String weekdayName(DateTime date) => _weekdaysFull[date.weekday - 1];

/// Возвращает, например: «Ноябрь 2026»
String formatMonthYear(DateTime date) {
  final monthName = months[date.month - 1];
  return '$monthName ${date.year}';
}

/// Возвращает:
/// - «3 – 9 ноября» (один месяц)
/// - «28 октября – 3 ноября» (разные месяцы)
/// - «29 декабря 2025 – 4 января 2026» (разные годы)
String formatDayRange(DateTime start, DateTime end) {
  final startMonth = _monthsGenitive[start.month - 1];
  final endMonth = _monthsGenitive[end.month - 1];

  // Случай 1: Переход через границу года (конец декабря -> начало января)
  if (start.year != end.year) {
    return '${start.day} $startMonth ${start.year} – ${end.day} $endMonth ${end.year}';
  }

  // Случай 2: Разные месяцы внутри одного года
  if (start.month != end.month) {
    return '${start.day} $startMonth – ${end.day} $endMonth';
  }

  // Случай 3: Дни внутри одного месяца (самый частый)
  return '${start.day} – ${end.day} $endMonth';
}
