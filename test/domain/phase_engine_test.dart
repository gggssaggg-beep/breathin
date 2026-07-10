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
