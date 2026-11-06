import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/section_title.dart';
import '../../core/colors.dart';
import '../../data/app_storage.dart';
import '../../data/diary_controller.dart';
import '../calendar/month_calendar.dart';
import '../day_editor/day_editor.dart';
import '../stats/day_card.dart';
import '../settings/settings_page.dart';
import '../stats/stats_page.dart';

/// Корневой экран: нижняя навигация и три вкладки.
/// Здесь живёт только состояние интерфейса (вкладка, выбранный день, месяц);
/// данные и их сохранение — в [DiaryController].
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
      _select(today);
      _visibleMonth = DateTime(today.year, today.month);
    });
  }

  bool _formOpen = false; // раскрыта ли форма для выбранного дня
  bool _canCollapse = false; // форма открыта карандашом -> показываем «Готово»

  /// Единственное место, где меняется выбранный день. Режим формы/карточки
  /// определяется здесь, а не при каждой перерисовке.
  void _select(DateTime date) {
    _selectedDate = date;

    final e = _diary.entries[date];
    final todayEntry = _diary.entries[_today];
    final todayEmpty = todayEntry == null || todayEntry.isEmpty;
    final isYesterday = date == DateUtils.addDaysToDate(_today, -1);

    _formOpen =
        date ==
            _today // сегодня: всегда форма
            ||
        (isYesterday && todayEmpty) // вчера: форма, только если сегодня пустой
        ||
        e == null ||
        e.isEmpty; // любой пустой день: форма
    _canCollapse = false;
  }

  void openDay(DateTime date) {
    setState(() {
      _select(date);
      _visibleMonth = DateTime(date.year, date.month);
      _navIndex = 0;
    });
  }

  void _goToToday() {
    final today = DateUtils.dateOnly(DateTime.now());
    setState(() {
      _today = today;
      _select(today);
      _visibleMonth = DateTime(today.year, today.month);
    });
  }

  // ----- Экран -----

  Widget _buildCalendarTab() {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTitle('Календарь'),
          const SizedBox(height: 6),
          MonthCalendar(
            month: _visibleMonth,
            selectedDate: _selectedDate,
            entries: _diary.entries,
            onMonthChanged: (month) {
              setState(() => _visibleMonth = month);
            },
            onToday: _goToToday,
            onDateSelected: (date) {
              setState(() => _select(date));
            },
          ),
          const SizedBox(height: 6),
          _buildDayPanel(),
        ],
      ),
    );
  }

  Widget _buildDayPanel() {
    final date = _selectedDate;
    //if (date.isAfter(_today)) return const FutureDayNote();

    final entry = _diary.entries[date];
    if (date == _today || _formOpen || entry == null) {
      return DayEditor(
        key: ValueKey('$date#${_diary.revision}'),
        selectedDate: date,
        entry: entry,
        availableTags: _diary.tags,
        onAddTag: _diary.addTag,
        onRenameTag: _diary.renameTag,
        onDeleteTag: _diary.deleteTag,
        onChanged: _diary.saveEntry,
        onDone: _canCollapse
            ? () => setState(() {
                _formOpen = false;
                _canCollapse = false;
              })
            : null,
      );
    }

    return DayCard(
      date: date,
      entry: entry,
      onTap: () => setState(() {
        _formOpen = true;
        _canCollapse = true;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Иконки статус-бара должны быть контрастны фону.
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: widget.isDarkTheme
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarColor: colors.card,
        systemNavigationBarIconBrightness: widget.isDarkTheme
            ? Brightness.light
            : Brightness.dark,
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
