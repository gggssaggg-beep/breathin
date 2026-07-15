import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breathin/domain/difficulty/difficulty.dart';
import 'package:breathin/features/settings/difficulty_section.dart';
import 'package:breathin/l10n/generated/app_localizations.dart';

Widget wrap(Widget child) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('5 пресетов, выбор прокидывается наверх', (tester) async {
    DifficultyPreset? picked;
    await tester.pumpWidget(wrap(DifficultySection(
      preset: DifficultyPreset.breeze,
      hasBoltResult: true,
      onChanged: (p) => picked = p,
    )));
    expect(find.byType(ChoiceChip), findsNWidgets(5));
    await tester.tap(find.text('Tide'));
    expect(picked, DifficultyPreset.tide);
  });

  testWidgets('«Своё дыхание» без теста подсказывает пройти тест',
      (tester) async {
    await tester.pumpWidget(wrap(DifficultySection(
      preset: DifficultyPreset.mine,
      hasBoltResult: false,
      onChanged: (_) {},
    )));
    expect(find.textContaining('Take the breathing test'), findsOneWidget);
  });

  testWidgets('«Своё дыхание» с тестом показывает обычную заметку',
      (tester) async {
    await tester.pumpWidget(wrap(DifficultySection(
      preset: DifficultyPreset.mine,
      hasBoltResult: true,
      onChanged: (_) {},
    )));
    expect(find.textContaining('Take the breathing test'), findsNothing);
  });
}
