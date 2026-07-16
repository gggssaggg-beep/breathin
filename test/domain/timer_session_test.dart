import 'package:flutter_test/flutter_test.dart';

import 'package:breathin/domain/engine/timer_session.dart';

void main() {
  group('cueSchedule', () {
    test('интервал 0 → пусто', () {
      expect(
        cueSchedule(const TimerSessionConfig(minutes: 5, cueIntervalSec: 0)),
        isEmpty,
      );
    });

    test('первая подсказка в t=0, чередование с левой', () {
      final s =
          cueSchedule(const TimerSessionConfig(minutes: 1, cueIntervalSec: 15));
      expect(s.map((e) => e.tMs), [0, 15000, 30000, 45000]);
      expect(s.map((e) => e.cue), [
        TimerCue.left,
        TimerCue.right,
        TimerCue.left,
        TimerCue.right,
      ]);
    });

    test('обрубок не ставится: подсказка внутри практики, но остаток < полу'
        'интервала', () {
      // 60 c практики, интервал 25 c: t=50000 внутри практики, но до конца
      // 10 c < 12.5 c (половина) → не ставится.
      final s =
          cueSchedule(const TimerSessionConfig(minutes: 1, cueIntervalSec: 25));
      expect(s.map((e) => e.tMs), [0, 25000]);
    });

    test('граница ровно в полуинтервал — ставится', () {
      // 60 c, интервал 30 c: t=30000, остаток 30 c ≥ 15 c → есть.
      final s =
          cueSchedule(const TimerSessionConfig(minutes: 1, cueIntervalSec: 30));
      expect(s.map((e) => e.tMs), [0, 30000]);
    });
  });

  group('TimerSessionMachine — стадии', () {
    test('prep → practice → finished с переносом остатка dt', () {
      final m = TimerSessionMachine(
        const TimerSessionConfig(minutes: 1, prepSeconds: 2),
      );
      expect(m.stage, TimerStage.prep);
      m.advance(65000); // 2 c prep + 60 c практики + 3 c лишних
      expect(m.stage, TimerStage.finished);
      expect(m.isFinished, isTrue);
      expect(m.totalElapsedMs, 65000);
    });

    test('без подготовки стартует сразу в практике', () {
      final m = TimerSessionMachine(
        const TimerSessionConfig(minutes: 1, prepSeconds: 0),
      );
      expect(m.stage, TimerStage.practice);
      m.advance(59999);
      expect(m.stage, TimerStage.practice);
      expect(m.practiceRemainingSec, 1);
      m.advance(1);
      expect(m.stage, TimerStage.finished);
    });

    test('prepRemainingSec убывает в подготовке', () {
      final m = TimerSessionMachine(
        const TimerSessionConfig(minutes: 1, prepSeconds: 3),
      );
      expect(m.prepRemainingSec, 3);
      m.advance(2999);
      expect(m.prepRemainingSec, 1);
      expect(m.practiceElapsedMs, 0);
    });
  });

  group('TimerSessionMachine — подсказки', () {
    test('cueIndex растёт по достижении отметок, currentCue чередуется', () {
      final m = TimerSessionMachine(
        const TimerSessionConfig(minutes: 1, prepSeconds: 0, cueIntervalSec: 15),
      );
      expect(m.cueIndex, -1);
      expect(m.currentCue, isNull);
      m.advance(1);
      expect(m.cueIndex, 0);
      expect(m.currentCue, TimerCue.left);
      m.advance(15000); // 15001 мс — прошла отметка 15000
      expect(m.cueIndex, 1);
      expect(m.currentCue, TimerCue.right);
      m.advance(30000); // 45001 — прошли 30000 и 45000
      expect(m.cueIndex, 3);
      expect(m.currentCue, TimerCue.right);
    });

    test('первая подсказка (левая) созревает сразу после подготовки', () {
      final m = TimerSessionMachine(
        const TimerSessionConfig(minutes: 1, prepSeconds: 3, cueIntervalSec: 15),
      );
      m.advance(2000); // ещё подготовка
      expect(m.currentCue, isNull);
      m.advance(1000); // ровно конец подготовки → практика, отметка t=0
      expect(m.stage, TimerStage.practice);
      expect(m.cueIndex, 0);
      expect(m.currentCue, TimerCue.left);
    });

    test('без интервала подсказок cueIndex остаётся -1', () {
      final m = TimerSessionMachine(
        const TimerSessionConfig(minutes: 1, prepSeconds: 0, cueIntervalSec: 0),
      );
      m.advance(40000);
      expect(m.cueIndex, -1);
      expect(m.currentCue, isNull);
    });
  });
}
