import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breathin/features/settings/settings_screen.dart';
import 'package:breathin/l10n/generated/app_localizations.dart';
import 'package:breathin/services/theme/ui_theme_store.dart';

/// Оборачивает SettingsScreen в MaterialApp с локализацией (en).
Widget wrapSettings() => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SettingsScreen(checkUpdates: false),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    // Возвращаем глобальный нотификатор к дефолту после каждого теста.
    uiThemeNotifier.value = AppUiTheme.classic;
  });

  testWidgets('секция «Interface» видна на экране настроек', (tester) async {
    await tester.pumpWidget(wrapSettings());
    await tester.pump(); // ждём setState после async-загрузки

    // Скроллим вниз до секции интерфейса, если она за экраном.
    await tester.scrollUntilVisible(
      find.text('Interface'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Interface'), findsOneWidget);
    expect(find.text('Classic'), findsOneWidget);
    expect(find.text('HANT'), findsOneWidget);
  });

  testWidgets('тап по «HANT» меняет uiThemeNotifier на hant', (tester) async {
    await tester.pumpWidget(wrapSettings());
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('HANT'),
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('HANT'));
    await tester.pump();

    expect(uiThemeNotifier.value, AppUiTheme.hant);
  });
}
