import 'package:flutter/material.dart';
import 'package:dayly/main.dart';

void main() => runApp(const DayCardPreviewPage());

// ───────────────────────── МОДЕЛЬ ─────────────────────────

class DayEntry {
  final DateTime date;
  final int rating; // 1..10
  final String note;
  final List<String> tags;

  const DayEntry({
    required this.date,
    required this.rating,
    required this.note,
    required this.tags,
  });
}

final List<DayEntry> demoDays = [
  DayEntry(
    date: DateTime(2026, 10, 16),
    rating: 10,
    note: 'Лучший день за месяц: закончил фичу, вечером погулял с друзьями.',
    tags: ['работа', 'друзья', 'прогулка'],
  ),
  DayEntry(
    date: DateTime(2026, 10, 15),
    rating: 8,
    note: 'Хорошая тренировка и вкусный ужин.',
    tags: ['спорт', 'еда'],
  ),
  DayEntry(
    date: DateTime(2026, 10, 14),
    rating: 6,
    note: 'Обычный день, ничего особенного.',
    tags: ['рутина'],
  ),
  DayEntry(
    date: DateTime(2026, 10, 13),
    rating: 5,
    note: 'Ни то ни сё. Много созвонов, мало сделал.',
    tags: ['работа', 'усталость'],
  ),
  DayEntry(
    date: DateTime(2026, 10, 12),
    rating: 3,
    note: 'Плохо спал, голова болела весь день, настроения нет совсем.',
    tags: ['здоровье', 'сон'],
  ),
  DayEntry(
    date: DateTime(2026, 10, 11),
    rating: 1,
    note: 'Ужасный день.',
    tags: ['стресс'],
  ),
];

// ───────────────────────── ЦВЕТ ПО ОЦЕНКЕ ─────────────────────────
// 1 — красный, 5 — жёлтый, 10 — зелёный (плавный переход)

const _red = Color(0xFFE5484D);
const _yellow = Color(0xFFF5B800);
const _green = Color(0xFF2FA866);

Color ratingColor(int rating) {
  final r = rating.clamp(1, 10);
  if (r <= 5) {
    return Color.lerp(_red, _yellow, (r - 1) / 4)!;
  }
  return Color.lerp(_yellow, _green, (r - 5) / 5)!;
}

/// Цвет текста поверх цветной заливки (на жёлтом — тёмный)
Color onColor(Color bg) =>
    ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
    ? Colors.white
    : const Color(0xFF1B1B1B);

// ───────────────────────── ФОРМАТ ДАТЫ ─────────────────────────

const _weekdays = [
  'Понедельник',
  'Вторник',
  'Среда',
  'Четверг',
  'Пятница',
  'Суббота',
  'Воскресенье',
];
const _weekdaysShort = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
const _months = [
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
const _monthsShort = [
  'янв',
  'фев',
  'мар',
  'апр',
  'май',
  'июн',
  'июл',
  'авг',
  'сен',
  'окт',
  'ноя',
  'дек',
];

String fullDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';
String weekday(DateTime d) => _weekdays[d.weekday - 1];
String weekdayShort(DateTime d) => _weekdaysShort[d.weekday - 1];
String monthShort(DateTime d) => _monthsShort[d.month - 1];

// ───────────────────────── ПРИЛОЖЕНИЕ ─────────────────────────

class DayCardPreviewPage extends StatelessWidget {
  const DayCardPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const PreviewPage(),
    );
  }
}

class _Variant {
  final String name;
  final Widget Function(DayEntry) builder;
  const _Variant(this.name, this.builder);
}

class PreviewPage extends StatefulWidget {
  const PreviewPage({super.key});

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  int selected = 0;

  late final List<_Variant> variants = [
    _Variant('1. Полоска', (e) => DayCardStripe(entry: e)),
    _Variant('2. Тонированная', (e) => DayCardTinted(entry: e)),
    _Variant('3. Календарная', (e) => DayCardCalendar(entry: e)),
    _Variant('4. Яркая', (e) => DayCardBold(entry: e)),
    _Variant('5. Кольцо', (e) => DayCardRing(entry: e)),
  ];

  @override
  Widget build(BuildContext context) {
    final v = variants[selected];
    return Scaffold(
      appBar: AppBar(title: Row(children: [Text('Мои дни')])),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: variants.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ChoiceChip(
                label: Text(variants[i].name),
                selected: selected == i,
                onSelected: (_) => setState(() => selected = i),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: demoDays.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => v.builder(demoDays[i]),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── ОБЩИЕ ЧАСТИ ─────────────────────────

class TagChip extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;
  final Color? border;

  const TagChip({
    super.key,
    required this.text,
    required this.background,
    required this.foreground,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: border == null ? null : Border.all(color: border!),
      ),
      child: Text(
        '#$text',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: foreground,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════
// ВАРИАНТ 1 — Цветная полоска слева + квадратный бейдж оценки
// ═════════════════════════════════════════════════════════

class DayCardStripe extends StatelessWidget {
  final DayEntry entry;
  const DayCardStripe({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = ratingColor(entry.rating);

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: c),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullDate(entry.date),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                weekday(entry.date),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: c,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${entry.rating}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: onColor(c),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (entry.note.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        entry.note,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, height: 1.35),
                      ),
                    ],
                    if (entry.tags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final t in entry.tags)
                            TagChip(
                              text: t,
                              background: cs.surfaceContainerHighest,
                              foreground: cs.onSurfaceVariant,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════
// ВАРИАНТ 2 — Тонированная карточка + круг с оценкой слева
// ═════════════════════════════════════════════════════════

class DayCardTinted extends StatelessWidget {
  final DayEntry entry;
  const DayCardTinted({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = ratingColor(entry.rating);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.45), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            child: Text(
              '${entry.rating}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: onColor(c),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      fullDate(entry.date),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      weekdayShort(entry.date),
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (entry.note.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    entry.note,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, height: 1.35),
                  ),
                ],
                if (entry.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final t in entry.tags)
                        TagChip(
                          text: t,
                          background: c.withValues(alpha: 0.18),
                          foreground: cs.onSurface,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════
// ВАРИАНТ 3 — «Календарная»: слева блок с числом, справа контент,
// оценка — звёздочка-пилюля как на IMDb
// ═════════════════════════════════════════════════════════

class DayCardCalendar extends StatelessWidget {
  final DayEntry entry;
  const DayCardCalendar({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = ratingColor(entry.rating);

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Блок даты
            Container(
              width: 62,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weekdayShort(entry.date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: c,
                    ),
                  ),
                  Text(
                    '${entry.date.day}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    monthShort(entry.date),
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: onColor(c),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${entry.rating}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: onColor(c),
                              ),
                            ),
                            Text(
                              '/10',
                              style: TextStyle(
                                fontSize: 11,
                                color: onColor(c).withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (entry.note.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      entry.note,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, height: 1.35),
                    ),
                  ],
                  if (entry.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final t in entry.tags)
                          TagChip(
                            text: t,
                            background: Colors.transparent,
                            foreground: cs.onSurfaceVariant,
                            border: cs.outlineVariant,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════
// ВАРИАНТ 4 — Яркая: вся карточка залита градиентом цвета оценки
// ═════════════════════════════════════════════════════════

class DayCardBold extends StatelessWidget {
  final DayEntry entry;
  const DayCardBold({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final c = ratingColor(entry.rating);
    final fg = onColor(c);
    final darker = Color.lerp(c, Colors.black, 0.22)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c, darker],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weekday(entry.date).toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: fg.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fullDate(entry.date),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
                if (entry.note.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    entry.note,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, height: 1.35, color: fg),
                  ),
                ],
                if (entry.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final t in entry.tags)
                        TagChip(
                          text: t,
                          background: fg.withValues(alpha: 0.2),
                          foreground: fg,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Text(
                '${entry.rating}',
                style: TextStyle(
                  fontSize: 44,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: fg,
                ),
              ),
              Text(
                'из 10',
                style: TextStyle(
                  fontSize: 11,
                  color: fg.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════
// ВАРИАНТ 5 — Кольцо-прогресс с оценкой, минималистичная карточка
// ═════════════════════════════════════════════════════════

class DayCardRing extends StatelessWidget {
  final DayEntry entry;
  const DayCardRing({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = ratingColor(entry.rating);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 58,
                  height: 58,
                  child: CircularProgressIndicator(
                    value: entry.rating / 10,
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                    backgroundColor: c.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(c),
                  ),
                ),
                Text(
                  '${entry.rating}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: c,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${weekday(entry.date)}, ${fullDate(entry.date)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if (entry.note.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    entry.note,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (entry.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      for (final t in entry.tags)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              t,
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
