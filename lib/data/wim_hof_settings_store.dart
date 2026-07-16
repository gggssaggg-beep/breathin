import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/prefs_changes.dart';
import '../domain/engine/wim_hof_machine.dart';
import '../domain/models/technique.dart';

/// Персист настроек метода Вима Хофа (prefs 'wim_hof.settings', JSON
/// {breaths, paceSec, rounds}). Диапазоны клэмпятся по [WimHofDefaults] —
/// битые/устаревшие сохранения не уводят сессию за пределы безопасного.
class WimHofSettingsStore {
  static const _key = 'wim_hof.settings';

  Future<WimHofConfig> load(WimHofDefaults d) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return _classic(d);
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return WimHofConfig(
        breaths: ((map['breaths'] as num?)?.toInt() ?? d.breaths)
            .clamp(d.minBreaths, d.maxBreaths)
            .toInt(),
        paceSec: ((map['paceSec'] as num?)?.toDouble() ?? d.paceSec)
            .clamp(d.minPaceSec, d.maxPaceSec)
            .toDouble(),
        rounds: ((map['rounds'] as num?)?.toInt() ?? d.rounds)
            .clamp(d.minRounds, d.maxRounds)
            .toInt(),
        recoveryHoldSec: d.recoveryHoldSec,
      );
    } catch (_) {
      return _classic(d);
    }
  }

  WimHofConfig _classic(WimHofDefaults d) => WimHofConfig(
        breaths: d.breaths,
        paceSec: d.paceSec,
        rounds: d.rounds,
        recoveryHoldSec: d.recoveryHoldSec,
      );

  Future<void> save(WimHofConfig c) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'breaths': c.breaths,
        'paceSec': c.paceSec,
        'rounds': c.rounds,
      }),
    );
    PrefsChanges.notify();
  }
}
