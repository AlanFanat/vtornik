import 'package:flutter/material.dart';

/// Первое число месяца, в котором лежит [date].
DateTime monthOf(DateTime date) => DateTime(date.year, date.month);

/// Понедельник недели, в которой лежит [date].
DateTime mondayOf(DateTime date) {
  final d = DateUtils.dateOnly(date);
  return DateUtils.addDaysToDate(d, -(d.weekday - 1));
}

/// Воскресенье той же недели.
DateTime sundayOf(DateTime date) =>
    DateUtils.addDaysToDate(mondayOf(date), 6);