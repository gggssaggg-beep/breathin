import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breathin/services/locale/locale_store.dart';

void main() {
  group('LocaleStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('дефолт — system', () async {
      final lang = await LocaleStore().load();
      expect(lang, AppLanguage.system);
    });

    test('save/load roundtrip для всех языков', () async {
      for (final lang in AppLanguage.values) {
        await LocaleStore().save(lang);
        expect(await LocaleStore().load(), lang);
      }
    });

    test('мусор в prefs → system', () async {
      SharedPreferences.setMockInitialValues({'app.locale': 'garbage_value'});
      final lang = await LocaleStore().load();
      expect(lang, AppLanguage.system);
    });

    test('localeFor: маппинг', () {
      expect(localeFor(AppLanguage.system), isNull);
      expect(localeFor(AppLanguage.ru), const Locale('ru'));
      expect(localeFor(AppLanguage.en), const Locale('en'));
    });
  });
}
