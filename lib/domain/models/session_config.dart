import 'technique.dart';

/// Как завершается сессия (ТЗ §3.1).
enum EndMode { cycles, timer }

/// Пользовательская настройка запуска сессии. Иммутабельна.
class SessionConfig {
  final EndMode endMode;

  /// Число циклов при [EndMode.cycles] (ТЗ §3.1: 1..100).
  final int cycles;

  /// Длительность таймера в минутах при [EndMode.timer] (ТЗ §3.1: 1..60).
  final int timerMinutes;

  /// Длительности фаз в секундах; длина == `technique.phases.length`.
  final List<double> phaseSeconds;

  /// Подготовительный отсчёт перед первым вдохом (0..5 c, ТЗ §3.4).
  final int prepSeconds;

  const SessionConfig({
    required this.endMode,
    required this.phaseSeconds,
    this.cycles = 10,
    this.timerMinutes = 5,
    this.prepSeconds = 3,
  });

  /// Классические настройки техники: длительности из дефолтов фаз, завершение
  /// по `defaultCycles`. Кнопка «Сбросить к классике» (ТЗ §3.2) даёт ровно это.
  factory SessionConfig.classic(Technique t, {int prepSeconds = 3}) {
    return SessionConfig(
      endMode: EndMode.cycles,
      cycles: t.defaultCycles,
      phaseSeconds: t.phases.map((p) => p.defaultSec).toList(),
      prepSeconds: prepSeconds,
    );
  }
}
