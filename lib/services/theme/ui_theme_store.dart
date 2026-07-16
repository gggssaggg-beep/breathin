import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/prefs_changes.dart';

/// Интерфейс приложения: классический (Material, светлый/тёмный по системе)
/// или HANT — техно-мистический тёмный (приборная панель, циан + янтарь).
enum AppUiTheme { classic, hant }

/// Персист выбранного интерфейса (prefs ключ 'app.ui_theme').
class UiThemeStore {
  static const _key = 'app.ui_theme';

  Future<AppUiTheme> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    return AppUiTheme.values.asNameMap()[raw] ?? AppUiTheme.classic;
  }

  Future<void> save(AppUiTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, theme.name);
    PrefsChanges.notify();
  }
}

/// Нотификатор интерфейса: обновляется при старте (гидрация в main) и при
/// выборе в настройках. MaterialApp слушает через ValueListenableBuilder.
final ValueNotifier<AppUiTheme> uiThemeNotifier =
    ValueNotifier(AppUiTheme.classic);
