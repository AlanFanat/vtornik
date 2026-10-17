import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/colors.dart';
import '../../data/app_storage.dart';
import '../../data/backup_data.dart';
import '../../data/day_entry.dart';
import '../calendar/month_calendar.dart';
import '../day_editor/day_editor.dart';
import '../settings/settings_page.dart';
import '../stats/stats_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.storage,
    required this.isDarkTheme,
    required this.onDarkThemeChanged,
  });

  final AppStorage storage;
  final bool isDarkTheme;
  final ValueChanged<bool> onDarkThemeChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _navIndex = 0;

  DateTime _today = DateUtils.dateOnly(DateTime.now());
  late DateTime _selectedDate = _today;
  late DateTime _visibleMonth = DateTime(_today.year, _today.month);

  /// Ключ — дата без времени (DateUtils.dateOnly).
  late final Map<DateTime, DayEntry> _entries = widget.storage.loadEntries();

  /// Общий список тегов: один и тот же для всех дней.
  late final List<String> _tags = widget.storage.tags;

  /// Растёт при восстановлении из копии, чтобы пересоздать редактор дня.
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Приложение могло пролежать в фоне всю ночь. При возвращении проверяем,
  /// не наступил ли новый день, и тогда открываем его, а не вчерашний.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    final today = DateUtils.dateOnly(DateTime.now());
    if (today == _today) return;

    setState(() {
      _today = today;
      _selectedDate = today;
      _visibleMonth = DateTime(today.year, today.month);
    });
  }

  // ----- Записи дней -----

  /// Вызывается редактором при каждом изменении дня (автосохранение).
  Future<bool> _saveEntry(DateTime date, DayEntry? entry) {
    if (entry == null || entry.isEmpty) {
      _entries.remove(date);
    } else {
      _entries[date] = entry;
    }

    // Не вызываем setState напрямую: вызов может прийти из dispose редактора
    // в момент смены дня, а в это время перерисовывать нельзя.
    Future.microtask(() {
      if (mounted) setState(() {});
    });

    return widget.storage.setEntries(_entries);
  }

  // ----- Теги -----

  void _addTag(String tag) {
    setState(() => _tags.add(tag));
    unawaited(widget.storage.setTags(_tags));
  }

  void _renameTag(String from, String to) {
    setState(() {
      final index = _tags.indexOf(from);
      if (index >= 0) _tags[index] = to;
      _replaceTagInEntries(from, to);
    });
    _persistTagsAndEntries();
  }

  void _deleteTag(String tag) {
    setState(() {
      _tags.remove(tag);
      _replaceTagInEntries(tag, null);
    });
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
    unawaited(widget.storage.setTags(_tags));
    unawaited(widget.storage.setEntries(_entries));
  }

  // ----- Резервная копия -----

  String _backupText() => AppStorage.exportBackup(_entries, _tags);

  /// Возвращает текст ошибки или null, если всё получилось.
  String? _restoreBackup(String text) {
    final BackupData data;
    try {
      data = AppStorage.parseBackup(text);
    } catch (_) {
      return 'Не удалось прочитать копию. Проверьте, что текст скопирован целиком.';
    }

    setState(() {
      _entries
        ..clear()
        ..addAll(data.entries);
      _tags
        ..clear()
        ..addAll(data.tags);
      _revision++;
    });
    _persistTagsAndEntries();
    return null;
  }

  // ----- Экран -----

  Widget _buildCalendarTab() {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonthCalendar(
            month: _visibleMonth,
            selectedDate: _selectedDate,
            entries: _entries,
            onMonthChanged: (month) {
              setState(() => _visibleMonth = month);
            },
            onDateSelected: (date) {
              setState(() => _selectedDate = date);
            },
          ),
          const SizedBox(height: 12),
          DayEditor(
            // Новый ключ на каждую дату -> редактор пересоздаётся
            // и подхватывает сохранённую запись этого дня.
            key: ValueKey('$_selectedDate#$_revision'),
            selectedDate: _selectedDate,
            entry: _entries[_selectedDate],
            availableTags: _tags,
            onAddTag: _addTag,
            onRenameTag: _renameTag,
            onDeleteTag: _deleteTag,
            onChanged: _saveEntry,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Иконки статус-бара должны быть контрастны фону.
      value: widget.isDarkTheme
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          // IndexedStack хранит все вкладки живыми: при переключении
          // несохранённый ввод в редакторе не пропадает.
          child: IndexedStack(
            index: _navIndex,
            children: [
              _buildCalendarTab(),
              StatsPage(entries: _entries),
              SettingsPage(
                isDarkTheme: widget.isDarkTheme,
                onDarkThemeChanged: widget.onDarkThemeChanged,
                onBackupText: _backupText,
                onRestore: _restoreBackup,
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          height: 70,
          backgroundColor: colors.card,
          indicatorColor: accentColor,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          selectedIndex: _navIndex,
          onDestinationSelected: (index) => setState(() => _navIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.calendar_month),
              label: 'Календарь',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart),
              label: 'Статистика',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings),
              label: 'Настройки',
            ),
          ],
        ),
      ),
    );
  }
}
