import 'dart:math';

import 'package:breathin/core/invite_code.dart';
import 'package:breathin/domain/models/session_record.dart';
import 'package:breathin/domain/stats/challenge_progress.dart';
import 'package:flutter_test/flutter_test.dart';

SessionRecord rec(DateTime at, {int durationSec = 300}) => SessionRecord(
      id: '${at.microsecondsSinceEpoch}',
      techniqueId: 'box',
      startedAt: at,
      durationSec: durationSec,
      cyclesCompleted: 10,
      completed: true,
    );

void main() {
  final start = DateTime(2026, 7, 1);
  final end = DateTime(2026, 7, 14);

  group('challengeProgress', () {
    test('sessions: считает только сессии в окне (границы включительно)', () {
      final records = [
        rec(DateTime(2026, 6, 30, 23)), // до окна
        rec(DateTime(2026, 7, 1, 0, 5)), // первый день
        rec(DateTime(2026, 7, 7)),
        rec(DateTime(2026, 7, 14, 23, 50)), // последний день
        rec(DateTime(2026, 7, 15, 0, 10)), // после окна
      ];
      expect(
        challengeProgress(records, ChallengeMetric.sessions, start, end),
        3,
      );
    });

    test('minutes: округление каждой сессии вверх, как в календаре', () {
      final records = [
        rec(DateTime(2026, 7, 2), durationSec: 61), // 2 мин
        rec(DateTime(2026, 7, 3), durationSec: 300), // 5 мин
        rec(DateTime(2026, 6, 1), durationSec: 6000), // вне окна
      ];
      expect(
        challengeProgress(records, ChallengeMetric.minutes, start, end),
        7,
      );
    });

    test('streak: максимальная серия внутри окна', () {
      final records = [
        rec(DateTime(2026, 7, 2)),
        rec(DateTime(2026, 7, 3)),
        rec(DateTime(2026, 7, 4)),
        // разрыв 5-го
        rec(DateTime(2026, 7, 6)),
        rec(DateTime(2026, 7, 7)),
      ];
      expect(
        challengeProgress(records, ChallengeMetric.streak, start, end),
        3,
      );
    });

    test('streak: дни вне окна серию не удлиняют', () {
      final records = [
        rec(DateTime(2026, 6, 29)),
        rec(DateTime(2026, 6, 30)), // вне окна
        rec(DateTime(2026, 7, 1)),
        rec(DateTime(2026, 7, 2)),
      ];
      expect(
        challengeProgress(records, ChallengeMetric.streak, start, end),
        2,
      );
    });

    test('пустая история → 0 по всем метрикам', () {
      for (final m in ChallengeMetric.values) {
        expect(challengeProgress(const [], m, start, end), 0, reason: '$m');
      }
    });
  });

  group('generateInviteCode', () {
    test('длина и алфавит без путающихся символов', () {
      final code = generateInviteCode(random: Random(42));
      expect(code, hasLength(6));
      for (final ch in code.split('')) {
        expect(inviteCodeAlphabet.contains(ch), isTrue, reason: ch);
      }
      expect(inviteCodeAlphabet.contains('O'), isFalse);
      expect(inviteCodeAlphabet.contains('0'), isFalse);
      expect(inviteCodeAlphabet.contains('I'), isFalse);
      expect(inviteCodeAlphabet.contains('1'), isFalse);
      expect(inviteCodeAlphabet.contains('L'), isFalse);
    });

    test('детерминированность с фиксированным Random', () {
      expect(
        generateInviteCode(random: Random(7)),
        generateInviteCode(random: Random(7)),
      );
    });
  });
}
