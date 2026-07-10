import 'package:flutter/material.dart';

import '../features/home/home_screen.dart';
import 'theme.dart';

/// Корень приложения «Дыши». Тема светлая/тёмная по системной настройке
/// (ТЗ §7). Навигация — Navigator (go_router подключим в партии маршрутов).
class BreathinApp extends StatelessWidget {
  const BreathinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Дыши',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
