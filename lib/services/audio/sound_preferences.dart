/// Выбор звука сессии. Итог итераций 2026-07-15/16: синтезы (свипы, клипы,
/// шум, пад) забракованы владельцем; остались ЖИВЫЕ варианты — «Арфа»
/// (мелодия дышит, утверждена по превью) и «Чаши».
library;

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/prefs_changes.dart';

/// Звуковые варианты. Порядок = порядок в настройках.
enum SoundSet {
  /// Живая арфа: восходящая лесенка на вдох, нисходящая на выдох, тихая
  /// нота на задержке + фоновый медитативный трек (дефолт).
  harp,

  /// Поющие чаши и колокольчики — клипы на стартах фаз.
  bowls,
}

/// Персист выбранного варианта (prefs: ключ sound.set, значение — name enum).
/// Устаревшие значения (flow/nature/minimal) откатываются к дефолту.
class SoundSetStore {
  static const _key = 'sound.set';

  Future<SoundSet> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    return SoundSet.values.asNameMap()[raw] ?? SoundSet.harp;
  }

  Future<void> save(SoundSet set) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, set.name);
    PrefsChanges.notify();
  }
}
