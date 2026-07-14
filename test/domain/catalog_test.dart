import 'package:breathin/domain/catalog/techniques.dart';
import 'package:breathin/domain/engine/session_plan.dart';
import 'package:breathin/domain/engine/session_plan_compiler.dart';
import 'package:breathin/domain/models/session_config.dart';
import 'package:breathin/domain/models/technique.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Каталог техник (ПЛАН §5.2)', () {
    test('14 записей: 8 counted + 3 timer + Вим Хоф + вытягивающее + элементы',
        () {
      expect(catalog, hasLength(14));
      expect(catalog.where((t) => t.type == TechniqueType.counted), hasLength(8));
      expect(catalog.where((t) => t.type == TechniqueType.timer), hasLength(3));
      expect(catalog.where((t) => t.type == TechniqueType.wimHof), hasLength(1));
      expect(
          catalog.where((t) => t.type == TechniqueType.scripted), hasLength(2));
    });

    test('вытягивающее: 25 дыханий, вдох 4/выдох 4→28→4 (+2), компилируется', () {
      final script = stretchBreath.cycleScript!;
      expect(script, hasLength(25));
      for (final cycle in script) {
        expect(cycle, hasLength(2), reason: 'вдох + выдох');
        expect(cycle[0].kind, PhaseKind.inhale);
        expect(cycle[0].defaultSec, 4, reason: 'вдох всегда 4');
        expect(cycle[1].kind, PhaseKind.exhale);
      }
      final exhales = [for (final c in script) c[1].defaultSec];
      expect(exhales.first, 4);
      expect(exhales.reduce((a, b) => a > b ? a : b), 28, reason: 'пик выдоха');
      expect(exhales.last, 4);

      final plan = const SessionPlanCompiler().compileScript(script);
      expect(plan.totalCycles, 25);
      expect(
        plan.events.where((e) => e.type == EngineEventType.phaseStart),
        hasLength(50),
      );
      // prep(3с) + вдохи(25×4) + сумма выдохов, в мс.
      final exhaleSum = exhales.fold<double>(0, (a, b) => a + b);
      expect(plan.totalDurationMs, ((3 + 100 + exhaleSum) * 1000).round());
    });

    test(
        'дыхание по элементам: 25 циклов, каждый [inhale 4, exhale 6]; '
        '5 сегментов, сумма cycles == 25; segmentForCycle; компиляция', () {
      final script = elementalBreath.cycleScript!;
      expect(script, hasLength(25));
      for (final cycle in script) {
        expect(cycle, hasLength(2), reason: 'вдох + выдох');
        expect(cycle[0].kind, PhaseKind.inhale);
        expect(cycle[0].defaultSec, 4, reason: 'вдох 4');
        expect(cycle[0].editable, isFalse);
        expect(cycle[1].kind, PhaseKind.exhale);
        expect(cycle[1].defaultSec, 6, reason: 'выдох 6');
        expect(cycle[1].editable, isFalse);
      }

      final segs = elementalBreath.segments!;
      expect(segs, hasLength(5));
      expect(segs.map((s) => s.id).toList(),
          ['earth', 'water', 'fire', 'air', 'ether']);
      expect(segs.fold<int>(0, (sum, s) => sum + s.cycles), 25);

      // segmentForCycle
      expect(elementalBreath.segmentForCycle(0)?.id, 'earth');
      expect(elementalBreath.segmentForCycle(4)?.id, 'earth');
      expect(elementalBreath.segmentForCycle(5)?.id, 'water');
      expect(elementalBreath.segmentForCycle(24)?.id, 'ether');
      expect(elementalBreath.segmentForCycle(25), isNull);
      expect(elementalBreath.segmentForCycle(-1), isNull);

      // эфир: маршруты null
      final ether = segs.firstWhere((s) => s.id == 'ether');
      expect(ether.inhale, isNull);
      expect(ether.exhale, isNull);

      // компиляция: 25 циклов, 50 событий phaseStart
      final plan = const SessionPlanCompiler().compileScript(script);
      expect(plan.totalCycles, 25);
      expect(
        plan.events.where((e) => e.type == EngineEventType.phaseStart),
        hasLength(50),
      );
      // prep(3с) + 25*(4+6) = 3 + 250 = 253 с
      expect(plan.totalDurationMs, (3 + 25 * 10) * 1000);
    });

    test('id уникальны и разрешаются через techniqueById', () {
      final ids = catalog.map((t) => t.id).toSet();
      expect(ids, hasLength(catalog.length));
      for (final t in catalog) {
        expect(techniqueById(t.id), same(t));
      }
      expect(() => techniqueById('nope'), throwsArgumentError);
    });

    test('counted-техники имеют фазы и scaling; дефолты внутри диапазонов', () {
      for (final t in catalog.where((t) => t.type == TechniqueType.counted)) {
        expect(t.phases, isNotNull, reason: t.id);
        expect(t.phases, isNotEmpty, reason: t.id);
        expect(t.scaling, isNotNull, reason: t.id);
        for (final p in [...t.phases!, ...?t.simplifiedPhases]) {
          expect(p.defaultSec, inInclusiveRange(p.minSec, p.maxSec),
              reason: '${t.id}/${p.kind}');
        }
      }
    });

    test('timer-техники: таймер 5 мин по умолчанию, диапазон 1–30 (ТЗ §2.2)', () {
      for (final t in catalog.where((t) => t.type == TechniqueType.timer)) {
        expect(t.phases, isNull, reason: t.id);
        expect(t.defaultTimerMin, 5, reason: t.id);
        expect(t.minTimerMin, 1, reason: t.id);
        expect(t.maxTimerMin, 30, reason: t.id);
      }
    });

    test('пропорции паттернов из ТЗ §2.1', () {
      List<double> secs(Technique t) =>
          t.phases!.map((p) => p.defaultSec).toList();
      expect(secs(boxBreathing), [4, 4, 4, 4]);
      expect(secs(triangleBreathing), [4, 4, 4]);
      expect(secs(fourSevenEight), [4, 7, 8]);
      expect(secs(fourTwoFour), [4, 2, 4]);
      expect(secs(twoEight), [2, 8]); // 1:4
      expect(secs(twoTen), [2, 10]); // 1:5
      expect(secs(fourSixteenEight), [4, 16, 8]); // 1:4:2
      expect(secs(coherent), [5.5, 5.5]);
    });

    test('4-16-8: дефолт — упрощённый 4-8-8; только для опытных (high)', () {
      expect(fourSixteenEight.safetyLevel, SafetyLevel.high);
      expect(
        fourSixteenEight.defaultPhases!.map((p) => p.defaultSec).toList(),
        [4, 8, 8],
      );
    });

    test('4-7-8: темп ×0.5/×0.75/×1/×1.25, фазы нередактируемы, новичкам ≤4',
        () {
      expect(fourSevenEight.tempoOptions, [0.5, 0.75, 1.0, 1.25]);
      expect(fourSevenEight.phases!.every((p) => !p.editable), isTrue);
      expect(fourSevenEight.recommendedMaxCyclesNovice, 4);
    });

    test('Вим Хоф: дефолты ТЗ §2.1/§2.3, помечен stage2', () {
      final w = wimHof.wimHof!;
      expect(wimHof.stage2, isTrue);
      expect((w.breaths, w.paceSec, w.rounds, w.recoveryHoldSec),
          (30, 2.0, 3, 15));
      expect((w.minBreaths, w.maxBreaths), (20, 50));
      expect((w.minRounds, w.maxRounds), (1, 5));
    });

    test('Нади Шодхана: интервалы подсказок выкл/10/15/20/30 с', () {
      final cue = nadiShodhana.periodicCue!;
      expect(cue.intervalOptionsSec, [0, 10, 15, 20, 30]);
      expect(cue.defaultIntervalSec, 15);
    });

    test('все counted-техники компилируются классическим конфигом', () {
      const compiler = SessionPlanCompiler();
      for (final t in catalog.where((t) => t.type == TechniqueType.counted)) {
        final plan = compiler.compile(t, SessionConfig.classic(t));
        expect(plan.totalCycles, t.defaultCycles, reason: t.id);
        expect(
          plan.events.where((e) => e.type == EngineEventType.phaseStart),
          hasLength(t.defaultCycles * t.phases!.length),
          reason: t.id,
        );
      }
    });

    test('timer/wimHof не компилируются фазовым конвейером', () {
      const compiler = SessionPlanCompiler();
      expect(() => SessionConfig.classic(diaphragmatic), throwsArgumentError);
      expect(
        () => compiler.compile(
          diaphragmatic,
          const SessionConfig(endMode: EndMode.timer, phaseSeconds: []),
        ),
        throwsArgumentError,
      );
    });
  });
}
