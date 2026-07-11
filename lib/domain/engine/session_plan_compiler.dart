import '../models/session_config.dart';
import '../models/technique.dart';
import 'session_plan.dart';

/// Компилирует технику + настройки в детерминированный [SessionPlan]
/// (см. ПЛАН §3.3). Чистый Dart, без побочных эффектов — тестируется напрямую.
///
/// Именно эта детерминированность позволяет отдать всю сессию аудио-железу
/// одним таймлайном: события известны в момент старта, «стрелять по таймеру»
/// не нужно.
class SessionPlanCompiler {
  const SessionPlanCompiler();

  SessionPlan compile(Technique technique, SessionConfig config) {
    final specs = technique.phases;
    if (specs == null) {
      // Timer-техники — режим `timer` компилятора (П10), Вим Хоф — свой
      // движок (П18); фазовый конвейер применим только к counted.
      throw ArgumentError(
        'Техника ${technique.id} (${technique.type.name}) не компилируется '
        'фазовым конвейером',
      );
    }
    if (config.phaseSeconds.length != specs.length) {
      throw ArgumentError(
        'phaseSeconds (${config.phaseSeconds.length}) != '
        'technique.phases (${specs.length})',
      );
    }

    final phaseMs =
        config.phaseSeconds.map((s) => (s * 1000).round()).toList();
    final cycleMs = phaseMs.fold<int>(0, (a, b) => a + b);
    if (cycleMs <= 0) {
      throw ArgumentError('Суммарная длительность цикла должна быть > 0');
    }

    // Число циклов: явно из настроек или расчёт из таймера. ТЗ §3.1: таймер
    // сводится к целому числу циклов с завершением по ближайшему концу цикла.
    final int cycles;
    if (config.endMode == EndMode.cycles) {
      cycles = config.cycles;
    } else {
      final totalMs = config.timerMinutes * 60 * 1000;
      final fit = totalMs ~/ cycleMs;
      cycles = fit < 1 ? 1 : fit; // минимум один цикл всегда доигрывается (Q2)
    }

    final events = <EngineEvent>[];

    // Подготовительный отсчёт: бипы в начале; первая фаза — после него.
    for (var i = config.prepSeconds; i >= 1; i--) {
      events.add(EngineEvent(
        tMs: (config.prepSeconds - i) * 1000,
        type: EngineEventType.prepCountdown,
        countdownValue: i,
      ));
    }

    var t = config.prepSeconds * 1000;
    for (var c = 0; c < cycles; c++) {
      for (var p = 0; p < specs.length; p++) {
        events.add(EngineEvent(
          tMs: t,
          type: EngineEventType.phaseStart,
          phase: specs[p].kind,
          cycleIndex: c,
        ));
        t += phaseMs[p];
      }
    }

    // Гонг совпадает с концом последней фазы; сессия логически завершается там же.
    events.add(EngineEvent(tMs: t, type: EngineEventType.gong));
    events.add(EngineEvent(tMs: t, type: EngineEventType.sessionEnd));

    return SessionPlan(
      events: events,
      totalCycles: cycles,
      totalDurationMs: t,
    );
  }
}
