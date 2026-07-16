import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breathin/domain/catalog/techniques.dart';
import 'package:breathin/features/catalog/technique_card_screen.dart';
import 'package:breathin/features/timer_session/timer_session_screen.dart';
import 'package:breathin/features/timer_session/timer_setup_screen.dart';
import 'package:breathin/l10n/generated/app_localizations.dart';

Widget wrap(Widget child) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('карточки всех 4 таймер-техник: кнопка Start активна',
      (tester) async {
    for (final t in [diaphragmatic, nadiShodhana, axisBreath, soundBreath]) {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(wrap(TechniqueCardScreen(technique: t)));
      await tester.pump();
      expect(find.text('Coming in a future update'), findsNothing,
          reason: 'у ${t.id} не должно быть бейджа «скоро»');
      final ink =
          tester.widget<InkWell>(find.byKey(const ValueKey('start_button')));
      expect(ink.onTap, isNotNull, reason: 'у ${t.id} кнопка должна работать');
    }
  });

  testWidgets('setup Нади Шодханы: длительность, чипы подсказок, подготовка, '
      'тумблеры', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester
        .pumpWidget(wrap(const TimerSetupScreen(technique: nadiShodhana)));
    await tester.pumpAndSettle();

    expect(find.text('Duration, min'), findsOneWidget);
    expect(find.text('Nostril switch cues'), findsOneWidget);
    expect(find.text('Off'), findsOneWidget);
    expect(find.text('15 s'), findsOneWidget);
    expect(find.text('Preparation, s'), findsOneWidget);
    expect(find.text('Sound'), findsOneWidget);
    expect(find.text('Vibration'), findsOneWidget);
  });

  testWidgets('setup диафрагмального: секции подсказок нет', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester
        .pumpWidget(wrap(const TimerSetupScreen(technique: diaphragmatic)));
    await tester.pumpAndSettle();

    expect(find.text('Duration, min'), findsOneWidget);
    expect(find.text('Nostril switch cues'), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('выбор чипа 30 s переживает пересоздание экрана (персист)',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester
        .pumpWidget(wrap(const TimerSetupScreen(technique: nadiShodhana)));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, '30 s'));
    await tester.pumpAndSettle();

    // Пересоздаём экран: настройки должны подняться из стора.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester
        .pumpWidget(wrap(const TimerSetupScreen(technique: nadiShodhana)));
    await tester.pumpAndSettle();

    final chip =
        tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '30 s'));
    expect(chip.selected, isTrue);
  });

  testWidgets('Start ведёт на экран таймер-сессии', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester
        .pumpWidget(wrap(const TimerSetupScreen(technique: nadiShodhana)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start'));
    // НЕ pumpAndSettle: у сессии repeat-анимация свечения — не «устаканится».
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(TimerSessionScreen), findsOneWidget);
    expect(find.text('Get ready'), findsOneWidget);
  });
}
