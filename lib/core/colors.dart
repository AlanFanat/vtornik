import 'package:flutter/material.dart';

/// Акцент и цвета текста поверх ярких заливок одинаковы в обеих темах.
const Color accentColor = Color(0xFF007aff); // акцент (синий)
const Color onAccentColor = Color(0xFF171717); // текст на акценте

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
    required this.onRatingColor,
    required this.navIndicator,
    required this.navInactive,
  });

  final Color background; // фон экрана
  final Color card; // фон карточки
  final Color cardBorder; // рамки
  final Color surface; // ячейки, чипы, плитки оценок
  final Color inputFill; // фон поля заметки и нижней панели
  final Color text; // основной текст
  final Color disabledText; // текст будущих дней
  final Color onRatingColor; // текст на цвете оценки
  final Color navIndicator; // индикатор навигации
  final Color navInactive; // неактивная навигация

  static const light = AppColors(
    background: Color(0xFFf5f5f7),
    card: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFE3E3E8),
    surface: Color(0xFFE9E9EE),
    inputFill: Color(0xFFF0F0F4),
    text: Color(0xFF18181C),
    disabledText: Color(0x4D18181C),
    onRatingColor: Color(0xFFECECEF),
    navIndicator: Color(0x26007AFF), // синий 15%
    navInactive: Color(0xFF6B7280),
  );

  static const dark = AppColors(
    background: Color(0xFF0C0C0D),
    card: Color(0xFF18181C),
    cardBorder: Color(0xFF29292F),
    surface: Color(0xFF29292F),
    inputFill: Color(0xFF222227),
    text: Color(0xFFECECEF),
    disabledText: Color(0x4DECECEF),
    onRatingColor: Color(0xFFECECEF),
    navIndicator: Color(0x33007AFF), // синий 20%
    navInactive: Color(0xFF9CA3AF),
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
    Color? onRatingColor,
    Color? navIndicator,
    Color? navInactive,
  }) {
    return AppColors(
      background: background ?? this.background,
      card: card ?? this.card,
      cardBorder: cardBorder ?? this.cardBorder,
      surface: surface ?? this.surface,
      inputFill: inputFill ?? this.inputFill,
      text: text ?? this.text,
      disabledText: disabledText ?? this.disabledText,
      onRatingColor: onRatingColor ?? this.onRatingColor,
      navIndicator: navIndicator ?? this.navIndicator,
      navInactive: navInactive ?? this.navInactive,
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
      onRatingColor: Color.lerp(onRatingColor, other.onRatingColor, t)!,
      navIndicator: Color.lerp(navIndicator, other.navIndicator, t)!,
      navInactive: Color.lerp(navInactive, other.navInactive, t)!,
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

/// Красный для ошибок (совпадает с цветом оценки 1).
const Color errorColor = Color(0xFFE0484A);
