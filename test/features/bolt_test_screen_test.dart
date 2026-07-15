import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breathin/data/bolt_repository.dart';
import 'package:breathin/domain/models/bolt_result.dart';
import 'package:breathin/features/bolt/bolt_test_screen.dart';
import 'package:breathin/l10n/generated/app_localizations.dart';

Widget wrap(Widget child) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

void main() {
  testWidgets('поток теста: вступление → задержка → результат → сохранение',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repo = BoltRepository();
    await tester.pumpWidget(wrap(BoltTestScreen(repo: repo)));
    await tester.pumpAndSettle();

    // Вступление: методика, дисклеймер, кнопка старта.
    expect(find.text('How it works'), findsOneWidget);
    expect(find.textContaining('not a clinical diagnostic test'),
        findsWidgets);

    await tester.tap(find.text('Start test'));
    await tester.pump();

    // Задержка: секундомер идёт; ждём ~2 c и тапаем «первый позыв».
    expect(find.text('Hold after a calm exhale'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2100));
    await tester.tap(find.text('First urge — stop'));
    await tester.pump();

    // Результат: показан уровень и кнопка сохранения.
    expect(find.text('Your result'), findsOneWidget);
    expect(find.text('Save result'), findsOneWidget);

    await tester.tap(find.text('Save result'));
    await tester.pumpAndSettle();

    // Сохранилось в репозиторий.
    final saved = await repo.all();
    expect(saved, hasLength(1));
    expect(saved.first.seconds, greaterThanOrEqualTo(2));
  });

  testWidgets('вступление показывает историю и график, если есть результаты',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repo = BoltRepository();
    await repo.add(BoltResult(
        id: 'x', takenAt: DateTime(2026, 7, 14), seconds: 15));
    await tester.pumpWidget(wrap(BoltTestScreen(repo: repo)));
    await tester.pumpAndSettle();

    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Latest result'), findsOneWidget);
  });
}
