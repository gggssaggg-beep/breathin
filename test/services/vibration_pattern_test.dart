import 'package:flutter_test/flutter_test.dart';

import 'package:breathin/domain/models/technique.dart';
import 'package:breathin/services/haptics/vibration_pattern.dart';

/// Сумма длительностей вибрации (нечётные индексы) — «сколько всего дрожит».
int _buzzMs(List<int> p) {
  var sum = 0;
  for (var i = 1; i < p.length; i += 2) {
    sum += p[i];
  }
  return sum;
}

void main() {
  group('VibrationPattern.forPhase', () {
    test('вдох — один короткий импульс', () {
      expect(VibrationPattern.forPhase(PhaseKind.inhale), [0, 80]);
    });

    test('выдох — один длинный импульс', () {
      expect(VibrationPattern.forPhase(PhaseKind.exhale), [0, 300]);
    });

    test('обе задержки — двойной короткий импульс', () {
      expect(VibrationPattern.forPhase(PhaseKind.holdIn), [0, 80, 90, 80]);
      expect(VibrationPattern.forPhase(PhaseKind.holdOut),
          VibrationPattern.forPhase(PhaseKind.holdIn));
    });

    test('выдох дрожит дольше вдоха (различимость на ощупь)', () {
      expect(_buzzMs(VibrationPattern.forPhase(PhaseKind.exhale)),
          greaterThan(_buzzMs(VibrationPattern.forPhase(PhaseKind.inhale))));
    });

    test('все паттерны начинаются с нулевой паузы', () {
      for (final ph in PhaseKind.values) {
        expect(VibrationPattern.forPhase(ph).first, 0);
      }
    });
  });

  test('служебные паттерны непусты', () {
    expect(VibrationPattern.prepTick, isNotEmpty);
    expect(VibrationPattern.sessionEnd.length, greaterThan(2));
  });
}
