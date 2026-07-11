import 'package:breathin/features/settings/account_section.dart';
import 'package:breathin/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets(
      'без конфигурации Supabase — карточка гостевого режима без кнопки входа',
      (tester) async {
    await tester.pumpWidget(wrap(const AccountSection()));
    expect(find.text('Guest mode'), findsOneWidget);
    expect(find.textContaining('Sign in with Google'), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });
}
