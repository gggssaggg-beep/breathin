import 'package:breathin/data/session_log_repository.dart';
import 'package:breathin/domain/models/session_record.dart';
import 'package:breathin/services/sync/session_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

SessionRecord rec(String id, {DateTime? at}) => SessionRecord(
      id: id,
      techniqueId: 'box',
      startedAt: at ?? DateTime(2026, 7, 12, 8),
      durationSec: 163,
      cyclesCompleted: 10,
      completed: true,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('computeUpload', () {
    test('в аплоад идут только записи, которых нет в облаке', () {
      final local = [rec('a'), rec('b'), rec('c')];
      expect(
        computeUpload(local, {'b'}).map((r) => r.id),
        ['a', 'c'],
      );
      expect(computeUpload(local, {'a', 'b', 'c'}), isEmpty);
      expect(computeUpload(const [], {'x'}), isEmpty);
    });
  });

  group('SessionLogRepository.mergeAll', () {
    test('дедупликация по id, локальные записи не трогаются', () async {
      final repo = SessionLogRepository();
      await repo.add(rec('local-1'));
      final added = await repo.mergeAll([
        rec('local-1'), // дубликат — пропустить
        rec('cloud-1', at: DateTime(2026, 7, 10, 9)),
        rec('cloud-2', at: DateTime(2026, 7, 11, 9)),
      ]);
      expect(added, 2);
      final all = await repo.all();
      expect(all.map((r) => r.id), ['local-1', 'cloud-1', 'cloud-2']);
    });

    test('пустой вход — no-op', () async {
      final repo = SessionLogRepository();
      expect(await repo.mergeAll(const []), 0);
      expect(await repo.all(), isEmpty);
    });
  });

  test('syncNow без входа — тихий no-op (isReady=false в тестах)', () async {
    // AuthService не инициализирован → currentUser == null → выхода в сеть нет.
    await SessionSyncService().syncNow();
    expect(await SessionLogRepository().all(), isEmpty);
  });
}
