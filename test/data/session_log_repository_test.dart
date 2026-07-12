import 'package:breathin/data/session_log_repository.dart';
import 'package:breathin/domain/models/session_record.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('пустая история → пустой список', () async {
    expect(await SessionLogRepository().all(), isEmpty);
  });

  test('add → all: записи накапливаются и восстанавливаются полностью',
      () async {
    final repo = SessionLogRepository();
    final a = SessionRecord(
      id: 'a',
      techniqueId: 'box',
      startedAt: DateTime(2026, 7, 11, 8, 30),
      durationSec: 163,
      cyclesCompleted: 10,
      completed: true,
    );
    final b = SessionRecord(
      id: 'b',
      techniqueId: 'coherent',
      startedAt: DateTime(2026, 7, 12, 9, 0),
      durationSec: 45,
      cyclesCompleted: 2,
      completed: false,
    );
    await repo.add(a);
    await repo.add(b);

    final all = await repo.all();
    expect(all, hasLength(2));
    expect(all[0].id, 'a');
    expect(all[1].techniqueId, 'coherent');
    expect(all[1].completed, isFalse);
    expect(all[0].startedAt, DateTime(2026, 7, 11, 8, 30));
  });

  test('битый JSON в ключе → пустая история, add работает дальше', () async {
    SharedPreferences.setMockInitialValues({'session_log.v1': '{oops'});
    final repo = SessionLogRepository();
    expect(await repo.all(), isEmpty);
    await repo.add(SessionRecord(
      id: 'x',
      techniqueId: 'box',
      startedAt: DateTime(2026, 7, 11),
      durationSec: 60,
      cyclesCompleted: 3,
      completed: true,
    ));
    expect(await repo.all(), hasLength(1));
  });

  test('параллельные add и mergeAll не теряют записи (очередь, ревью М12)',
      () async {
    final repo = SessionLogRepository();
    SessionRecord rec(String id) => SessionRecord(
          id: id,
          techniqueId: 'box',
          startedAt: DateTime(2026, 7, 12, 10),
          durationSec: 60,
          cyclesCompleted: 3,
          completed: true,
        );
    // Без сериализации перекрывающиеся read-modify-write затирали бы
    // друг друга (у каждого async-зазор между чтением и записью).
    await Future.wait([
      repo.add(rec('a')),
      repo.mergeAll([rec('m1'), rec('m2')]),
      repo.add(rec('b')),
      SessionLogRepository().add(rec('c')), // другой инстанс — то же хранилище
    ]);
    final ids = (await repo.all()).map((r) => r.id).toSet();
    expect(ids, {'a', 'b', 'c', 'm1', 'm2'});
  });
}
