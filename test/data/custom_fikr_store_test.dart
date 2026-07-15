import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breathin/data/custom_fikr_store.dart';

void main() {
  group('CustomFikrPhraseStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('load возвращает null при пустых prefs', () async {
      final store = CustomFikrPhraseStore();
      expect(await store.load(), isNull);
    });

    test('save/load roundtrip', () async {
      final store = CustomFikrPhraseStore();
      await store.save('Я дышу', 'Отпускаю');
      final loaded = await store.load();
      expect(loaded, isNotNull);
      expect(loaded!.inhale, 'Я дышу');
      expect(loaded.exhale, 'Отпускаю');
    });

    test('trim: сохраняет обрезанные строки', () async {
      final store = CustomFikrPhraseStore();
      await store.save('  вдох  ', '  выдох  ');
      final loaded = await store.load();
      expect(loaded!.inhale, 'вдох');
      expect(loaded.exhale, 'выдох');
    });

    test('null при пустых строках после сохранения', () async {
      final store = CustomFikrPhraseStore();
      await store.save('что-то', 'что-то');
      await store.save('', '');
      expect(await store.load(), isNull);
    });

    test('null при пробельных строках', () async {
      final store = CustomFikrPhraseStore();
      await store.save('   ', '   ');
      expect(await store.load(), isNull);
    });
  });
}
