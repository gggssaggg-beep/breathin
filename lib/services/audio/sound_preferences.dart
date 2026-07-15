/// Выбор звукового набора сессии (отзыв №5: свипы неприятны → «Природа»
/// по умолчанию, «Минимал» остаётся выбором для любителей чистых сигналов).
library;

import 'package:shared_preferences/shared_preferences.dart';

/// Звуковые наборы приложения. Порядок = порядок в настройках.
enum SoundSet {
  /// Волны на вдох/выдох, капли на задержки и тики (дефолт).
  nature,

  /// Исторический синтетический набор: свипы и тоны.
  minimal,
}

/// Персист выбранного набора (prefs: ключ sound.set, значение — name enum).
class SoundSetStore {
  static const _key = 'sound.set';

  Future<SoundSet> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    return SoundSet.values.asNameMap()[raw] ?? SoundSet.nature;
  }

  Future<void> save(SoundSet set) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, set.name);
  }
}
