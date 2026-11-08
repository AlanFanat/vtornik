---
name: vtornik-styling
description: >-
  Provides design guidelines, UI architecture rules, color system, typography,
  and component styling patterns for the vtornik Flutter app. Use this skill whenever
  creating, styling, or modifying UI components, widgets, screens, dialogs, or themes
  in vtornik.
---

# vtornik UI & Styling Guide

Этот скилл содержит правила оформления, цветовую модель, типографику и готовые паттерны верстки для приложения **vtornik** (минималистичный дневник настроения и календарь на Flutter).

Используйте эти правила при создании новых экранов, компонентов, диалогов или рефакторинге существующего UI.

---

## 1. Концепция и эстетика

* **Минимализм и чистота**: визуальный стиль вдохновлен гайдлайнами iOS / Apple Human Interface Design — плоский интерфейс, аккуратные тонкие рамки, отсутствие тяжелых теней (`elevation: 0`, `surfaceTintColor: Colors.transparent`).
* **Бесшовная поддержка тем**: светлая и тёмная темы равнозначны. Все цвета поверхностей, текста и разделителей берутся динамически.
* **Цветовое кодирование настроения**: ключевой визуальный якорь приложения — шкала оценок от 1 до 10 с плавным градиентом от красного к зеленому.

---

## 2. Цветовая система (`lib/core/colors.dart`)

### Доступ к цветам темы: `context.colors`
Все цвета, зависящие от текущей темы, получаются через расширение `context.colors` (`AppColors` ThemeExtension):

| Свойство | Назначение | Светлая тема | Тёмная тема |
| :--- | :--- | :--- | :--- |
| `colors.background` | Фон экранов и `Scaffold` | `#F5F5F7` | `#0C0C0D` |
| `colors.card` | Фон блоков, карточек и диалогов | `#FFFFFF` | `#18181C` |
| `colors.cardBorder` | Тонкие границы карточек и разделителей | `#E3E3E8` | `#29292F` |
| `colors.surface` | Неоцененные дни, чипы тегов, подложки | `#E9E9EE` | `#29292F` |
| `colors.inputFill` | Заливка поля заметки и полей ввода | `#F0F0F4` | `#222227` |
| `colors.text` | Основной читаемый текст | `#18181C` | `#ECECEF` |
| `colors.disabledText` | Текст будущих/неактивных дней | 30% `#18181C` | 30% `#ECECEF` |
| `colors.onRatingColor` | Текст на цветных плашках оценок | `#FFFFFF` | `#ECECEF` |
| `colors.navIndicator` | Подложка активной вкладки снизу | 15% синий | 20% синий |
| `colors.navInactive` | Неактивные иконки и подписи навигации | `#6B7280` | `#9CA3AF` |

### Глобальные константы цветов:
* `accentColor` (`0xFF007AFF`) — фирменный акцентный синий цвет (iOS Blue).
* `onAccentColor` (`0xFF171717`) — текст поверх акцента (если требуется тёмный контраст).
* `errorColor` (`0xFFE0484A`) — индикатор ошибки / предупреждения (совпадает с оценкой 1).
* `impactPositiveColor` (`0xFF10B981`) — положительное влияние тега в статистике (зелёный).
* `impactNegativeColor` (`0xFFF43F5E`) — отрицательное влияние тега в статистике (красный).

### Шкала оценок `ratingColor(rating)`:
Оценки от 1 до 10 имеют строго фиксированную палитру:
1. `0xFFE0484A` (Красный)
2. `0xFFE8603E`
3. `0xFFEE7B3A`
4. `0xFFF29A3C`
5. `0xFFF5B93B`
6. `0xFFEAD23C`
7. `0xFFC4D048`
8. `0xFF9BC653`
9. `0xFF6DBB5E`
10. `0xFF3FA55B` (Зелёный)

---

## 3. Типографика и текстовые стили

Используйте готовые виджеты заголовков из [`lib/widgets/section_title.dart`](file:///c:/Proga/Flutter_projects/vtornik/lib/widgets/section_title.dart):

* **Заголовок экрана**: виджет `PageTitle('Название')` (22px, `FontWeight.bold`, `colors.text`).
* **Заголовок раздела**: виджет `SectionTitle('Раздел')` (16px, `FontWeight.w600`, `colors.text`).
* **Заголовок диалогового окна**: `TextStyle(fontSize: 18, fontWeight: FontWeight.bold)`.
* **Заголовок карточки / плашки**: `TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.text)`.
* **Основной текст и заметки**: `TextStyle(fontSize: 14, height: 1.35, color: colors.text)`.
* **Подписи, даты и подсказки**: `TextStyle(fontSize: 11–13, color: Colors.grey)` или `colors.disabledText`.
* **Числа в ячейках календаря**: `TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: foreground)`. Если день сегодняшний — `decoration: TextDecoration.underline`.

---

## 4. Паттерны верстки компонентов

### 1. Карточка / Контейнер блока
Основной контейнер для блоков (календарь, редактор дня, карточки статистики):
```dart
Container(
  padding: const EdgeInsets.all(10), // или EdgeInsets.all(12)
  decoration: BoxDecoration(
    color: colors.card,
    borderRadius: BorderRadius.circular(10), // 16 для отдельных карточек списка
    border: Border.all(color: colors.cardBorder),
  ),
  child: ...,
)
```

### 2. Поле ввода (`TextField`)
Поля ввода оформляются с мягкой заливкой без рамки:
```dart
TextField(
  controller: controller,
  style: TextStyle(color: colors.text),
  decoration: InputDecoration(
    hintText: 'Подсказка...',
    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
    filled: true,
    fillColor: colors.inputFill,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  ),
)
```

### 3. Чипы тегов (`FilterChip` / `ActionChip`)
Чипы компактные с радиусом скругления 16:
```dart
FilterChip(
  label: Text(tag, style: TextStyle(fontSize: 12, color: selected ? Colors.white : colors.text)),
  selected: selected,
  selectedColor: accentColor,
  backgroundColor: colors.surface,
  showCheckmark: false,
  side: BorderSide.none,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  padding: const EdgeInsets.symmetric(horizontal: 4),
  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
  onSelected: (val) => ...,
)
```

### 4. Шкала оценки дня (`RatingRow`)
10 плиток в одну строку, скругление 8, высота 40:
* Выбранная плитка: `scale: 1.10`, `opacity: 1.0`, цвет `ratingColor(rating)`.
* Невыбранная: `scale: 1.0`, `opacity: 0.5`.

### 5. Ячейка дня календаря (`DayCell`)
* Скругление: `BorderRadius.circular(8)`.
* Оценённый день: цвет `ratingColor(rating)`.
* Пустой день: `colors.surface`.
* Будущий день: прозрачный фон с границей `colors.cardBorder`.
* Выбранный день: граница `BorderSide(color: accentColor, width: 2)`.

---

## 5. Чек-лист для агента при написании нового UI

1. **Никакого жесткого хардкода цветов**:
   * Никогда не пишите `color: Colors.white` или `color: Colors.black` для текста или фонов. Всегда используйте `context.colors.text`, `context.colors.card`, `context.colors.background`.
2. **Проверка контраста**:
   * Для текста на цветных оценках всегда используйте `colors.onRatingColor`.
   * На активном синем чипе тега цвет текста — `Colors.white`.
3. **Компактные отступы**:
   * Базовые отступы приложения — 4, 6, 8, 10, 12, 14 px. Не перегружайте интерфейс избыточными пустыми отступами.
4. **Скругления (`BorderRadius`)**:
   * 8 px — ячейки календаря, плитки оценки.
   * 10–12 px — блоки контейнеров, поля ввода.
   * 16 px — карточки списков, чипы тегов.
5. **Доступность**:
   * Интерактивные плитки и ячейки оборачивайте в `Semantics(button: true, label: ...)`.
