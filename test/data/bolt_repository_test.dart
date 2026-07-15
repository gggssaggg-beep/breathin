import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breathin/data/bolt_repository.dart';
import 'package:breathin/domain/models/bolt_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  BoltResult mk(String id, int s) =>
      BoltResult(id: id, takenAt: DateTime(2026, 7, 15), seconds: s);

  test('пустое хранилище — пустой список', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await BoltRepository().all(), isEmpty);
  });

  test('add сохраняет в порядке добавления и переживает roundtrip', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = BoltRepository();
    await repo.add(mk('a', 12));
    await repo.add(mk('b', 18));
    final all = await repo.all();
    expect(all.map((r) => r.id), ['a', 'b']);
    expect(all.map((r) => r.seconds), [12, 18]);
    expect(all.first.takenAt, DateTime(2026, 7, 15));
  });

  test('битый JSON не роняет чтение', () async {
    SharedPreferences.setMockInitialValues({'bolt_log.v1': '{not json'});
    expect(await BoltRepository().all(), isEmpty);
  });
}
