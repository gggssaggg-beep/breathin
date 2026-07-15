/// Выбор звука сессии (итерации 2026-07-15: свипы «из 90-х», короткие клипы
/// и шум-прибой отклонены владельцем; остались «Поток» и «Чаши»).
library;

import 'package:shared_preferences/shared_preferences.dart';

/// Звуковые варианты. Порядок = порядок в настройках.
enum SoundSet {
  /// Поющий тон дышит с фазами: вверх весь вдох, вниз весь выдох (дефолт).
  /// Синтезируется рендерером на всю длительность фазы (pad_synth.dart).
  flow,

  /// Поющие чаши и колокольчики — клипы на стартах фаз.
  bowls,
}

/// Персист выбранного варианта (prefs: ключ sound.set, значение — name enum).
/// Старые значения (bowls живо; nature/minimal удалены) — мусор откатывается
/// к дефолту.
class SoundSetStore {
  static const _key = 'sound.set';

  Future<SoundSet> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    return SoundSet.values.asNameMap()[raw] ?? SoundSet.flow;
  }

  Future<void> save(SoundSet set) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, set.name);
  }
}
