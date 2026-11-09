import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/section_title.dart';
import '../../core/colors.dart';
import '../../data/app_storage.dart';
import '../../data/diary_controller.dart';
import '../calendar/month_calendar.dart';
import '../day_editor/day_editor.dart';
import '../settings/settings_page.dart';
import '../stats/stats_page.dart';

/// Корневой экран: нижняя навигация и три вкладки.
/// Здесь живёт только состояние интерфейса (вкладка, выбранный день, месяц,
/// режим и неделя календаря); данные и их сохранение — в [DiaryController].
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
  late DateTime _selectedDate = _today;
  late DateTime _visibleMonth = DateTime(_today.year, _today.month);

  /// true — календарь свёрнут до одной недели, false — показан весь месяц.
  late bool _isCalendarCollapsed = widget.storage.isCalendarCollapsed;

  /// Понедельник отображаемой недели в свёрнутом режиме.
  late DateTime _weekStart = _mondayOf(_today);

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
      _visibleMonth = DateTime(today.year, today.month);
      _weekStart = _mondayOf(today);
    });
  }

  /// Переход из статистики: открываем день в календаре.
  void openDay(DateTime date) {
    setState(() {
      _selectedDate = date;
      _visibleMonth = DateTime(date.year, date.month);
      _weekStart = _mondayOf(date);
      _navIndex = 0;
    });
  }

  // ----- Логика календаря -----

  /// Возвращает понедельник недели, содержащей [date].
  DateTime _mondayOf(DateTime date) {
    final d = DateUtils.dateOnly(date);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  /// «Четверговый» месяц недели (правило ISO: к какому месяцу относится неделя).
  DateTime _thursdayMonthOf(DateTime weekStart) {
    final thursday = weekStart.add(const Duration(days: 3));
    return DateTime(thursday.year, thursday.month);
  }

  /// Выбирает начало недели при сворачивании:
  /// 0. Запомненная неделя, если она относится к показанному месяцу
  ///    (так при «свернул → полистал → развернул → свернул» возвращается
  ///    та же неделя).
  /// 1. Неделя выбранного дня, если он в показанном месяце.
  /// 2. Неделя сегодняшнего дня, если показан текущий месяц.
  /// 3. Неделя первого числа месяца.
  DateTime _weekStartForCollapse() {
    final m = _visibleMonth;
    final sel = DateUtils.dateOnly(_selectedDate);

    if (_thursdayMonthOf(_weekStart) == DateTime(m.year, m.month)) {
      return _weekStart;
    }

    if (sel.year == m.year && sel.month == m.month) {
      return _mondayOf(sel);
    }
    if (m.year == _today.year && m.month == _today.month) {
      return _mondayOf(_today);
    }
    return _mondayOf(DateTime(m.year, m.month, 1));
  }

  void _toggleCalendar() {
    setState(() {
      if (!_isCalendarCollapsed) {
        // Развёрнутый → свёрнутый.
        _weekStart = _weekStartForCollapse();
        _visibleMonth = _thursdayMonthOf(_weekStart);
        _isCalendarCollapsed = true;
      } else {
        // Свёрнутый → развёрнутый: месяц четверга текущей недели.
        _visibleMonth = _thursdayMonthOf(_weekStart);
        _isCalendarCollapsed = false;
      }
    });
    // Сохраняем новое состояние асинхронно, не блокируя UI.
    unawaited(widget.storage.setCollaps(_isCalendarCollapsed));
  }

  void _goToToday() {
    final today = DateUtils.dateOnly(DateTime.now());
    setState(() {
      _today = today;
      _selectedDate = today;
      _visibleMonth = DateTime(today.year, today.month);
      _weekStart = _mondayOf(today);
    });
  }

  void _changeWeek(DateTime newWeekStart) {
    setState(() {
      _weekStart = newWeekStart;
      _visibleMonth = _thursdayMonthOf(newWeekStart);
    });
  }

  void _previous() {
    if (_isCalendarCollapsed) {
      _changeWeek(_weekStart.subtract(const Duration(days: 7)));
    } else {
      setState(() {
        _visibleMonth = DateUtils.addMonthsToMonthDate(_visibleMonth, -1);
      });
    }
  }

  void _next() {
    if (_isCalendarCollapsed) {
      _changeWeek(_weekStart.add(const Duration(days: 7)));
    } else {
      setState(() {
        _visibleMonth = DateUtils.addMonthsToMonthDate(_visibleMonth, 1);
      });
    }
  }

  /// Показывать ли кнопку «Сегодня».
  bool get _showTodayBtn {
    if (_isCalendarCollapsed) {
      // Скрыта только когда на текущей неделе.
      return _weekStart != _mondayOf(_today);
    }
    // Скрыта только когда показан текущий месяц.
    return _visibleMonth.year != _today.year ||
        _visibleMonth.month != _today.month;
  }

  /// Можно ли листать вперёд (по месяцам или неделям).
  bool get _canGoNext {
    if (_isCalendarCollapsed) {
      return !_weekStart.add(const Duration(days: 7)).isAfter(_today);
    }
    return _visibleMonth.isBefore(DateTime(_today.year, _today.month));
  }

  // ----- Экран -----

  Widget _buildCalendarHeader() {
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
                  // Кнопка «Сегодня» — место занято всегда, но может быть невидима.
                  AnimatedOpacity(
                    opacity: _showTodayBtn ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: IgnorePointer(
                      ignoring: !_showTodayBtn,
                      child: IconButton(
                        constraints: buttonConstraints,
                        padding: EdgeInsets.zero,
                        tooltip: 'Сегодня',
                        icon: const Icon(Icons.today),
                        onPressed: _goToToday,
                      ),
                    ),
                  ),

                  // Кнопка «Свернуть / Развернуть».
                  AnimatedRotation(
                    turns: _isCalendarCollapsed ? 0.5 : 0.0, // 180° при свёрнутом
                    duration: const Duration(milliseconds: 250),
                    child: IconButton(
                      constraints: buttonConstraints,
                      padding: EdgeInsets.zero,
                      tooltip: _isCalendarCollapsed
                          ? 'Показать месяц'
                          : 'Свернуть до недели',
                      icon: const Icon(Icons.expand_less),
                      onPressed: _toggleCalendar,
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

  Widget _buildCalendarTab() {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCalendarHeader(),
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
            onDateSelected: (date) {
              setState(() {
                _selectedDate = date;
                _weekStart = _mondayOf(date);
              });
            },
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Иконки статус-бара должны быть контрастны фону.
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            widget.isDarkTheme ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: colors.card,
        systemNavigationBarIconBrightness:
            widget.isDarkTheme ? Brightness.light : Brightness.dark,
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