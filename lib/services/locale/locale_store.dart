import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Язык приложения: системный (следует ОС), русский или английский.
enum AppLanguage { system, ru, en }

/// Персист выбранного языка (prefs ключ 'app.locale').
class LocaleStore {
  static const _key = 'app.locale';

  Future<AppLanguage> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    return AppLanguage.values.asNameMap()[raw] ?? AppLanguage.system;
  }

  Future<void> save(AppLanguage lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, lang.name);
  }
}

/// null = системная локаль (MaterialApp не переопределяет).
Locale? localeFor(AppLanguage lang) => switch (lang) {
      AppLanguage.system => null,
      AppLanguage.ru => const Locale('ru'),
      AppLanguage.en => const Locale('en'),
    };

/// Нотификатор локали: null = следовать ОС; обновляется при старте и при
/// выборе в настройках. MaterialApp слушает его через ValueListenableBuilder.
final ValueNotifier<Locale?> localeNotifier = ValueNotifier(null);
