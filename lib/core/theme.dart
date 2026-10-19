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
      height: 70,
      backgroundColor: colors.card,
      indicatorColor: colors.navIndicator,
      elevation: 0,
      surfaceTintColor:
          Colors.transparent, // чистый цвет без оттенка Material 3
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? accentColor : colors.navInactive,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? accentColor : colors.navInactive,
        );
      }),
    ),
  );
}

final ThemeData lightTheme = _buildTheme(AppColors.light, Brightness.light);
final ThemeData darkTheme = _buildTheme(AppColors.dark, Brightness.dark);
