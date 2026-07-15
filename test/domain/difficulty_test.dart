import 'package:flutter_test/flutter_test.dart';

import 'package:breathin/domain/bolt/bolt_interpretation.dart';
import 'package:breathin/domain/catalog/techniques.dart';
import 'package:breathin/domain/difficulty/difficulty.dart';
import 'package:breathin/domain/models/technique.dart';

void main() {
  group('difficultyMultiplier', () {
    test('фиксированные пресеты: мягче < классики < труднее', () {
      expect(difficultyMultiplier(DifficultyPreset.calm), lessThan(1.0));
      expect(difficultyMultiplier(DifficultyPreset.breeze), 1.0);
      expect(difficultyMultiplier(DifficultyPreset.wave), greaterThan(1.0));
      expect(
        difficultyMultiplier(DifficultyPreset.tide),
        greaterThan(difficultyMultiplier(DifficultyPreset.wave)),
      );
    });

    test('«Своё дыхание» растёт с уровнем BOLT', () {
      double mine(BoltLevel? l) =>
          difficultyMultiplier(DifficultyPreset.mine, boltLevel: l);
      expect(mine(BoltLevel.low), lessThan(mine(BoltLevel.medium)));
      expect(mine(BoltLevel.medium), lessThan(mine(BoltLevel.high)));
      expect(mine(BoltLevel.high), lessThan(mine(BoltLevel.veryHigh)));
    });

    test('«Своё дыхание» без теста деградирует к бризу (×1.0)', () {
      expect(difficultyMultiplier(DifficultyPreset.mine, boltLevel: null), 1.0);
    });
  });

  group('presetPhaseSeconds', () {
    test('box: «Прибой» удлиняет фазы, «Штиль» укорачивает', () {
      final classic = [for (final p in boxBreathing.phases!) p.defaultSec];
      final tide = presetPhaseSeconds(
          boxBreathing, difficultyMultiplier(DifficultyPreset.tide));
      final calm = presetPhaseSeconds(
          boxBreathing, difficultyMultiplier(DifficultyPreset.calm));
      expect(tide.first, greaterThan(classic.first));
      expect(calm.first, lessThan(classic.first));
    });

    test('клэмп в диапазон фазы и шаг 0.5', () {
      for (final v in presetPhaseSeconds(boxBreathing, 10.0)) {
        // Не выходит за max любой фазы box (10 c) и кратно 0.5.
        expect(v, lessThanOrEqualTo(10.0));
        expect((v * 2) % 1, 0);
      }
    });

    test('бриз (×1.0) совпадает с классикой', () {
      final classic = [for (final p in boxBreathing.phases!) p.defaultSec];
      expect(presetPhaseSeconds(boxBreathing, 1.0), classic);
    });

    test('tempoMultiplier-техника (4-7-8) не масштабируется пресетом', () {
      expect(presetAffects(fourSevenEight), isFalse);
      final classic =
          [for (final p in fourSevenEight.defaultPhases!) p.defaultSec];
      expect(presetPhaseSeconds(fourSevenEight, 1.6), classic);
    });

    test('timer-техника без фаз: пустой список, presetAffects=false', () {
      expect(presetAffects(diaphragmatic), isFalse);
      expect(presetPhaseSeconds(diaphragmatic, 1.5), isEmpty);
    });
  });
}
