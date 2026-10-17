import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import 'backup_data.dart';
import 'day_entry.dart';

/// Всё, что приложение помнит между запусками: тема, теги и записи дней.
///
/// Записи лежат одной JSON-строкой вида
/// {"2026-10-14": {"rating": 8, "tags": ["Работа"], "note": "..."}}.
/// Для личного дневника этого хватает на годы: на год выходит порядка 100 КБ.
class AppStorage {
  AppStorage._(this._prefs);

  final SharedPreferences _prefs;

  static const _darkThemeKey = 'is_dark_theme';
  static const _tagsKey = 'tags';
  static const _entriesKey = 'entries';
  static const _corruptedEntriesKey = 'entries_corrupted';

  static Future<AppStorage> open() async {
    return AppStorage._(await SharedPreferences.getInstance());
  }

  // ----- Тема -----

  bool get isDarkTheme => _prefs.getBool(_darkThemeKey) ?? false;

  Future<bool> setDarkTheme(bool value) => _prefs.setBool(_darkThemeKey, value);

  // ----- Теги -----

  List<String> get tags => _prefs.getStringList(_tagsKey) ?? [...defaultTags];

  Future<bool> setTags(List<String> tags) =>
      _prefs.setStringList(_tagsKey, tags);

  // ----- Записи дней -----

  Map<DateTime, DayEntry> loadEntries() {
    final raw = _prefs.getString(_entriesKey);
    if (raw == null) return {};

    try {
      return _entriesFromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Данные не читаются. Не теряем их молча: откладываем копию
      // в отдельный ключ и начинаем с чистого листа.
      unawaited(_prefs.setString(_corruptedEntriesKey, raw));
      return {};
    }
  }

  /// Возвращает false, если записать не удалось.
  Future<bool> setEntries(Map<DateTime, DayEntry> entries) async {
    try {
      return await _prefs.setString(
        _entriesKey,
        jsonEncode(_entriesToJson(entries)),
      );
    } catch (_) {
      return false;
    }
  }

  // ----- Резервная копия -----

  /// Текст резервной копии: все дни и теги одной строкой.
  static String exportBackup(
    Map<DateTime, DayEntry> entries,
    List<String> tags,
  ) {
    return jsonEncode({
      'version': 1,
      'tags': tags,
      'entries': _entriesToJson(entries),
    });
  }

  /// Разбирает текст копии. Бросает исключение, если текст не подходит.
  static BackupData parseBackup(String text) {
    final json = jsonDecode(text.trim()) as Map<String, dynamic>;
    final entries = _entriesFromJson(json['entries'] as Map<String, dynamic>);

    final tags = <String>[
      ...((json['tags'] as List<dynamic>?) ?? const []).cast<String>(),
    ];
    // Теги из записей, которых нет в списке, тоже добавляем.
    for (final entry in entries.values) {
      for (final tag in entry.tags) {
        if (!tags.contains(tag)) tags.add(tag);
      }
    }

    return BackupData(
      tags: tags.isEmpty ? [...defaultTags] : tags,
      entries: entries,
    );
  }

  // ----- JSON -----

  static Map<String, dynamic> _entriesToJson(Map<DateTime, DayEntry> entries) {
    return {
      for (final item in entries.entries)
        _dateKey(item.key): item.value.toJson(),
    };
  }

  static Map<DateTime, DayEntry> _entriesFromJson(Map<String, dynamic> json) {
    return {
      for (final item in json.entries)
        DateUtils.dateOnly(DateTime.parse(item.key)): DayEntry.fromJson(
          item.value as Map<String, dynamic>,
        ),
    };
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-$month-$day';
  }
}
