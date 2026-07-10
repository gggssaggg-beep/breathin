import 'package:flutter_test/flutter_test.dart';

import 'package:breathin/domain/catalog/techniques.dart';
import 'package:breathin/domain/engine/session_plan.dart';
import 'package:breathin/domain/engine/session_plan_compiler.dart';
import 'package:breathin/domain/models/session_config.dart';
import 'package:breathin/domain/models/technique.dart';

void main() {
  const compiler = SessionPlanCompiler();

  group('SessionPlanCompiler — режим циклов', () {
    test('box 4-4-4-4 × 10, prep 3: длительность и число событий', () {
      final plan =
          compiler.compile(boxBreathing, SessionConfig.classic(boxBreathing));
      expect(plan.totalCycles, 10);
      // prep 3 c + 10 циклов × 16 c = 3000 + 160000
      expect(plan.totalDurationMs, 163000);
      expect(plan.phaseStarts.length, 40); // 4 фазы × 10 циклов

      // события строго упорядочены по времени
      for (var i = 1; i < plan.events.length; i++) {
        expect(plan.events[i].tMs, greaterThanOrEqualTo(plan.events[i - 1].tMs));
      }
    });

    test('первая фаза стартует сразу после подготовки', () {
      final plan =
          compiler.compile(boxBreathing, SessionConfig.classic(boxBreathing));
      final first = plan.phaseStarts.first;
      expect(first.tMs, 3000);
      expect(first.phase, PhaseKind.inhale);
      expect(first.cycleIndex, 0);
    });

    test('позиция конкретной фазы: выдох в цикле 2 = 43000 мс', () {
      final plan =
          compiler.compile(boxBreathing, SessionConfig.classic(boxBreathing));
      // prep 3000 + 2 полных цикла (32000) + вдох 4000 + задержка 4000
      final exhaleC2 = plan.phaseStarts.firstWhere(
        (e) => e.cycleIndex == 2 && e.phase == PhaseKind.exhale,
      );
      expect(exhaleC2.tMs, 43000);
    });

    test('prep=0 → первая фаза в t=0, без бипов отсчёта', () {
      const cfg = SessionConfig(
        endMode: EndMode.cycles,
        cycles: 2,
        phaseSeconds: [4, 4, 4, 4],
        prepSeconds: 0,
      );
      final plan = compiler.compile(boxBreathing, cfg);
      expect(
        plan.events.where((e) => e.type == EngineEventType.prepCountdown),
        isEmpty,
      );
      expect(plan.phaseStarts.first.tMs, 0);
      expect(plan.totalDurationMs, 32000);
    });

    test('дробные длительности округляются до мс', () {
      const cfg = SessionConfig(
        endMode: EndMode.cycles,
        cycles: 1,
        phaseSeconds: [2.5, 2.5, 2.5, 2.5], // 10 c = 10000 мс
        prepSeconds: 0,
      );
      final plan = compiler.compile(boxBreathing, cfg);
      expect(plan.totalDurationMs, 10000);
    });
  });

  group('SessionPlanCompiler — режим таймера (ТЗ §3.1)', () {
    test('5 мин при цикле 16 c → floor(300/16) = 18 циклов', () {
      const cfg = SessionConfig(
        endMode: EndMode.timer,
        timerMinutes: 5,
        phaseSeconds: [4, 4, 4, 4],
        prepSeconds: 0,
      );
      final plan = compiler.compile(boxBreathing, cfg);
      expect(plan.totalCycles, 18);
      expect(plan.totalDurationMs, 18 * 16000);
    });

    test('цикл длиннее таймера → минимум 1 цикл (открытый вопрос Q2)', () {
      const cfg = SessionConfig(
        endMode: EndMode.timer,
        timerMinutes: 1, // 60 c
        phaseSeconds: [20, 20, 20, 20], // цикл 80 c > 60 c
        prepSeconds: 0,
      );
      final plan = compiler.compile(boxBreathing, cfg);
      expect(plan.totalCycles, 1);
    });
  });

  group('SessionPlanCompiler — валидация', () {
    test('несовпадение длины phaseSeconds → ArgumentError', () {
      const cfg = SessionConfig(
        endMode: EndMode.cycles,
        cycles: 1,
        phaseSeconds: [4, 4, 4], // у box 4 фазы
      );
      expect(() => compiler.compile(boxBreathing, cfg), throwsArgumentError);
    });
  });

  group('Каталог', () {
    test('techniqueById находит box и бросает на неизвестном id', () {
      expect(techniqueById('box').id, 'box');
      expect(() => techniqueById('nope'), throwsArgumentError);
    });
  });
}
