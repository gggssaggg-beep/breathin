import 'package:shared_preferences/shared_preferences.dart';

import '../domain/difficulty/difficulty.dart';

/// Персист глобального пресета сложности (prefs 'difficulty.preset',
/// значение — name enum). Дефолт — «Бриз» (классические длительности).
class DifficultyStore {
  static const _key = 'difficulty.preset';

  Future<DifficultyPreset> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    return DifficultyPreset.values.asNameMap()[raw] ?? DifficultyPreset.breeze;
  }

  Future<void> save(DifficultyPreset preset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, preset.name);
  }
}
