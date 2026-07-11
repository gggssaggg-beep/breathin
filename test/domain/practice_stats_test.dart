import 'package:breathin/domain/models/session_record.dart';
import 'package:breathin/domain/stats/practice_stats.dart';
import 'package:flutter_test/flutter_test.dart';

SessionRecord rec(DateTime at, {int durationSec = 180, String tech = 'box'}) =>
    SessionRecord(
      id: '${at.millisecondsSinceEpoch}',
      techniqueId: tech,
      startedAt: at,
      durationSec: durationSec,
      cyclesCompleted: 10,
      completed: true,
    );

void main() {
  group('PracticeStats', () {
    final july = [
      rec(DateTime(2026, 7, 1, 8)),
      rec(DateTime(2026, 7, 1, 21), durationSec: 300),
      rec(DateTime(2026, 7, 2, 9), durationSec: 61),
      rec(DateTime(2026, 7, 10, 23, 59)),
      rec(DateTime(2026, 6, 30, 10)), // другой месяц
    ];

    test('practisedDays: дни месяца с практикой', () {
      expect(PracticeStats.practisedDays(july, 2026, 7), {1, 2, 10});
      expect(PracticeStats.practisedDays(july, 2026, 6), {30});
      expect(PracticeStats.practisedDays(july, 2025, 7), isEmpty);
    });

    test('minutesByDay: суммирование и округление вверх', () {
      final m = PracticeStats.minutesByDay(july, 2026, 7);
      expect(m[1], 8); // 180 c → 3 мин + 300 c → 5 мин
      expect(m[2], 2); // 61 c → вверх до 2 мин
      expect(m[10], 3);
    });

    test('minutesInMonth и sessionsInMonth', () {
      expect(PracticeStats.minutesInMonth(july, 2026, 7), 13);
      expect(PracticeStats.sessionsInMonth(july, 2026, 7), 4);
    });

    test('byTechnique: агрегация и сортировка по минутам', () {
      final mixed = [
        rec(DateTime(2026, 7, 1), durationSec: 120), // box: 2 мин
        rec(DateTime(2026, 7, 2), durationSec: 120), // box: ещё 2 мин
        rec(DateTime(2026, 7, 3), durationSec: 600, tech: 'coherent'), // 10
        rec(DateTime(2026, 6, 1), durationSec: 6000, tech: 'two_ten'), // вне
      ];
      final rows = PracticeStats.byTechnique(mixed, 2026, 7);
      expect(rows, hasLength(2));
      expect(rows[0].$1, 'coherent'); // 10 мин — первым
      expect(rows[0].$2, (sessions: 1, minutes: 10));
      expect(rows[1].$1, 'box');
      expect(rows[1].$2, (sessions: 2, minutes: 4));
    });

    group('streakDays', () {
      test('серия, заканчивающаяся сегодня', () {
        final records = [
          rec(DateTime(2026, 7, 9, 7)),
          rec(DateTime(2026, 7, 10, 7)),
          rec(DateTime(2026, 7, 11, 7)),
        ];
        expect(
          PracticeStats.streakDays(records, today: DateTime(2026, 7, 11, 22)),
          3,
        );
      });

      test('сегодня ещё не практиковали — серия не рвётся (отсчёт со вчера)',
          () {
        final records = [
          rec(DateTime(2026, 7, 9, 7)),
          rec(DateTime(2026, 7, 10, 7)),
        ];
        expect(
          PracticeStats.streakDays(records, today: DateTime(2026, 7, 11, 9)),
          2,
        );
      });

      test('пропуск дня рвёт серию', () {
        final records = [
          rec(DateTime(2026, 7, 7, 7)),
          rec(DateTime(2026, 7, 8, 7)),
          rec(DateTime(2026, 7, 10, 7)),
        ];
        expect(
          PracticeStats.streakDays(records, today: DateTime(2026, 7, 10, 20)),
          1,
        );
      });

      test('давняя практика — streak 0; пусто — 0', () {
        expect(
          PracticeStats.streakDays(
            [rec(DateTime(2026, 7, 1))],
            today: DateTime(2026, 7, 11),
          ),
          0,
        );
        expect(PracticeStats.streakDays(const [], today: DateTime(2026, 7, 11)),
            0);
      });
    });
  });
}
