import 'package:flutter_test/flutter_test.dart';

import 'package:breathin/domain/models/session_record.dart';
import 'package:breathin/domain/stats/wim_hof_stats.dart';

SessionRecord rec({
  required String id,
  String technique = 'wim_hof',
  required DateTime at,
  List<int>? retentions,
}) =>
    SessionRecord(
      id: id,
      techniqueId: technique,
      startedAt: at,
      durationSec: 300,
      cyclesCompleted: retentions?.length ?? 0,
      completed: true,
      retentionsSec: retentions,
    );

void main() {
  group('WimHofStats.progress', () {
    test('фильтрует чужие техники и записи без задержек, сортирует по дате', () {
      final log = [
        rec(id: 'b', at: DateTime(2026, 7, 10), retentions: [40, 55, 50]),
        rec(id: 'a', at: DateTime(2026, 7, 8), retentions: [30, 45]),
        rec(id: 'other', technique: 'box', at: DateTime(2026, 7, 9),
            retentions: [99]),
        rec(id: 'old', at: DateTime(2026, 7, 7)), // ВХ без задержек (старая)
        rec(id: 'empty', at: DateTime(2026, 7, 6), retentions: []),
      ];
      final p = WimHofStats.progress(log);
      expect(p, hasLength(2));
      expect(p.first.date, DateTime(2026, 7, 8));
      expect(p.first.bestSec, 45);
      expect(p.last.bestSec, 55);
      expect(p.last.rounds, [40, 55, 50]);
    });

    test('пустой журнал → пустой список, bestEver = null', () {
      expect(WimHofStats.progress(const []), isEmpty);
      expect(WimHofStats.bestEver(const []), isNull);
    });
  });

  group('WimHofStats.bestEver / bestOnDay', () {
    final log = [
      rec(id: '1', at: DateTime(2026, 7, 15, 8), retentions: [40, 62]),
      rec(id: '2', at: DateTime(2026, 7, 15, 20), retentions: [55, 58]),
      rec(id: '3', at: DateTime(2026, 7, 16, 9), retentions: [71, 60]),
    ];

    test('bestEver — максимум по всем сессиям', () {
      expect(WimHofStats.bestEver(log), 71);
    });

    test('bestOnDay — максимум за календарный день', () {
      expect(WimHofStats.bestOnDay(log, DateTime(2026, 7, 15)), 62);
      expect(WimHofStats.bestOnDay(log, DateTime(2026, 7, 16)), 71);
      expect(WimHofStats.bestOnDay(log, DateTime(2026, 7, 14)), isNull);
    });
  });
}
