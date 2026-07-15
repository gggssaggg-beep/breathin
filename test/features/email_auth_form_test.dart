import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breathin/features/settings/email_auth_form.dart';
import 'package:breathin/l10n/generated/app_localizations.dart';

Widget wrap(Widget child) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('невалидный адрес — ошибка, onSubmit не вызывается',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(wrap(EmailAuthForm(
      actionLabel: 'Sign in by email',
      onSubmit: (_) async {
        calls++;
        return true;
      },
    )));
    await tester.enterText(find.byType(TextField), 'not-an-email');
    await tester.tap(find.text('Sign in by email'));
    await tester.pump();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(calls, 0);
  });

  testWidgets('валидный адрес: onSubmit получает адрес, показ «проверьте почту»',
      (tester) async {
    String? got;
    await tester.pumpWidget(wrap(EmailAuthForm(
      actionLabel: 'Sign in by email',
      onSubmit: (email) async {
        got = email;
        return true;
      },
    )));
    await tester.enterText(find.byType(TextField), '  Me@Example.com ');
    await tester.tap(find.text('Sign in by email'));
    await tester.pump(); // старт отправки
    await tester.pump(); // завершение future
    expect(got, 'Me@Example.com'); // trim, регистр сохранён
    expect(find.textContaining('sent a sign-in link'), findsOneWidget);
    expect(find.textContaining('Me@Example.com'), findsOneWidget);
    expect(find.byType(TextField), findsNothing); // форма скрыта
  });

  testWidgets('сбой отправки (onSubmit=false) оставляет форму на месте',
      (tester) async {
    await tester.pumpWidget(wrap(EmailAuthForm(
      actionLabel: 'Sign in by email',
      onSubmit: (_) async => false,
    )));
    await tester.enterText(find.byType(TextField), 'a@b.co');
    await tester.tap(find.text('Sign in by email'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget); // форма осталась
    expect(find.textContaining('sent a sign-in link'), findsNothing);
  });
}
