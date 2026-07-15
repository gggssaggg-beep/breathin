import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breathin/data/difficulty_store.dart';
import 'package:breathin/domain/difficulty/difficulty.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('дефолт — «Бриз» (классические длительности)', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await DifficultyStore().load(), DifficultyPreset.breeze);
  });

  test('save/load сохраняет выбор', () async {
    SharedPreferences.setMockInitialValues({});
    final store = DifficultyStore();
    await store.save(DifficultyPreset.tide);
    expect(await store.load(), DifficultyPreset.tide);
  });

  test('мусорное значение откатывается к дефолту', () async {
    SharedPreferences.setMockInitialValues({'difficulty.preset': 'extreme'});
    expect(await DifficultyStore().load(), DifficultyPreset.breeze);
  });
}
