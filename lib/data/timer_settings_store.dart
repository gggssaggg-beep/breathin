import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/engine/phase_scaling.dart';
import '../domain/models/technique.dart';

/// Настройки одной таймер-сессии (без привязки к конкретной технике).
class TimerSettings {
  final int minutes;
  final int prepSeconds;
  final int cueIntervalSec;
  final bool sound;
  final bool vibration;

  const TimerSettings({
    required this.minutes,
    required this.prepSeconds,
    required this.cueIntervalSec,
    required this.sound,
    required this.vibration,
  });

  TimerSettings copyWith({
    int? minutes,
    int? prepSeconds,
    int? cueIntervalSec,
    bool? sound,
    bool? vibration,
  }) =>
      TimerSettings(
        minutes: minutes ?? this.minutes,
        prepSeconds: prepSeconds ?? this.prepSeconds,
        cueIntervalSec: cueIntervalSec ?? this.cueIntervalSec,
        sound: sound ?? this.sound,
        vibration: vibration ?? this.vibration,
      );
}

/// Персист настроек таймер-техник (prefs `timer.settings.<techniqueId>`,
/// JSON {minutes, prepSeconds, cueIntervalSec, sound, vibration}).
/// Диапазоны клэмпятся по метаданным техники — битые/устаревшие сохранения
/// не выводят сессию за пределы безопасного диапазона.
class TimerSettingsStore {
  static String _key(String techniqueId) => 'timer.settings.$techniqueId';

  /// Загружает сохранённые настройки для техники [t].
  /// Дефолты: minutes из [Technique.defaultTimerMin], prepSeconds=3,
  /// cueIntervalSec из [PeriodicCue.defaultIntervalSec] (0 — если нет cue).
  /// Битый JSON → дефолты.
  Future<TimerSettings> load(Technique t) async {
    final defaults = _defaults(t);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(t.id));
      if (raw == null) return defaults;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final minutes = ((map['minutes'] as num?)?.toInt() ?? defaults.minutes)
          .clamp(t.minTimerMin!, t.maxTimerMin!)
          .toInt();
      final prepSeconds =
          clampPrepSeconds((map['prepSeconds'] as num?)?.toInt() ?? defaults.prepSeconds);
      final rawCue = (map['cueIntervalSec'] as num?)?.toInt() ?? defaults.cueIntervalSec;
      final cueIntervalSec = _clampCue(t, rawCue);
      final sound = (map['sound'] as bool?) ?? defaults.sound;
      final vibration = (map['vibration'] as bool?) ?? defaults.vibration;
      return TimerSettings(
        minutes: minutes,
        prepSeconds: prepSeconds,
        cueIntervalSec: cueIntervalSec,
        sound: sound,
        vibration: vibration,
      );
    } catch (_) {
      return defaults;
    }
  }

  /// Сохраняет настройки [s] для техники [techniqueId].
  Future<void> save(String techniqueId, TimerSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(techniqueId),
      jsonEncode({
        'minutes': s.minutes,
        'prepSeconds': s.prepSeconds,
        'cueIntervalSec': s.cueIntervalSec,
        'sound': s.sound,
        'vibration': s.vibration,
      }),
    );
  }

  TimerSettings _defaults(Technique t) => TimerSettings(
        minutes: t.defaultTimerMin!,
        prepSeconds: 3,
        cueIntervalSec: t.periodicCue?.defaultIntervalSec ?? 0,
        sound: true,
        vibration: true,
      );

  /// Клэмп интервала подсказок: техника без cue → 0; если значение не входит
  /// в список допустимых → дефолт из техники.
  int _clampCue(Technique t, int value) {
    final cue = t.periodicCue;
    if (cue == null) return 0;
    if (cue.intervalOptionsSec.contains(value)) return value;
    return cue.defaultIntervalSec;
  }
}
