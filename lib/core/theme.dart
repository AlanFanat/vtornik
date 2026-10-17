import 'package:flutter/material.dart';

import 'colors.dart';

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
      // Иконка выбранной вкладки лежит на акцентном индикаторе — делаем её тёмной.
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? onAccentColor : colors.text);
      }),
    ),
  );
}

final ThemeData lightTheme = _buildTheme(AppColors.light, Brightness.light);
final ThemeData darkTheme = _buildTheme(AppColors.dark, Brightness.dark);
