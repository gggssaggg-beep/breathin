import 'package:flutter_test/flutter_test.dart';

import 'package:breathin/domain/catalog/techniques.dart';
import 'package:breathin/domain/engine/phase_engine.dart';
import 'package:breathin/domain/engine/session_plan.dart';
import 'package:breathin/domain/engine/session_plan_compiler.dart';
import 'package:breathin/domain/models/session_config.dart';
import 'package:breathin/domain/models/technique.dart';

void main() {
  const compiler = SessionPlanCompiler();
  // box 4-4-4-4 × 2, prep 3 c. Длительность = 3000 + 2×16000 = 35000.
  final plan = compiler.compile(
    boxBreathing,
    const SessionConfig(
      endMode: EndMode.cycles,
      cycles: 2,
      phaseSeconds: [4, 4, 4, 4],
      prepSeconds: 3,
    ),
  );
  final engine = PhaseEngine(plan);

  group('stateAt — стадии', () {
    test('позиция в подготовке', () {
      final s = engine.stateAt(1000);
      expect(s.stage, SessionStage.prep);
      expect(s.prepRemainingMs, 2000);
      expect(s.phase, isNull);
      expect(s.cycleIndex, -1);
    });

    test('старт первой фазы = вдох, цикл 0', () {
      final s = engine.stateAt(3000);
      expect(s.stage, SessionStage.breathing);
      expect(s.phase, PhaseKind.inhale);
      expect(s.cycleIndex, 0);
      expect(s.phaseElapsedMs, 0);
      expect(s.phaseDurationMs, 4000);
    });

    test('середина выдоха цикла 1', () {
      // prep 3000 + цикл0 16000 + вдох 4000 + задержка 4000 = 27000 → выдох c1
      final s = engine.stateAt(27000 + 1500);
      expect(s.phase, PhaseKind.exhale);
      expect(s.cycleIndex, 1);
      expect(s.phaseElapsedMs, 1500);
      expect(s.phaseProgress, closeTo(0.375, 1e-9));
    });

    test('на самом конце → finished', () {
      final s = engine.stateAt(35000);
      expect(s.stage, SessionStage.finished);
      expect(s.isFinished, isTrue);
      expect(s.sessionElapsedMs, 35000);
    });

    test('позиция за концом клампится к finished', () {
      expect(engine.stateAt(999999).stage, SessionStage.finished);
    });

    test('отрицательная позиция → начало подготовки', () {
      final s = engine.stateAt(-500);
      expect(s.stage, SessionStage.prep);
      expect(s.sessionElapsedMs, 0);
    });
  });

  group('производные величины', () {
    test('phaseRemainingSec округляется вверх', () {
      // вдох цикла 0: старт 3000, длит 4000. В 3000+2200 остаётся 1800 мс → 2 c
      expect(engine.stateAt(5200).phaseRemainingSec, 2);
      // ровно в начале фазы — 4 c
      expect(engine.stateAt(3000).phaseRemainingSec, 4);
    });
  });

  group('phaseIndexInCycle', () {
    // box 4-4-4-4 × 2, prep=3000.
    // Цикл 0: вдох 3000..7000, holdIn 7000..11000, выдох 11000..15000, holdOut 15000..19000
    // Цикл 1: вдох 19000..23000, holdIn 23000..27000, выдох 27000..31000, holdOut 31000..35000

    test('в prep — phaseIndexInCycle = -1', () {
      expect(engine.stateAt(1000).phaseIndexInCycle, -1);
    });

    test('первая фаза цикла 0 (вдох) → индекс 0', () {
      expect(engine.stateAt(3000).phaseIndexInCycle, 0);
    });

    test('вторая фаза цикла 0 (holdIn) → индекс 1', () {
      // Середина 2-й фазы (holdIn) цикла 0: t = 7000 + 2000 = 9000
      final s = engine.stateAt(9000);
      expect(s.cycleIndex, 0);
      expect(s.phase, PhaseKind.holdIn);
      expect(s.phaseIndexInCycle, 1);
    });

    test('в середине 2-й фазы 1-го цикла → phaseIndexInCycle = 1', () {
      // Цикл 0 длится 16000 мс (3000..19000).
      // Цикл 1, фаза 1 (holdIn): 23000..27000. Середина: 25000.
      final s = engine.stateAt(25000);
      expect(s.cycleIndex, 1);
      expect(s.phase, PhaseKind.holdIn);
      expect(s.phaseIndexInCycle, 1);
    });

    test('во 2-м цикле фазы начинаются снова с 0', () {
      // Цикл 1, первая фаза (вдох): 19000..23000
      final s = engine.stateAt(20000);
      expect(s.cycleIndex, 1);
      expect(s.phase, PhaseKind.inhale);
      expect(s.phaseIndexInCycle, 0);
    });

    test('4-я фаза цикла 0 (holdOut) → индекс 3', () {
      // holdOut цикла 0: 15000..19000
      final s = engine.stateAt(16000);
      expect(s.cycleIndex, 0);
      expect(s.phase, PhaseKind.holdOut);
      expect(s.phaseIndexInCycle, 3);
    });

    test('в finished → phaseIndexInCycle = -1', () {
      expect(engine.stateAt(35000).phaseIndexInCycle, -1);
    });
  });

  group('eventsInWindow', () {
    test('ловит phaseStart на границе окна', () {
      // старт вдоха цикла 1 в 19000 (prep 3000 + 16000)
      final ev = engine.eventsInWindow(18950, 19050);
      expect(
        ev.any((e) =>
            e.type == EngineEventType.phaseStart &&
            e.phase == PhaseKind.inhale &&
            e.cycleIndex == 1),
        isTrue,
      );
    });

    test('окно (from, to]: событие ровно на from не попадает, на to — попадает',
        () {
      // phaseStart вдоха цикла 0 в t=3000
      expect(engine.eventsInWindow(3000, 4000).any((e) => e.tMs == 3000),
          isFalse);
      expect(engine.eventsInWindow(2000, 3000).any((e) => e.tMs == 3000),
          isTrue);
    });

    test('гонг попадает в окно конца', () {
      final ev = engine.eventsInWindow(34000, 35000);
      expect(ev.any((e) => e.type == EngineEventType.gong), isTrue);
    });
  });
}
