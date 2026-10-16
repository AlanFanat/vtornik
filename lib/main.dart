import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Акцент и цвета текста поверх ярких заливок одинаковы в обеих темах.
const Color accentColor = Color(0xFFE5B84B); // акцент (жёлтый)
const Color onAccentColor = Color(0xFF171717); // текст на акценте
const Color onRatingColor = Color(0xFF18181C); // текст на цвете оценки

/// Цвета, которые зависят от темы. Достаём их через `context.colors`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.card,
    required this.cardBorder,
    required this.surface,
    required this.inputFill,
    required this.text,
    required this.disabledText,
  });

  final Color background; // фон экрана
  final Color card; // фон карточки
  final Color cardBorder; // рамки
  final Color surface; // ячейки, чипы, плитки оценок
  final Color inputFill; // фон поля заметки и нижней панели
  final Color text; // основной текст
  final Color disabledText; // текст будущих дней

  static const light = AppColors(
    background: Color(0xFFF4F4F7),
    card: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFE3E3E8),
    surface: Color(0xFFE9E9EE),
    inputFill: Color(0xFFF0F0F4),
    text: Color(0xFF18181C),
    disabledText: Color(0x4D18181C),
  );

  static const dark = AppColors(
    background: Color(0xFF0C0C0D),
    card: Color(0xFF18181C),
    cardBorder: Color(0xFF29292F),
    surface: Color(0xFF29292F),
    inputFill: Color(0xFF222227),
    text: Color(0xFFECECEF),
    disabledText: Color(0x4DECECEF),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? card,
    Color? cardBorder,
    Color? surface,
    Color? inputFill,
    Color? text,
    Color? disabledText,
  }) {
    return AppColors(
      background: background ?? this.background,
      card: card ?? this.card,
      cardBorder: cardBorder ?? this.cardBorder,
      surface: surface ?? this.surface,
      inputFill: inputFill ?? this.inputFill,
      text: text ?? this.text,
      disabledText: disabledText ?? this.disabledText,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      text: Color.lerp(text, other.text, t)!,
      disabledText: Color.lerp(disabledText, other.disabledText, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

/// У каждой оценки 1..10 свой цвет: красный -> оранжевый -> жёлтый -> зелёный.
/// Все цвета достаточно светлые, чтобы на них читался тёмный текст.
const List<Color> _ratingColors = [
  Color(0xFFE0484A), // 1
  Color(0xFFE8603E), // 2
  Color(0xFFEE7B3A), // 3
  Color(0xFFF29A3C), // 4
  Color(0xFFF5B93B), // 5
  Color(0xFFEAD23C), // 6
  Color(0xFFC4D048), // 7
  Color(0xFF9BC653), // 8
  Color(0xFF6DBB5E), // 9
  Color(0xFF3FA55B), // 10
];

Color ratingColor(int rating) => _ratingColors[rating - 1];

// ---------------------------------------------------------------------------
// Темы
// ---------------------------------------------------------------------------
ThemeData _buildTheme(AppColors colors, Brightness brightness) {
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: colors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accentColor,
      brightness: brightness,
    ),
    extensions: [colors],
    navigationBarTheme: NavigationBarThemeData(
      // Иконка выбранной вкладки лежит на жёлтом индикаторе — делаем её тёмной.
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? onAccentColor : colors.text);
      }),
    ),
  );
}

final ThemeData _lightTheme = _buildTheme(AppColors.light, Brightness.light);
final ThemeData _darkTheme = _buildTheme(AppColors.dark, Brightness.dark);

// ---------------------------------------------------------------------------
// Тексты
// ---------------------------------------------------------------------------
const List<String> _weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

const List<String> _months = [
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

/// Теги, которые есть при первом запуске. Остальные пользователь добавляет сам.
const List<String> _defaultTags = ['Работа', 'Френды', 'Школа'];

const int _maxTagLength = 20;

/// Через сколько после последнего символа заметка сохраняется сама.
const Duration _noteSaveDelay = Duration(milliseconds: 400);

Future<void> main() async {
  // Нужно, чтобы прочитать сохранённые данные до первого кадра:
  // тогда тема не мигает, а дни сразу на месте.
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await AppStorage.open();

  runApp(MainApp(storage: storage));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key, required this.storage});

  final AppStorage storage;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late bool _isDarkTheme = widget.storage.isDarkTheme;

  void _setDarkTheme(bool value) {
    setState(() => _isDarkTheme = value);
    unawaited(widget.storage.setDarkTheme(value));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: _isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      home: HomePage(
        storage: widget.storage,
        isDarkTheme: _isDarkTheme,
        onDarkThemeChanged: _setDarkTheme,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Модель
// ---------------------------------------------------------------------------

/// Запись об одном дне. Неизменяемая: чтобы изменить день, создаём новую.
/// Оценки может не быть: запись с одними тегами или заметкой тоже сохраняется.
@immutable
class DayEntry {
  const DayEntry({this.rating, this.tags = const {}, this.note = ''});

  final int? rating;
  final Set<String> tags;
  final String note;

  /// В пустой записи нет ничего, её не храним.
  bool get isEmpty => rating == null && tags.isEmpty && note.isEmpty;

  DayEntry withTags(Set<String> tags) {
    return DayEntry(rating: rating, tags: tags, note: note);
  }

  Map<String, dynamic> toJson() => {
    if (rating != null) 'rating': rating,
    'tags': tags.toList()..sort(),
    'note': note,
  };

  factory DayEntry.fromJson(Map<String, dynamic> json) {
    final rating = json['rating'] as int?;

    return DayEntry(
      // Защита от испорченных данных: оценка всегда в пределах 1..10.
      rating: rating == null
          ? null
          : (rating < 1 ? 1 : (rating > 10 ? 10 : rating)),
      tags: {...((json['tags'] as List<dynamic>?) ?? const []).cast<String>()},
      note: (json['note'] as String?) ?? '',
    );
  }
}

/// Содержимое резервной копии.
class BackupData {
  const BackupData({required this.tags, required this.entries});

  final List<String> tags;
  final Map<DateTime, DayEntry> entries;
}

// ---------------------------------------------------------------------------
// Хранилище (SharedPreferences)
// ---------------------------------------------------------------------------

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

  bool get isDarkTheme => _prefs.getBool(_darkThemeKey) ?? false;

  Future<bool> setDarkTheme(bool value) => _prefs.setBool(_darkThemeKey, value);

  List<String> get tags => _prefs.getStringList(_tagsKey) ?? [..._defaultTags];

  Future<bool> setTags(List<String> tags) =>
      _prefs.setStringList(_tagsKey, tags);

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
      tags: tags.isEmpty ? [..._defaultTags] : tags,
      entries: entries,
    );
  }

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

// ---------------------------------------------------------------------------
// Главная страница
// ---------------------------------------------------------------------------
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
              _StatsPage(entries: _entries),
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
          backgroundColor: colors.inputFill,
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

// ---------------------------------------------------------------------------
// Статистика (пока заглушка)
// ---------------------------------------------------------------------------
class _StatsPage extends StatelessWidget {
  const _StatsPage({required this.entries});

  final Map<DateTime, DayEntry> entries;

  @override
  Widget build(BuildContext context) {
    final sortEntries = entries.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    if (sortEntries.isEmpty) {
      return const Center(
        child: Text(
          'Статистика появится позже',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: sortEntries.length,
      itemBuilder: (context, index) {
        return _DayCard(
          date: sortEntries[index].key,
          entry: sortEntries[index].value,
        );
      },
      separatorBuilder: (context, index) {
        return SizedBox(height: 4);
      },
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.date, required this.entry});

  final DateTime date;
  final DayEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rating = entry.rating;
    final note = entry.note;
    final tags = entry.tags;

    //Фон рейтинга дня.
    final Color rateBackground = rating != null
        ? ratingColor(rating)
        : colors.surface;

    final Color foreground = rating != null ? onRatingColor : colors.text;

    return Material(
      color: colors.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colors.cardBorder),
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: rateBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  rating?.toString() ?? '-',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: foreground,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(formatDate(date), style: TextStyle(fontSize: 18)),
                  Text(
                    note.isEmpty ? '-' : note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(tags.isEmpty ? '-' : tags.join(', ')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// class _RateCell extends StatelessWidget {
//   const _RateCell({required this.rating});

//   final int? rating;

//   @override
//   Widget build(BuildContext context) {
//     final colors = context.colors;
//     final rating = this.rating;

//     // Оценённый день — цвет оценки, будущий — пустая рамка, остальные — серый.
//     final Color background = rating != null
//         ? ratingColor(rating)
//         : colors.surface;

//     final shape = RoundedRectangleBorder(
//       borderRadius: BorderRadius.circular(8),
//     );

//     // На цветной заливке оценки текст всегда тёмный, в любой теме.
//     final Color foreground = rating != null ? onRatingColor : colors.text;

//     final dayStyle = TextStyle(
//       fontSize: 14,
//       color: foreground,
//       decorationColor: foreground,
//     );

//     return Material(
//       color: background,
//       shape: shape,
//       child: InkWell(
//         customBorder: shape,
//         child: Center(child: Text('${date.day}', style: dayStyle)),
//       ),
//     );
//   }
// }

// ---------------------------------------------------------------------------
// Настройки
// ---------------------------------------------------------------------------
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.isDarkTheme,
    required this.onDarkThemeChanged,
    required this.onBackupText,
    required this.onRestore,
  });

  final bool isDarkTheme;
  final ValueChanged<bool> onDarkThemeChanged;

  /// Возвращает текст резервной копии.
  final String Function() onBackupText;

  /// Восстанавливает данные из текста. Возвращает ошибку или null.
  final String? Function(String text) onRestore;

  void _showMessage(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _copyBackup(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: onBackupText()));
    if (!context.mounted) return;

    _showMessage(
      context,
      'Скопировано. Вставьте в заметки или в «Избранное» мессенджера.',
    );
  }

  Future<void> _restoreBackup(BuildContext context) async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => const _RestoreDialog(),
    );
    if (text == null || !context.mounted) return;

    _showMessage(context, onRestore(text) ?? 'Данные восстановлены');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        Text(
          'Настройки',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
        const SizedBox(height: 12),

        _SettingsCard(
          child: SwitchListTile(
            secondary: Icon(Icons.dark_mode_outlined, color: colors.text),
            title: Text('Тёмная тема', style: TextStyle(color: colors.text)),
            value: isDarkTheme,
            onChanged: onDarkThemeChanged,
            activeTrackColor: accentColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),

        const SizedBox(height: 16),
        const _SectionTitle('Резервная копия'),
        const SizedBox(height: 6),

        _SettingsCard(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.copy_outlined, color: colors.text),
                title: Text(
                  'Скопировать данные',
                  style: TextStyle(color: colors.text),
                ),
                subtitle: const Text('Все дни и теги — в буфер обмена'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                onTap: () => _copyBackup(context),
              ),
              Divider(height: 1, color: colors.cardBorder),
              ListTile(
                leading: Icon(Icons.restore_outlined, color: colors.text),
                title: Text(
                  'Восстановить из копии',
                  style: TextStyle(color: colors.text),
                ),
                subtitle: const Text('Вставьте ранее скопированный текст'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                onTap: () => _restoreBackup(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Карточка настроек. Material (а не Container), чтобы была видна рябь нажатия.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colors.cardBorder),
      ),
      child: child,
    );
  }
}

/// Диалог восстановления: вставляем текст копии и подтверждаем замену.
class _RestoreDialog extends StatefulWidget {
  const _RestoreDialog();

  @override
  State<_RestoreDialog> createState() => _RestoreDialogState();
}

class _RestoreDialogState extends State<_RestoreDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text case final text?) _controller.text = text;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Восстановить из копии'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Текущие дни и теги будут заменены данными из копии.'),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Вставьте скопированный текст',
                border: OutlineInputBorder(),
              ),
            ),
            TextButton.icon(
              onPressed: _paste,
              icon: const Icon(Icons.content_paste, size: 18),
              label: const Text('Вставить из буфера'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isNotEmpty) Navigator.pop(context, text);
          },
          child: const Text('Восстановить'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Календарь
// ---------------------------------------------------------------------------
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.selectedDate,
    required this.entries,
    required this.onMonthChanged,
    required this.onDateSelected,
  });

  /// Любая дата нужного месяца (используем первое число).
  final DateTime month;
  final DateTime selectedDate;
  final Map<DateTime, DayEntry> entries;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final today = DateUtils.dateOnly(DateTime.now());

    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    // Dart: Monday = 1 ... Sunday = 7, поэтому неделя начинается с Пн.
    final startOffset = DateTime(month.year, month.month).weekday - 1;

    // В будущие месяцы листать нельзя.
    final canGoNext = month.isBefore(DateTime(today.year, today.month));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок со стрелками.
        Row(
          children: [
            IconButton(
              tooltip: 'Предыдущий месяц',
              icon: const Icon(Icons.chevron_left),
              onPressed: () =>
                  onMonthChanged(DateUtils.addMonthsToMonthDate(month, -1)),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${_months[month.month - 1]} ${month.year}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Следующий месяц',
              icon: const Icon(Icons.chevron_right),
              onPressed: canGoNext
                  ? () =>
                        onMonthChanged(DateUtils.addMonthsToMonthDate(month, 1))
                  : null,
            ),
          ],
        ),

        const SizedBox(height: 4),

        // Названия дней недели.
        Row(
          children: [
            for (final day in _weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 6),

        // Сетка дней.
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: startOffset + daysInMonth,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1.4,
          ),
          itemBuilder: (context, index) {
            // Пустые ячейки перед первым числом.
            if (index < startOffset) return const SizedBox.shrink();

            final date = DateTime(
              month.year,
              month.month,
              index - startOffset + 1,
            );

            return _DayCell(
              date: date,
              rating: entries[date]?.rating,
              isSelected: date == selectedDate,
              isToday: date == today,
              isFuture: date.isAfter(today),
              onTap: () => onDateSelected(date),
            );
          },
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.rating,
    required this.isSelected,
    required this.isToday,
    required this.isFuture,
    required this.onTap,
  });

  final DateTime date;
  final int? rating;
  final bool isSelected;
  final bool isToday;
  final bool isFuture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rating = this.rating;

    // Оценённый день — цвет оценки, будущий — пустая рамка, остальные — серый.
    final Color background = isFuture
        ? Colors.transparent
        : rating != null
        ? ratingColor(rating)
        : colors.surface;

    // Выбранный день обводим цветом текста: жёлтый акцент терялся бы на жёлтых оценках.
    final BorderSide border = isSelected
        ? BorderSide(color: colors.text, width: 2)
        : isFuture
        ? BorderSide(color: colors.cardBorder)
        : BorderSide.none;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: border,
    );

    // На цветной заливке оценки текст всегда тёмный, в любой теме.
    final Color foreground = isFuture
        ? colors.disabledText
        : rating != null
        ? onRatingColor
        : colors.text;

    final dayStyle = TextStyle(
      fontSize: 14,
      color: foreground,
      fontWeight: isToday ? FontWeight.w800 : FontWeight.normal,
      // Сегодняшний день подчёркнут: не конфликтует с рамкой выбора.
      decoration: isToday ? TextDecoration.underline : null,
      decorationColor: foreground,
    );

    return Semantics(
      button: !isFuture,
      enabled: !isFuture,
      selected: isSelected,
      excludeSemantics: true,
      label: isFuture
          ? '${date.day}, день ещё не наступил'
          : rating != null
          ? '${date.day}, оценка $rating'
          : '${date.day}, без оценки',
      child: Material(
        color: background,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          // null у будущих дней: ни нажатия, ни ряби.
          onTap: isFuture ? null : onTap,
          child: Center(child: Text('${date.day}', style: dayStyle)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Редактор дня
// ---------------------------------------------------------------------------
enum _SaveStatus { idle, saved, failed }

enum _TagAction { rename, delete }

class DayEditor extends StatefulWidget {
  const DayEditor({
    super.key,
    required this.selectedDate,
    required this.entry,
    required this.availableTags,
    required this.onAddTag,
    required this.onRenameTag,
    required this.onDeleteTag,
    required this.onChanged,
  });

  final DateTime selectedDate;
  final DayEntry? entry;
  final List<String> availableTags;
  final ValueChanged<String> onAddTag;
  final void Function(String from, String to) onRenameTag;
  final ValueChanged<String> onDeleteTag;

  /// Вызывается при каждом изменении дня. Возвращает true,
  /// если запись удалось сохранить на устройство.
  final Future<bool> Function(DateTime date, DayEntry entry) onChanged;

  @override
  State<DayEditor> createState() => _DayEditorState();
}

class _DayEditorState extends State<DayEditor> with WidgetsBindingObserver {
  late int? _rating = widget.entry?.rating;
  late final Set<String> _tags = {...?widget.entry?.tags};
  late final TextEditingController _noteController = TextEditingController(
    text: widget.entry?.note ?? '',
  );

  Timer? _noteTimer;
  _SaveStatus _status = _SaveStatus.idle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Заметку не успели сохранить (сменили день за доли секунды) — сохраняем сейчас.
    if (_noteTimer?.isActive ?? false) {
      _noteTimer!.cancel();
      unawaited(widget.onChanged(widget.selectedDate, _currentEntry));
    }

    _noteController.dispose();
    super.dispose();
  }

  /// Если приложение уходит в фон, не ждём таймер.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_noteTimer?.isActive ?? false) unawaited(_saveNow());
    }
  }

  DayEntry get _currentEntry => DayEntry(
    rating: _rating,
    tags: {..._tags},
    note: _noteController.text.trim(),
  );

  String get _title {
    final date = widget.selectedDate;
    final now = DateTime.now();

    var label = '${date.day} ${_monthsGenitive[date.month - 1]}';
    if (date.year != now.year) label = '$label ${date.year}';

    return DateUtils.isSameDay(date, now) ? 'Сегодня, $label' : label;
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  // ----- Автосохранение -----

  Future<void> _saveNow() async {
    _noteTimer?.cancel();

    final saved = await widget.onChanged(widget.selectedDate, _currentEntry);
    if (!mounted) return;

    setState(() => _status = saved ? _SaveStatus.saved : _SaveStatus.failed);
  }

  /// Заметку сохраняем не на каждую букву, а когда пользователь на миг замолчал.
  void _scheduleSave() {
    _noteTimer?.cancel();
    _noteTimer = Timer(_noteSaveDelay, _saveNow);
  }

  // ----- Оценка и теги -----

  /// Повторное нажатие на выбранную оценку снимает её.
  void _selectRating(int rating) {
    setState(() => _rating = _rating == rating ? null : rating);
    unawaited(_saveNow());
  }

  void _toggleTag(String tag, bool selected) {
    setState(() {
      if (selected) {
        _tags.add(tag);
      } else {
        _tags.remove(tag);
      }
    });
    unawaited(_saveNow());
  }

  Future<void> _addTag() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) =>
          const _TagNameDialog(title: 'Новый тег', confirmLabel: 'Добавить'),
    );
    if (name == null || !mounted) return;

    // Такой тег уже есть (без учёта регистра) — просто выбираем его.
    final existing = widget.availableTags
        .where((tag) => tag.toLowerCase() == name.toLowerCase())
        .firstOrNull;
    if (existing == null) widget.onAddTag(name);

    setState(() => _tags.add(existing ?? name));
    unawaited(_saveNow());
  }

  Future<void> _manageTag(String tag) async {
    final action = await showModalBottomSheet<_TagAction>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                tag,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Переименовать'),
              onTap: () => Navigator.pop(context, _TagAction.rename),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Удалить'),
              onTap: () => Navigator.pop(context, _TagAction.delete),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;

    switch (action) {
      case _TagAction.rename:
        await _renameTag(tag);
      case _TagAction.delete:
        await _deleteTag(tag);
    }
  }

  Future<void> _renameTag(String tag) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _TagNameDialog(
        title: 'Переименовать тег',
        confirmLabel: 'Сохранить',
        initial: tag,
      ),
    );
    if (name == null || !mounted || name == tag) return;

    final clash = widget.availableTags.any(
      (other) => other != tag && other.toLowerCase() == name.toLowerCase(),
    );
    if (clash) {
      _showMessage('Тег «$name» уже есть');
      return;
    }

    // Тег меняется и в общем списке, и во всех прошлых днях.
    widget.onRenameTag(tag, name);
    setState(() {
      if (_tags.remove(tag)) _tags.add(name);
    });
    unawaited(_saveNow());
  }

  Future<void> _deleteTag(String tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить тег «$tag»?'),
        content: const Text('Он пропадёт и из всех прошлых дней.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    widget.onDeleteTag(tag);
    setState(() => _tags.remove(tag));
    unawaited(_saveNow());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                ),
              ),
              _SaveIndicator(status: _status),
            ],
          ),

          const SizedBox(height: 8),

          // Оценка: ровно одна строка из 10 плиток при любой ширине экрана.
          Row(
            children: [
              for (var rating = 1; rating <= 10; rating++) ...[
                if (rating > 1) const SizedBox(width: 4),
                Expanded(
                  child: _RatingTile(
                    rating: rating,
                    isSelected: _rating == rating,
                    onTap: () => _selectRating(rating),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              const _SectionTitle('Теги дня'),
              const SizedBox(width: 8),
              if (widget.availableTags.isNotEmpty)
                const Expanded(
                  child: Text(
                    'удерживайте тег, чтобы изменить',
                    textAlign: TextAlign.end,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final tag in widget.availableTags)
                GestureDetector(
                  onLongPress: () => _manageTag(tag),
                  child: FilterChip(
                    label: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 12,
                        // На жёлтом акценте текст тёмный в любой теме.
                        color: _tags.contains(tag)
                            ? onAccentColor
                            : colors.text,
                      ),
                    ),
                    selected: _tags.contains(tag),
                    onSelected: (selected) => _toggleTag(tag, selected),
                    selectedColor: accentColor,
                    backgroundColor: colors.surface,
                    showCheckmark: false,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    visualDensity: const VisualDensity(
                      horizontal: -3,
                      vertical: -3,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),

              // Кнопка добавления нового тега.
              ActionChip(
                avatar: Icon(Icons.add, size: 16, color: colors.text),
                label: Text(
                  'Тег',
                  style: TextStyle(fontSize: 12, color: colors.text),
                ),
                onPressed: _addTag,
                backgroundColor: Colors.transparent,
                side: BorderSide(color: colors.cardBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                visualDensity: const VisualDensity(
                  horizontal: -3,
                  vertical: -3,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                labelPadding: const EdgeInsets.only(right: 4),
              ),
            ],
          ),

          const SizedBox(height: 10),

          const _SectionTitle('Заметка'),
          const SizedBox(height: 4),
          TextField(
            controller: _noteController,
            onChanged: (_) => _scheduleSave(),
            maxLines: 4,
            style: TextStyle(color: colors.text),
            decoration: InputDecoration(
              hintText: 'Что запомнилось в этот день?',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              filled: true,
              fillColor: colors.inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String formatDate(DateTime date) {
  final now = DateTime.now();

  var label = '${date.day} ${_monthsGenitive[date.month - 1]}';
  if (date.year != now.year) label = '$label ${date.year}';

  return DateUtils.isSameDay(date, now) ? 'Сегодня, $label' : label;
}

/// Маленький индикатор в шапке редактора: день сохранился или нет.
class _SaveIndicator extends StatelessWidget {
  const _SaveIndicator({required this.status});

  final _SaveStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case _SaveStatus.idle:
        return const SizedBox.shrink();
      case _SaveStatus.saved:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, size: 14, color: Colors.grey),
            SizedBox(width: 4),
            Text(
              'Сохранено',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        );
      case _SaveStatus.failed:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 14, color: Color(0xFFE0484A)),
            SizedBox(width: 4),
            Text(
              'Не сохранилось',
              style: TextStyle(color: Color(0xFFE0484A), fontSize: 12),
            ),
          ],
        );
    }
  }
}

/// Диалог с названием тега: и для нового, и для переименования.
/// Возвращает название или null.
class _TagNameDialog extends StatefulWidget {
  const _TagNameDialog({
    required this.title,
    required this.confirmLabel,
    this.initial = '',
  });

  final String title;
  final String confirmLabel;
  final String initial;

  @override
  State<_TagNameDialog> createState() => _TagNameDialogState();
}

class _TagNameDialogState extends State<_TagNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  )..selection = TextSelection.collapsed(offset: widget.initial.length);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    // Пустое название не принимаем.
    if (name.isNotEmpty) Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: _maxTagLength,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(hintText: 'Например, Спорт'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        TextButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: context.colors.text,
      ),
    );
  }
}

class _RatingTile extends StatelessWidget {
  const _RatingTile({
    required this.rating,
    required this.isSelected,
    required this.onTap,
  });

  final int rating;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    return Semantics(
      button: true,
      selected: isSelected,
      excludeSemantics: true,
      label: 'Оценка $rating из 10',
      child: Material(
        // Без анимации: цвет оценки появляется сразу, а не проявляется из серого.
        animationDuration: Duration.zero,
        color: isSelected ? ratingColor(rating) : colors.surface,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          // Без ряби и затемнения при нажатии: именно они давали «тусклый» цвет.
          splashFactory: NoSplash.splashFactory,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: SizedBox(
            height: 40,
            child: Center(
              child: Text(
                '$rating',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? onRatingColor : colors.text,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
