import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breathin/l10n/generated/app_localizations.dart';
import 'package:breathin/services/update/app_version.dart';
import 'package:breathin/services/update/update_manifest.dart';
import 'package:breathin/services/update/update_service.dart';
import 'package:breathin/features/settings/update_section.dart';

Widget wrap({
  required UpdateCheckResult result,
  bool autoUpdate = true,
  ValueChanged<bool>? onChanged,
  VoidCallback? onUpdateNow,
}) =>
    MaterialApp(
      // UpdateSection теперь локализован — подаём делегаты (en по умолчанию).
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: UpdateSection(
          result: result,
          autoUpdate: autoUpdate,
          onAutoUpdateChanged: onChanged ?? (_) {},
          onUpdateNow: onUpdateNow,
        ),
      ),
    );

void main() {
  final available = UpdateCheckResult(
    UpdateAvailability.available,
    info: const UpdateInfo(
      version: Version(1, 3, 0),
      downloadUrl: 'https://example/app.apk',
      sizeBytes: 25411234,
    ),
  );

  testWidgets('доступно обновление: версия, размер и кнопка «Обновить»',
      (tester) async {
    var tapped = false;
    await tester
        .pumpWidget(wrap(result: available, onUpdateNow: () => tapped = true));
    expect(find.text('Update 1.3.0 available'), findsOneWidget);
    // Единицы размера — по локали виджета (en).
    expect(find.text('≈ 24.2 MB'), findsOneWidget);
    await tester.tap(find.text('Update'));
    expect(tapped, isTrue);
  });

  testWidgets('актуальная версия: карточки обновления нет', (tester) async {
    await tester.pumpWidget(wrap(result: UpdateCheckResult.upToDate));
    expect(find.text("You're on the latest version"), findsOneWidget);
    expect(find.text('Update'), findsNothing);
  });

  testWidgets('сбой проверки показывает сообщение', (tester) async {
    await tester.pumpWidget(wrap(
      result: const UpdateCheckResult(UpdateAvailability.checkFailed),
    ));
    expect(find.text("Couldn't check for updates"), findsOneWidget);
  });

  testWidgets('галочка автообновления вкл и переключается', (tester) async {
    bool? changedTo;
    await tester.pumpWidget(wrap(
      result: UpdateCheckResult.upToDate,
      autoUpdate: true,
      onChanged: (v) => changedTo = v,
    ));
    final sw = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(sw.value, isTrue);
    await tester.tap(find.byType(SwitchListTile));
    expect(changedTo, isFalse);
  });
}
