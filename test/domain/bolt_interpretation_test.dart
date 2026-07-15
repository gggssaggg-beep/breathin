import 'package:flutter_test/flutter_test.dart';

import 'package:breathin/domain/bolt/bolt_interpretation.dart';

void main() {
  group('boltLevelFor — границы диапазонов (науч. справочник)', () {
    test('низкая: < 10 c', () {
      expect(boltLevelFor(0), BoltLevel.low);
      expect(boltLevelFor(9), BoltLevel.low);
    });

    test('средняя: [10, 20)', () {
      expect(boltLevelFor(10), BoltLevel.medium);
      expect(boltLevelFor(19), BoltLevel.medium);
    });

    test('высокая: [20, 40)', () {
      expect(boltLevelFor(20), BoltLevel.high);
      expect(boltLevelFor(39), BoltLevel.high);
    });

    test('очень высокая: >= 40', () {
      expect(boltLevelFor(40), BoltLevel.veryHigh);
      expect(boltLevelFor(120), BoltLevel.veryHigh);
    });
  });

  test('boltRangeText покрывает все уровни непустыми подписями', () {
    for (final level in BoltLevel.values) {
      expect(boltRangeText(level), isNotEmpty);
    }
  });
}
