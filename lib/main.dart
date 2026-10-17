import 'dart:async';

import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'data/app_storage.dart';
import 'features/home/home_page.dart';

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
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      home: HomePage(
        storage: widget.storage,
        isDarkTheme: _isDarkTheme,
        onDarkThemeChanged: _setDarkTheme,
      ),
    );
  }
}
