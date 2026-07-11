import 'package:breathin/domain/catalog/techniques.dart';
import 'package:breathin/domain/engine/phase_scaling.dart';
import 'package:breathin/domain/models/session_config.dart';
import 'package:breathin/domain/models/technique_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TechniqueSettings', () {
    test('classic: дефолты техники; для 4-16-8 — упрощённый 4-8-8', () {
      final box = TechniqueSettings.classic(boxBreathing);
      expect(box.endMode, EndMode.cycles);
      expect(box.cycles, 10);
      expect(box.phaseSeconds, [4, 4, 4, 4]);

      final p418 = TechniqueSettings.classic(fourSixteenEight);
      expect(p418.useSimplified, isTrue);
      expect(p418.phaseSeconds, [4, 8, 8]);

      final timer = TechniqueSettings.classic(diaphragmatic);
      expect(timer.endMode, EndMode.timer);
      expect(timer.timerMinutes, 5);
      expect(timer.phaseSeconds, isEmpty);
    });

    test('JSON-roundtrip сохраняет все поля', () {
      final s = TechniqueSettings.classic(twoEight).copyWith(
        endMode: EndMode.timer,
        cycles: 25,
        timerMinutes: 12,
        phaseSeconds: [2.5, 10.0],
        keepRatio: false,
        prepSeconds: 5,
      );
      final restored = TechniqueSettings.fromJson(twoEight, s.toJson());
      expect(restored.endMode, s.endMode);
      expect(restored.cycles, s.cycles);
      expect(restored.timerMinutes, s.timerMinutes);
      expect(restored.phaseSeconds, s.phaseSeconds);
      expect(restored.keepRatio, s.keepRatio);
      expect(restored.prepSeconds, s.prepSeconds);
      expect(restored.feedback, s.feedback);
    });

    test('fromJson: пустой/битый JSON закрывается классикой', () {
      final restored = TechniqueSettings.fromJson(boxBreathing, {});
      final classic = TechniqueSettings.classic(boxBreathing);
      expect(restored.cycles, classic.cycles);
      expect(restored.phaseSeconds, classic.phaseSeconds);
      expect(restored.feedback, classic.feedback);
    });

    test('toSessionConfig: 4-7-8 с темпом ×0.75 масштабирует дефолты', () {
      final s = TechniqueSettings.classic(fourSevenEight)
          .copyWith(tempoMultiplier: 0.75);
      final cfg = s.toSessionConfig(fourSevenEight);
      expect(cfg.phaseSeconds, [3.0, 5.25, 6.0]);
    });

    test('toSessionConfig бросает для timer/wimHof', () {
      expect(
        () => TechniqueSettings.classic(diaphragmatic)
            .toSessionConfig(diaphragmatic),
        throwsArgumentError,
      );
    });
  });

  group('applyPhaseChange', () {
    test('perPhase (box): меняется одна фаза, квант 0.5, клэмп 2–10', () {
      final s = TechniqueSettings.classic(boxBreathing);
      expect(applyPhaseChange(boxBreathing, s, 1, 6.3), [4, 6.5, 4, 4]);
      expect(applyPhaseChange(boxBreathing, s, 0, 99), [10, 4, 4, 4]);
      expect(applyPhaseChange(boxBreathing, s, 3, 0.1), [4, 4, 4, 2]);
    });

    test('ratioLock (4-16-8 полный): база тянет всё, пропорция 1:4:2 точная',
        () {
      final s = switchSimplified(
        fourSixteenEight,
        TechniqueSettings.classic(fourSixteenEight),
        false,
      );
      expect(s.phaseSeconds, [4, 16, 8]);
      expect(applyPhaseChange(fourSixteenEight, s, 0, 5), [5, 20, 10]);
      expect(applyPhaseChange(fourSixteenEight, s, 0, 3), [3, 12, 6]);
      // Клэмп масштаба: выше 5-20-10 не уйти.
      expect(applyPhaseChange(fourSixteenEight, s, 0, 8), [5, 20, 10]);
      // Изменение производной фазы тоже держит пропорцию.
      expect(applyPhaseChange(fourSixteenEight, s, 1, 14), [3.5, 14, 7]);
    });

    test('ratioOptional (2-8): keepRatio держит 1:4, без него — perPhase', () {
      final s = TechniqueSettings.classic(twoEight);
      expect(s.keepRatio, isTrue);
      expect(applyPhaseChange(twoEight, s, 0, 2.5), [2.5, 10]);
      // Масштаб клэмпится пересечением диапазонов (выдох ≤10 → вдох ≤2.5).
      expect(applyPhaseChange(twoEight, s, 0, 4), [2.5, 10]);

      final free = s.copyWith(keepRatio: false);
      expect(applyPhaseChange(twoEight, free, 1, 6), [2, 6]);
    });

    test('tempoMultiplier (4-7-8): фазы не редактируются', () {
      final s = TechniqueSettings.classic(fourSevenEight);
      expect(applyPhaseChange(fourSevenEight, s, 0, 9), s.phaseSeconds);
    });

    test('индекс вне диапазона — RangeError', () {
      final s = TechniqueSettings.classic(boxBreathing);
      expect(() => applyPhaseChange(boxBreathing, s, 4, 5), throwsRangeError);
    });
  });

  group('switchSimplified (4-16-8)', () {
    test('переключение сбрасывает длительности к дефолтам режима', () {
      final simplified = TechniqueSettings.classic(fourSixteenEight);
      final full = switchSimplified(fourSixteenEight, simplified, false);
      expect(full.useSimplified, isFalse);
      expect(full.phaseSeconds, [4, 16, 8]);
      final back = switchSimplified(fourSixteenEight, full, true);
      expect(back.phaseSeconds, [4, 8, 8]);
    });

    test('без simplifiedPhases и без изменения режима — no-op', () {
      final s = TechniqueSettings.classic(boxBreathing);
      expect(switchSimplified(boxBreathing, s, false), same(s));
      final p = TechniqueSettings.classic(fourSixteenEight);
      expect(switchSimplified(fourSixteenEight, p, true), same(p));
    });
  });

  group('клэмпы настроек', () {
    test('циклы 1..100, подготовка 3..5', () {
      expect(clampCycles(0), 1);
      expect(clampCycles(100), 100);
      expect(clampCycles(500), 100);
      expect(clampPrepSeconds(0), 3);
      expect(clampPrepSeconds(9), 5);
    });

    test('таймер: counted 1..60, timer-техники 1..30', () {
      expect(clampTimerMinutes(boxBreathing, 90), 60);
      expect(clampTimerMinutes(diaphragmatic, 90), 30);
      expect(clampTimerMinutes(diaphragmatic, 0), 1);
    });
  });
}
