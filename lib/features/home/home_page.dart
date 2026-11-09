import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/colors.dart';
import '../../data/app_storage.dart';
import '../../data/diary_controller.dart';
import '../calendar/calendar_header.dart';
import '../calendar/month_calendar.dart';
import '../day_editor/day_editor.dart';
import '../settings/settings_page.dart';
import '../stats/stats_page.dart';

/// Корневой экран: нижняя навигация и три вкладки.
/// Здесь живёт только состояние интерфейса (вкладка, выбранный день, режим
/// календаря); данные и их сохранение — в [DiaryController].
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
  late final DiaryController _diary = DiaryController(widget.storage);

  int _navIndex = 0;

  DateTime _today = DateUtils.dateOnly(DateTime.now());

  /// Выбранный день. Месяц и неделя календаря всегда определяются им.
  late DateTime _selectedDate = _today;

  /// true — календарь свёрнут до одной недели, false — показан весь месяц.
  late bool _isCalendarCollapsed = widget.storage.isCalendarCollapsed;

  // Производные от выбранного дня: отдельного состояния не требуют.
  DateTime get _visibleMonth => _monthOf(_selectedDate);
  DateTime get _weekStart => _mondayOf(_selectedDate);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _diary.dispose();
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
    });
  }

  // ----- Выбор дня и режим календаря -----

  void _selectDay(DateTime date) => setState(() => _selectedDate = date);

  void _goToToday() => _selectDay(_today);

  /// Переход из статистики: открываем день на вкладке «Календарь».
  void openDay(DateTime date) {
    setState(() {
      _selectedDate = date;
      _navIndex = 0;
    });
  }

  void _toggleCalendar() {
    setState(() => _isCalendarCollapsed = !_isCalendarCollapsed);
    // Сохраняем асинхронно, не блокируя интерфейс.
    unawaited(widget.storage.setCalendarCollapsed(_isCalendarCollapsed));
  }

  // ----- Листание календаря -----
  //
  // Стрелки двигают выбранный день, а месяц и неделя следуют за ним.
  // Дальше сегодняшнего дня не листаем.

  void _previous() => _step(-1);
  void _next() => _step(1);

  /// Свёрнутый режим сдвигает на неделю, развёрнутый на месяц.
  void _step(int direction) {
    setState(() {
      _selectedDate = _isCalendarCollapsed
          ? _shiftByDays(7 * direction)
          : _shiftByMonths(direction);
    });
  }

  DateTime _clampToToday(DateTime date) => date.isAfter(_today) ? _today : date;

  DateTime _shiftByDays(int days) {
    return _clampToToday(DateUtils.addDaysToDate(_selectedDate, days));
  }

  /// То же число в соседнем месяце; если там меньше дней, берём последнее.
  DateTime _shiftByMonths(int months) {
    final month = DateUtils.addMonthsToMonthDate(_visibleMonth, months);
    final lastDay = DateUtils.getDaysInMonth(month.year, month.month);
    final day = _selectedDate.day.clamp(1, lastDay);
    return _clampToToday(DateTime(month.year, month.month, day));
  }

  /// Кнопка «Сегодня» скрыта, когда уже показана текущая неделя или месяц.
  bool get _showTodayButton => _isCalendarCollapsed
      ? _weekStart != _mondayOf(_today)
      : _visibleMonth != _monthOf(_today);

  /// Можно ли листать вперёд (по неделям или месяцам).
  bool get _canGoNext => _isCalendarCollapsed
      ? !DateUtils.addDaysToDate(_weekStart, 7).isAfter(_today)
      : _visibleMonth.isBefore(_monthOf(_today));

  // ----- Экран -----

  Widget _buildCalendarTab() {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CalendarHeader(
            isCollapsed: _isCalendarCollapsed,
            showToday: _showTodayButton,
            onToday: _goToToday,
            onToggle: _toggleCalendar,
          ),
          const SizedBox(height: 6),
          MonthCalendar(
            month: _visibleMonth,
            weekStart: _weekStart,
            isCollapsed: _isCalendarCollapsed,
            selectedDate: _selectedDate,
            entries: _diary.entries,
            canGoNext: _canGoNext,
            onPrevious: _previous,
            onNext: _next,
            onDateSelected: _selectDay,
          ),
          const SizedBox(height: 6),
          DayEditor(
            // Новый ключ на каждую дату -> редактор пересоздаётся
            // и подхватывает сохранённую запись этого дня.
            key: ValueKey('$_selectedDate#${_diary.revision}'),
            selectedDate: _selectedDate,
            entry: _diary.entries[_selectedDate],
            availableTags: _diary.tags,
            onAddTag: _diary.addTag,
            onRenameTag: _diary.renameTag,
            onDeleteTag: _diary.deleteTag,
            onChanged: _diary.saveEntry,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final iconBrightness = widget.isDarkTheme
        ? Brightness.light
        : Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Иконки статус-бара и системной панели контрастны фону.
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: iconBrightness,
        systemNavigationBarColor: colors.card,
        systemNavigationBarIconBrightness: iconBrightness,
        systemNavigationBarContrastEnforced: false, // убирает серую подложку
      ),
      child: Scaffold(
        body: SafeArea(
          // ListenableBuilder перерисовывает вкладки при изменении данных.
          // IndexedStack хранит все вкладки живыми: при переключении
          // несохранённый ввод в редакторе не пропадает.
          child: ListenableBuilder(
            listenable: _diary,
            builder: (context, _) => IndexedStack(
              index: _navIndex,
              children: [
                _buildCalendarTab(),
                StatsPage(entries: _diary.entries, onDaySelected: openDay),
                SettingsPage(
                  isDarkTheme: widget.isDarkTheme,
                  onDarkThemeChanged: widget.onDarkThemeChanged,
                  onBackupText: _diary.backupText,
                  onRestore: _diary.restoreBackup,
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.cardBorder)),
          ),
          child: NavigationBar(
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
      ),
    );
  }
}

/// Первое число месяца, в котором лежит [date].
DateTime _monthOf(DateTime date) => DateTime(date.year, date.month);

/// Понедельник недели, в которой лежит [date].
DateTime _mondayOf(DateTime date) {
  final d = DateUtils.dateOnly(date);
  return DateUtils.addDaysToDate(d, -(d.weekday - 1));
}
