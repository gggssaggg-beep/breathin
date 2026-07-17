import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breathin/app/app.dart';
import 'package:breathin/app/hant_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('smoke: приложение всегда в HANT (HantStyle в теме)',
      (tester) async {
    // HANT — единственный интерфейс (решение владельца 2026-07-17).
    await tester.pumpWidget(
      const BreathinApp(checkUpdates: false, showOnboarding: false),
    );

    // Берём контекст дочернего Scaffold — он внутри MaterialApp, тема
    // там уже применена.
    final ctx = tester.element(find.byType(Scaffold).first);
    final hantStyle = Theme.of(ctx).extension<HantStyle>();
    expect(hantStyle, isNotNull,
        reason: 'HantStyle должен быть зарегистрирован в теме HANT');
  });
}
