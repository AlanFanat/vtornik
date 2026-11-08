import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/section_title.dart';
import '../../core/colors.dart';
import '../../data/app_storage.dart';
import '../../data/day_entry.dart';
import '../../data/diary_controller.dart';
import '../calendar/month_calendar.dart';
import '../day_editor/day_editor.dart';
import '../day_editor/day_summary.dart';
import '../settings/settings_page.dart';
import '../stats/stats_page.dart';

/// Корневой экран: нижняя навигация и три вкладки.
/// Здесь живёт только состояние интерфейса (вкладка, выбранный день, месяц,
/// режим формы); данные и их сохранение — в [DiaryController].
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

  // ----- Режим дня: форма или карточка -----
  //
  // Режим хранится как состояние и меняется только событиями (выбор дня,
  // тап по карточке, «Готово», «Отмена»). Из данных его на лету не выводим:
  // иначе форма пустого дня превратилась бы в карточку, как только
  // автосохранение записало первую оценку.

  /// Раскрыта ли форма для выбранного дня. Приложение стартует на сегодня.
  bool _formOpen = true;

  /// Форма открыта тапом по карточке: правим готовую запись.
  /// Изменения копятся в [_draft] и применяются только по «Готово».
  bool _editMode = false;
  DayEntry? _draft;

  /// Есть несохранённые изменения: черновик отличается от записи в хранилище.
  /// Сравниваем именно с хранилищем: переименование и удаление тегов меняют
  /// его сразу и не должны выглядеть как правка пользователя.
  bool get _dirty {
    final draft = _draft;
    if (!_editMode || draft == null) return false;

    final stored = _diary.entries[_selectedDate];
    return stored == null || !_sameEntry(draft, stored);
  }

  bool _sameEntry(DayEntry a, DayEntry b) =>
      a.rating == b.rating && a.note == b.note && setEquals(a.tags, b.tags);

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
            _today // сегодня: форма
            ||
        (isYesterday && todayEmpty) // вчера: форма, только если сегодня пустой
        ||
        e == null ||
        e.isEmpty; // любой пустой день: форма

    _editMode = false;
    _draft = null;
  }

  /// Закрывает режим правки и показывает карточку (если в дне есть запись).
  void _endEdit() => setState(_dropEdit);

  /// То же без setState: для вызова изнутри другого setState.
  void _dropEdit() {
    _formOpen = false;
    _editMode = false;
    _draft = null;
  }

  /// Тап по карточке: открываем форму. Для прошлых дней это режим правки:
  /// черновик начинается с текущей записи и применяется по «Готово».
  /// Сегодняшний день всегда с автосохранением, без черновика.
  void _startEdit() {
    setState(() {
      _formOpen = true;
      _editMode = _selectedDate != _today;
      _draft = _editMode ? _diary.entries[_selectedDate] : null;
    });
  }

  /// Форма сообщает, что черновик изменился. Перерисовываем экран только
  /// когда меняется «грязность»: от неё зависит кнопка «Назад».
  void _onDraft(DayEntry entry) {
    final wasDirty = _dirty;
    _draft = entry;
    if (_dirty != wasDirty) setState(() {});
  }

  /// «Готово» в обычной форме: запись уже сохранена, просто сворачиваем.
  void _collapse() => setState(() => _formOpen = false);

  /// «Готово» в режиме правки: применяем черновик.
  void _finishEdit() => unawaited(_saveDraft());

  /// Записывает черновик. true — получилось (режим правки закрыт).
  Future<bool> _saveDraft() async {
    final draft = _draft;
    if (draft == null) return true;

    final saved = await _diary.saveEntry(_selectedDate, draft);
    if (!mounted) return false;

    if (!saved) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Не удалось сохранить')));
      return false;
    }

    _endEdit();
    return true;
  }

  // ----- Навигация -----
  //
  // Правка, не доведённая до «Готово», при уходе просто пропадает: записи
  // в хранилище она не меняла. Смена дня сбрасывает её сама внутри [_select].

  void _selectDay(DateTime date) => setState(() => _select(date));

  /// Переход из статистики. Черновик уже сброшен при уходе с вкладки.
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

  void _selectTab(int index) {
    if (index == _navIndex) return;
    setState(() {
      // Правка с изменениями пропадает; без изменений форма остаётся как была.
      if (_dirty) _dropEdit();
      _navIndex = index;
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
            onDateSelected: _selectDay,
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

    // Пустой день показываем формой в любом случае: карточке нечего рисовать.
    if (_formOpen || entry == null || entry.isEmpty) {
      return DayEditor(
        key: ValueKey('$date#${_diary.revision}'),
        selectedDate: date,
        // Если форму пересоздали (например, после переименования тега),
        // черновик не должен потеряться.
        entry: _editMode ? _draft : entry,
        availableTags: _diary.tags,
        onAddTag: _diary.addTag,
        onRenameTag: _diary.renameTag,
        onDeleteTag: _diary.deleteTag,
        onChanged: _diary.saveEntry,
        onDone: _editMode ? _finishEdit : _collapse,
        onCancel: _editMode ? _endEdit : null,
        onDraftChanged: _editMode ? _onDraft : null,
      );
    }

    return DaySummary(date: date, entry: entry, onEdit: _startEdit);
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
      // «Назад» при несохранённой правке закрывает правку (изменения
      // пропадают), а не выходит из приложения.
      child: PopScope(
        canPop: !_dirty,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _endEdit();
        },
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
              onDestinationSelected: _selectTab,
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
      ),
    );
  }
}