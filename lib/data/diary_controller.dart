import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

import '../core/constants.dart';
import 'app_storage.dart';
import 'backup_data.dart';
import 'day_entry.dart';

/// Вся логика данных дневника: записи дней, общий список тегов, резервная копия.
class DiaryController extends ChangeNotifier {
  DiaryController(AppStorage storage)
    : _storage = storage,
      _entries = storage.loadEntries(),
      _tags = storage.tags;

  final AppStorage _storage;

  /// Ключ — дата без времени (DateUtils.dateOnly).
  final Map<DateTime, DayEntry> _entries;

  /// Общий список тегов: один и тот же для всех дней.
  final List<String> _tags;

  int _revision = 0;
  bool _disposed = false;

  /// Только для чтения: менять записи можно лишь методами контроллера.
  Map<DateTime, DayEntry> get entries => UnmodifiableMapView(_entries);
  List<String> get tags => UnmodifiableListView(_tags);

  /// Теги, отсортированные по частоте использования за последние
  /// [tagSortWindowDays] дней (от частых к редким, при равенстве — по алфавиту).
  List<String> get tagsSorted {
    final counts = _countRecentTagUsage();
    final sorted = [..._tags]
      ..sort((a, b) => _compareTagsByUsage(a, b, counts));
    return UnmodifiableListView(sorted);
  }

  /// Растёт при восстановлении из копии, чтобы пересоздать редактор дня.
  int get revision => _revision;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // ----- Частота и сортировка тегов -----

  Map<String, int> _countRecentTagUsage() {
    final today = DateUtils.dateOnly(DateTime.now());
    final cutoff = DateUtils.addDaysToDate(today, -(tagSortWindowDays - 1));
    final counts = <String, int>{};

    for (final entry in _entries.entries) {
      final date = DateUtils.dateOnly(entry.key);
      if (date.isBefore(cutoff) || date.isAfter(today)) continue;
      for (final tag in entry.value.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    return counts;
  }

  int _compareTagsByUsage(String a, String b, Map<String, int> counts) {
    final countDiff = (counts[b] ?? 0).compareTo(counts[a] ?? 0);
    if (countDiff != 0) return countDiff;
    final lowerDiff = a.toLowerCase().compareTo(b.toLowerCase());
    return lowerDiff != 0 ? lowerDiff : a.compareTo(b);
  }

  // ----- Записи дней -----

  /// Вызывается редактором при каждом изменении дня (автосохранение).
  /// Пустая запись удаляет день. Возвращает false, если записать не удалось.
  Future<bool> saveEntry(DateTime date, DayEntry entry) {
    if (entry.isEmpty) {
      _entries.remove(date);
    } else {
      _entries[date] = entry;
    }

    Future.microtask(() {
      if (!_disposed) notifyListeners();
    });

    return _storage.setEntries(_entries);
  }

  // ----- Теги -----

  void addTag(String tag) {
    if (_tags.contains(tag)) return;
    _tags.add(tag);
    notifyListeners();
    unawaited(_storage.setTags(_tags));
  }

  /// Переименовывает тег в общем списке и во всех прошлых днях.
  void renameTag(String from, String to) {
    final index = _tags.indexOf(from);
    if (index >= 0) _tags[index] = to;
    _replaceTagInEntries(from, to);
    notifyListeners();
    _persistTagsAndEntries();
  }

  /// Удаляет тег из общего списка и из всех прошлых дней.
  void deleteTag(String tag) {
    _tags.remove(tag);
    _replaceTagInEntries(tag, null);
    notifyListeners();
    _persistTagsAndEntries();
  }

  /// Заменяет тег во всех прошлых днях; to == null — просто убирает его.
  void _replaceTagInEntries(String from, String? to) {
    for (final date in _entries.keys.toList()) {
      final entry = _entries[date]!;
      if (!entry.tags.contains(from)) continue;
      final updated = entry.withTags({
        for (final tag in entry.tags)
          if (tag != from) tag else ?to,
      });
      if (updated.isEmpty) {
        _entries.remove(date);
      } else {
        _entries[date] = updated;
      }
    }
  }

  void _persistTagsAndEntries() {
    unawaited(_storage.setTags(_tags));
    unawaited(_storage.setEntries(_entries));
  }

  // ----- Резервная копия -----

  String backupText() => AppStorage.exportBackup(_entries, _tags);

  /// Заменяет все данные содержимым копии.
  /// Возвращает текст ошибки или null, если всё получилось.
  String? restoreBackup(String text) {
    final BackupData data;
    try {
      data = AppStorage.parseBackup(text);
    } catch (_) {
      return 'Не удалось прочитать копию. Проверьте, что текст скопирован целиком.';
    }

    _entries
      ..clear()
      ..addAll(data.entries);
    _tags
      ..clear()
      ..addAll(data.tags);
    _revision++;
    notifyListeners();
    _persistTagsAndEntries();
    return null;
  }
}
