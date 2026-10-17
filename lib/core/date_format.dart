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
