import 'package:shared_preferences/shared_preferences.dart';

import '../core/prefs_changes.dart';

/// Персист «своей фразы» фикра (prefs ключи 'fikr.custom.in' / 'fikr.custom.ex').
/// null — своя фраза не задана (оба ключа пусты/не заданы).
class CustomFikrPhraseStore {
  static const _keyIn = 'fikr.custom.in';
  static const _keyEx = 'fikr.custom.ex';

  Future<({String inhale, String exhale})?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final inText = prefs.getString(_keyIn)?.trim() ?? '';
    final exText = prefs.getString(_keyEx)?.trim() ?? '';
    if (inText.isEmpty && exText.isEmpty) return null;
    return (inhale: inText, exhale: exText);
  }

  Future<void> save(String inhale, String exhale) async {
    final trimIn = inhale.trim();
    final trimEx = exhale.trim();
    final prefs = await SharedPreferences.getInstance();
    if (trimIn.isEmpty && trimEx.isEmpty) {
      await prefs.remove(_keyIn);
      await prefs.remove(_keyEx);
    } else {
      await prefs.setString(_keyIn, trimIn);
      await prefs.setString(_keyEx, trimEx);
    }
    PrefsChanges.notify();
  }
}
