import 'package:flutter_test/flutter_test.dart';

import 'package:breathin/domain/models/session_record.dart';
import 'package:breathin/services/reminders/streak_reminder.dart';

SessionRecord rec(DateTime at) => SessionRecord(
      id: '${at.millisecondsSinceEpoch}',
      techniqueId: 'box',
      startedAt: at,
      durationSec: 300,
      cyclesCompleted: 10,
      completed: true,
    );

void main() {
  group('nextStreakReminderAt (С1)', () {
    test('пустой журнал → null (серии нет)', () {
      expect(nextStreakReminderAt(const [], DateTime(2026, 7, 16, 10)), isNull);
    });

    test('серия умерла (последняя практика 3 дня назад) → null', () {
      final records = [rec(DateTime(2026, 7, 13, 9))];
      expect(
          nextStreakReminderAt(records, DateTime(2026, 7, 16, 10)), isNull);
    });

    test('практика была сегодня → завтра в 20:00', () {
      final records = [rec(DateTime(2026, 7, 16, 8))];
      expect(
        nextStreakReminderAt(records, DateTime(2026, 7, 16, 9)),
        DateTime(2026, 7, 17, 20),
      );
    });

    test('вчера была, сегодня нет, утро → сегодня в 20:00', () {
      final records = [rec(DateTime(2026, 7, 15, 8))];
      expect(
        nextStreakReminderAt(records, DateTime(2026, 7, 16, 10)),
        DateTime(2026, 7, 16, 20),
      );
    });

    test('вчера была, сегодня нет, уже вечер (после 20:00) → null', () {
      final records = [rec(DateTime(2026, 7, 15, 8))];
      expect(
          nextStreakReminderAt(records, DateTime(2026, 7, 16, 21)), isNull);
    });

    test('переход месяца: практика 31-го → 1-е число, 20:00', () {
      final records = [rec(DateTime(2026, 7, 31, 8))];
      expect(
        nextStreakReminderAt(records, DateTime(2026, 7, 31, 22)),
        DateTime(2026, 8, 1, 20),
      );
    });
  });
}
