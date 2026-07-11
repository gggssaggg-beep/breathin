import 'package:flutter/material.dart';

import '../features/home/home_screen.dart';
import '../l10n/generated/app_localizations.dart';
import 'theme.dart';

/// Корень приложения «Дыши». Тема светлая/тёмная по системной настройке
/// (ТЗ §7). Навигация — Navigator (go_router подключим в партии маршрутов).
/// Локализация подключена через flutter gen-l10n (lib/l10n/app_ru.arb + app_en.arb).
class BreathinApp extends StatelessWidget {
  const BreathinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
