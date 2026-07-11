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

  /// [metronome] — вшить тики метронома (ТЗ §3.3): каждый круглую секунду
  /// дыхательной части, с акцентом на тиках, совпадающих с началом фазы.
  SessionPlan compile(
    Technique technique,
    SessionConfig config, {
    bool metronome = false,
  }) {
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

    if (metronome) {
      // Тики: от первого вдоха до гонга (гонговый момент не тикает).
      // Акцент — на тиках, совпадающих с началом какой-либо фазы; при
      // целых длительностях фаз (шаг слайдера 0.5 c возможен, но старты фаз
      // на полусекундах в тик не попадают) сравнение по точному tMs честно.
      final phaseStartTimes = {
        for (final e in events)
          if (e.type == EngineEventType.phaseStart) e.tMs,
      };
      for (var tick = config.prepSeconds * 1000; tick < t; tick += 1000) {
        events.add(EngineEvent(
          tMs: tick,
          type: EngineEventType.metronomeTick,
          accent: phaseStartTimes.contains(tick),
        ));
      }
    }

    // Гонг совпадает с концом последней фазы; сессия логически завершается там же.
    events.add(EngineEvent(tMs: t, type: EngineEventType.gong));
    events.add(EngineEvent(tMs: t, type: EngineEventType.sessionEnd));

    // Контракт SessionPlan — события упорядочены по времени (тики метронома
    // добавлялись после фазовых). List.sort в Dart НЕстабильна — держим
    // порядок вставки при равном tMs вторичным ключом-индексом
    // (фаза раньше её акцент-тика).
    final indexed = events.asMap().entries.toList()
      ..sort((a, b) {
        final byTime = a.value.tMs.compareTo(b.value.tMs);
        return byTime != 0 ? byTime : a.key.compareTo(b.key);
      });
    final ordered = [for (final e in indexed) e.value];

    return SessionPlan(
      events: ordered,
      totalCycles: cycles,
      totalDurationMs: t,
    );
  }
}
