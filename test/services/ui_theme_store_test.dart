import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breathin/services/theme/ui_theme_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UiThemeStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('дефолт — classic при пустых prefs', () async {
      final theme = await UiThemeStore().load();
      expect(theme, AppUiTheme.classic);
    });

    test('save(hant) → load() == hant', () async {
      await UiThemeStore().save(AppUiTheme.hant);
      expect(await UiThemeStore().load(), AppUiTheme.hant);
    });

    test('save(classic) → load() == classic', () async {
      await UiThemeStore().save(AppUiTheme.classic);
      expect(await UiThemeStore().load(), AppUiTheme.classic);
    });

    test('битое значение в prefs → classic (дефолт)', () async {
      SharedPreferences.setMockInitialValues({'app.ui_theme': 'мусор'});
      final theme = await UiThemeStore().load();
      expect(theme, AppUiTheme.classic);
    });

    test('save дёргает PrefsChanges (через NotifyCallback)', () async {
      // Проверяем, что save без ошибок вызывает PrefsChanges.notify().
      // Прямую проверку коллбека делаем в prefs_sync_test.dart.
      await expectLater(
        UiThemeStore().save(AppUiTheme.hant),
        completes,
      );
    });
  });
}
