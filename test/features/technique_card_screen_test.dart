import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breathin/domain/catalog/techniques.dart';
import 'package:breathin/features/catalog/technique_card_screen.dart';
import 'package:breathin/features/catalog/technique_subtitle.dart';
import 'package:breathin/features/session_setup/session_setup_screen.dart';
import 'package:breathin/features/wim_hof/wim_hof_setup_screen.dart';
import 'package:breathin/l10n/generated/app_localizations.dart';
import 'package:breathin/l10n/generated/app_localizations_en.dart';

/// Хелпер: оборачивает виджет в MaterialApp с локализацией AppLocalizations
/// (locale en по умолчанию).
Widget _wrap(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // Круглая кнопка старта: находим по ключу (влад. §5).
  final startButton = find.byKey(const ValueKey('start_button'));

  // --- (а) counted-техника box: описание, польза, безопасность, кнопка Start ---
  group('TechniqueCardScreen — box (counted)', () {
    testWidgets('показывает описание, пользу, безопасность и активную кнопку Start', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(TechniqueCardScreen(technique: boxBreathing)),
      );
      await tester.pump();

      // Секции (Benefits/Safety могут быть ниже сгиба — описание box
      // выросло на абзац о тактическом дыхании; доскролливаем).
      expect(find.text('About'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Benefits'), 200);
      expect(find.text('Benefits'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Safety'), 200);
      expect(find.text('Safety'), findsOneWidget);

      // Название в AppBar
      expect(find.text('Box Breathing'), findsWidgets);

      // Подпись «Start» под кнопкой
      expect(find.text('Start'), findsOneWidget);

      // Круглая кнопка активна (InkWell.onTap не null)
      expect(startButton, findsOneWidget);
      final ink = tester.widget<InkWell>(startButton);
      expect(ink.onTap, isNotNull);
    });

    testWidgets('тап по Start открывает SessionSetupScreen', (tester) async {
      await tester.pumpWidget(
        _wrap(TechniqueCardScreen(technique: boxBreathing)),
      );
      await tester.pump();

      await tester.tap(startButton);
      // pump без duration — выполняет один кадр анимации (route push).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SessionSetupScreen), findsOneWidget);
    });
  });

  // --- (б) wimHof (stage2): кнопка disabled, текст comingSoonStage2 ---
  group('TechniqueCardScreen — wim_hof (этап 2 реализован)', () {
    testWidgets('кнопка Start активна, «скоро» нет, тап открывает свой setup',
        (tester) async {
      await tester.pumpWidget(
        _wrap(TechniqueCardScreen(technique: wimHof)),
      );
      await tester.pump();

      expect(startButton, findsOneWidget);
      final ink = tester.widget<InkWell>(startButton);
      expect(ink.onTap, isNotNull);
      expect(find.text('Coming in a future update'), findsNothing);

      await tester.tap(startButton);
      await tester.pumpAndSettle();
      // Открывается свой setup ВХ (не общий SessionSetupScreen).
      expect(find.byType(SessionSetupScreen), findsNothing);
      expect(find.byType(WimHofSetupScreen), findsOneWidget);
    });
  });

  // --- (в) Сабтайтлы ---
  group('techniqueSubtitle', () {
    final l = AppLocalizationsEn();

    test('box → «4-4-4-4 · 10 cycles»', () {
      expect(techniqueSubtitle(l, boxBreathing), '4-4-4-4 · 10 cycles');
    });

    test('coherent содержит «5.5»', () {
      final subtitle = techniqueSubtitle(l, coherent);
      expect(subtitle, contains('5.5'));
    });

    test('diaphragmatic → «5 min»', () {
      expect(techniqueSubtitle(l, diaphragmatic), '5 min');
    });

    test('wimHof → содержит «rounds»', () {
      final subtitle = techniqueSubtitle(l, wimHof);
      // wimHof.rounds = 3 → «3 rounds» (en)
      expect(subtitle, contains('round'));
    });

    test('triangle → «4-4-4 · 10 cycles»', () {
      expect(techniqueSubtitle(l, triangleBreathing), '4-4-4 · 10 cycles');
    });
  });
}
