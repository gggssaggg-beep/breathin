import 'package:breathin/domain/catalog/techniques.dart';
import 'package:breathin/domain/engine/session_plan.dart';
import 'package:breathin/domain/engine/session_plan_compiler.dart';
import 'package:breathin/domain/models/session_config.dart';
import 'package:breathin/domain/models/technique.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Каталог техник (ПЛАН §5.2)', () {
    test('12 записей: 8 counted + 3 timer + Вим Хоф', () {
      expect(catalog, hasLength(12));
      expect(catalog.where((t) => t.type == TechniqueType.counted), hasLength(8));
      expect(catalog.where((t) => t.type == TechniqueType.timer), hasLength(3));
      expect(catalog.where((t) => t.type == TechniqueType.wimHof), hasLength(1));
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
