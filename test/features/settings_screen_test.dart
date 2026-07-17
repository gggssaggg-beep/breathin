import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breathin/features/settings/settings_screen.dart';
import 'package:breathin/l10n/generated/app_localizations.dart';

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

  testWidgets('переключателя интерфейса больше нет (HANT — единственный)',
      (tester) async {
    // Решение владельца 2026-07-17: классика скрыта из UI, секция
    // «Interface» удалена из настроек.
    await tester.pumpWidget(wrapSettings());
    await tester.pump(); // ждём setState после async-загрузки

    // Секция языка ниже фолда — доскролливаем (заодно прокатываем весь
    // список: переключателя не должно быть нигде).
    await tester.scrollUntilVisible(
      find.text('Language'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Interface'), findsNothing);
    expect(find.text('Classic'), findsNothing);
  });
}
