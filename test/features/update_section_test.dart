import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
    expect(find.text('Доступно обновление 1.3.0'), findsOneWidget);
    expect(find.text('≈ 24.2 МБ'), findsOneWidget);
    await tester.tap(find.text('Обновить'));
    expect(tapped, isTrue);
  });

  testWidgets('актуальная версия: карточки обновления нет', (tester) async {
    await tester.pumpWidget(wrap(result: UpdateCheckResult.upToDate));
    expect(find.text('Установлена последняя версия'), findsOneWidget);
    expect(find.text('Обновить'), findsNothing);
  });

  testWidgets('сбой проверки показывает сообщение', (tester) async {
    await tester.pumpWidget(wrap(
      result: const UpdateCheckResult(UpdateAvailability.checkFailed),
    ));
    expect(find.text('Не удалось проверить обновления'), findsOneWidget);
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
