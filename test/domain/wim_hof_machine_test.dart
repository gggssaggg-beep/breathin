import 'package:flutter_test/flutter_test.dart';

import 'package:breathin/domain/engine/wim_hof_machine.dart';

void main() {
  const config = WimHofConfig(
    breaths: 3,
    paceSec: 2.0,
    rounds: 2,
    recoveryHoldSec: 15,
    prepSeconds: 3,
  );

  group('WimHofMachine — детерминированные стадии', () {
    test('prep → breathing точно по границе, остаток dt переносится', () {
      final m = WimHofMachine(config);
      expect(m.stage, WimHofStage.prep);
      expect(m.prepRemainingSec, 3);
      // 3.5 c одним шагом: 3 c prep + 0.5 c уже в breathing.
      m.advance(3500);
      expect(m.stage, WimHofStage.breathing);
      expect(m.breathIndex, 0);
      expect(m.breathProgress, closeTo(0.25, 1e-9)); // 500/2000
    });

    test('счёт дыханий и прогресс внутри дыхания', () {
      final m = WimHofMachine(config)..advance(3000); // конец prep
      m.advance(2000); // одно дыхание
      expect(m.breathIndex, 1);
      m.advance(3000); // ещё 1.5 дыхания → третье, середина
      expect(m.breathIndex, 2);
      expect(m.breathProgress, closeTo(0.5, 1e-9));
    });

    test('после N дыханий — retention; время копится до тапа', () {
      final m = WimHofMachine(config)..advance(3000 + 3 * 2000);
      expect(m.stage, WimHofStage.retention);
      m.advance(90 * 1000); // задержка не завершается сама
      expect(m.stage, WimHofStage.retention);
      expect(m.retentionMs, 90 * 1000);
    });

    test('endRetention пишет секунды раунда и уводит в recovery', () {
      final m = WimHofMachine(config)..advance(3000 + 3 * 2000);
      m.advance(61 * 1000 + 400);
      m.endRetention();
      expect(m.retentionsSec, [61]);
      expect(m.stage, WimHofStage.recovery);
      expect(m.recoveryRemainingSec, 15);
    });

    test('endRetention вне retention — no-op', () {
      final m = WimHofMachine(config);
      m.endRetention();
      expect(m.stage, WimHofStage.prep);
      expect(m.retentionsSec, isEmpty);
    });

    test('recovery → второй раунд → финиш; retentions по всем раундам', () {
      final m = WimHofMachine(config)..advance(3000 + 3 * 2000);
      m.advance(30 * 1000);
      m.endRetention(); // раунд 1: 30 c
      expect(m.round, 1);
      m.advance(15 * 1000); // recovery
      expect(m.stage, WimHofStage.breathing);
      expect(m.round, 2);
      m.advance(3 * 2000); // дыхания раунда 2
      m.advance(45 * 1000);
      m.endRetention(); // раунд 2: 45 c
      m.advance(15 * 1000); // recovery последнего раунда
      expect(m.stage, WimHofStage.finished);
      expect(m.isFinished, isTrue);
      expect(m.retentionsSec, [30, 45]);
      // Финиш поглощает время без ошибок.
      m.advance(1000);
      expect(m.stage, WimHofStage.finished);
    });

    test('totalElapsedMs копит всё время сессии', () {
      final m = WimHofMachine(config)..advance(5000);
      m.advance(2500);
      expect(m.totalElapsedMs, 7500);
    });

    test('prepSeconds=0 стартует сразу с дыхания', () {
      final m = WimHofMachine(const WimHofConfig(prepSeconds: 0));
      expect(m.stage, WimHofStage.breathing);
    });
  });
}
