import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breathin/app/app.dart';
import 'package:breathin/app/hant_theme.dart';
import 'package:breathin/services/theme/ui_theme_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    // Возвращаем глобальный нотификатор к дефолту после теста.
    uiThemeNotifier.value = AppUiTheme.classic;
  });

  testWidgets(
      'smoke: при uiTheme=hant тема содержит HantStyle extension',
      (tester) async {
    uiThemeNotifier.value = AppUiTheme.hant;

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
