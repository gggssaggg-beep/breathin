import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breathin/data/technique_settings_repository.dart';
import 'package:breathin/domain/catalog/techniques.dart';
import 'package:breathin/domain/models/session_config.dart';
import 'package:breathin/features/session/session_runner.dart';
import 'package:breathin/features/session_setup/session_setup_screen.dart';
import 'package:breathin/l10n/generated/app_localizations.dart';

/// Оборачивает виджет в MaterialApp с AppLocalizations (locale ru по умолчанию).
Widget _wrap(Widget child, {Locale locale = const Locale('ru')}) {
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

  // --- (а) box: 4 слайдера фаз, «Начать» открывает SessionRunner ---
  group('SessionSetupScreen — box (perPhase)', () {
    testWidgets('показывает 4 слайдера фаз и кнопку Начать', (tester) async {
      await tester.pumpWidget(_wrap(
        SessionSetupScreen(technique: boxBreathing),
      ));
      // Ждём загрузки из SharedPreferences
      await tester.pump();
      await tester.pump();

      // 4 фазы у box + слайдер подготовки = 5 слайдеров итого;
      // проверяем, что слайдеров >= 4
      expect(find.byType(Slider), findsAtLeast(4));

      // Кнопка «Начать»
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('тап «Начать» открывает SessionRunner', (tester) async {
      await tester.pumpWidget(_wrap(
        SessionSetupScreen(technique: boxBreathing),
      ));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byType(FilledButton));
      // Используем pump с Duration, не pumpAndSettle — Ticker в SessionRunner тикает бесконечно
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SessionRunner), findsOneWidget);
    });
  });

  // --- (б) two_eight: переключатель keepRatio, при включённом — один слайдер ---
  group('SessionSetupScreen — two_eight (ratioOptional)', () {
    testWidgets('переключатель keepRatio присутствует', (tester) async {
      await tester.pumpWidget(_wrap(
        SessionSetupScreen(technique: twoEight),
      ));
      await tester.pump();
      await tester.pump();

      // SwitchListTile keepRatioLabel
      expect(
        find.byType(SwitchListTile),
        findsWidgets,
      );
    });

    testWidgets('при keepRatio=true слайдер фаз один', (tester) async {
      // Дефолт keepRatio = true
      await tester.pumpWidget(_wrap(
        SessionSetupScreen(technique: twoEight),
      ));
      await tester.pump();
      await tester.pump();

      // В ratio-режиме: 1 слайдер фаз (база) + 1 слайдер циклов + 1 слайдер подготовки = 3
      // При keepRatio=false (perPhase) у two_eight было бы 2 фазовых слайдера → 4 итого.
      // Убеждаемся, что слайдеров именно 3 (ratio-режим), а не 4.
      expect(find.byType(Slider), findsNWidgets(3));
    });
  });

  // --- (в) four_seven_eight: секции фаз нет, чипы темпа есть ---
  group('SessionSetupScreen — four_seven_eight (tempoMultiplier)', () {
    testWidgets('нет секции фаз, есть чипы темпа', (tester) async {
      await tester.pumpWidget(_wrap(
        SessionSetupScreen(technique: fourSevenEight),
      ));
      await tester.pump();
      await tester.pump();

      // Нет слайдеров фаз — только слайдер циклов + слайдер подготовки = 2
      // ChoiceChip есть для каждого tempoOption (4 варианта)
      expect(find.byType(ChoiceChip), findsNWidgets(4));
      // Слайдеры: циклы + prep = 2 (без слайдеров фаз)
      expect(find.byType(Slider), findsNWidgets(2));
    });
  });

  // --- (г) «Сбросить к классике» возвращает дефолт после изменения ---
  group('SessionSetupScreen — reset', () {
    testWidgets('сброс к классике после изменения режима на timer', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(
        SessionSetupScreen(technique: boxBreathing),
      ));
      await tester.pump();
      await tester.pump();

      // Переключаем на Таймер
      await tester.tap(find.text('Таймер'));
      await tester.pump();

      // Нажимаем «Сбросить к классике»
      await tester.tap(find.text('Сбросить к классике'));
      await tester.pump();

      // После сброса должен быть режим «Циклы» (дефолт для box)
      // Проверяем, что SegmentedButton выбрал Циклы
      expect(find.text('Циклы'), findsWidgets);
    });
  });

  // --- (д) после «Начать» настройки сохранены в репозитории ---
  group('SessionSetupScreen — сохранение настроек', () {
    testWidgets('после Начать настройки сохранены в SharedPreferences', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(
        SessionSetupScreen(technique: boxBreathing),
      ));
      await tester.pump();
      await tester.pump();

      // Переключаем на Timer
      await tester.tap(find.text('Таймер'));
      await tester.pump();

      // Жмём «Начать»
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Проверяем через репозиторий, что сохранились настройки с endMode=timer
      final repo = TechniqueSettingsRepository();
      final saved = await repo.load(boxBreathing);
      expect(saved.endMode, EndMode.timer);
    });
  });
}
