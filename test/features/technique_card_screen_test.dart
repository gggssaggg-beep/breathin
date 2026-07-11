import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breathin/domain/catalog/techniques.dart';
import 'package:breathin/features/catalog/technique_card_screen.dart';
import 'package:breathin/features/catalog/technique_subtitle.dart';
import 'package:breathin/features/session/session_runner.dart';
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
  // --- (а) counted-техника box: описание, польза, безопасность, кнопка Start ---
  group('TechniqueCardScreen — box (counted)', () {
    testWidgets('показывает описание, пользу, безопасность и активную кнопку Start', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(TechniqueCardScreen(technique: boxBreathing)),
      );
      await tester.pump();

      // Секции
      expect(find.text('About'), findsOneWidget);
      expect(find.text('Benefits'), findsOneWidget);
      expect(find.text('Safety'), findsOneWidget);

      // Название в AppBar
      expect(find.text('Box Breathing'), findsWidgets);

      // Кнопка Start активна
      final startBtn = find.widgetWithText(FilledButton, 'Start');
      expect(startBtn, findsOneWidget);
      final btn = tester.widget<FilledButton>(startBtn);
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('тап по Start открывает SessionRunner', (tester) async {
      await tester.pumpWidget(
        _wrap(TechniqueCardScreen(technique: boxBreathing)),
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Start'));
      // pump без duration — выполняет один кадр анимации (route push).
      // Не используем pumpAndSettle, т.к. Ticker в SessionRunner крутится бесконечно.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SessionRunner), findsOneWidget);
    });
  });

  // --- (б) wimHof (stage2): кнопка disabled, текст comingSoonStage2 ---
  group('TechniqueCardScreen — wim_hof (stage2)', () {
    testWidgets('кнопка Start disabled и отображается comingSoonStage2', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(TechniqueCardScreen(technique: wimHof)),
      );
      await tester.pump();

      final startBtn = find.widgetWithText(FilledButton, 'Start');
      expect(startBtn, findsOneWidget);
      final btn = tester.widget<FilledButton>(startBtn);
      expect(btn.onPressed, isNull);

      // Текст comingSoonStage2 (en)
      expect(find.text('Coming in a future update'), findsWidgets);
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
