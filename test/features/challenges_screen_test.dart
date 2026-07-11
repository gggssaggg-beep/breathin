import 'package:breathin/features/challenges/challenges_screen.dart';
import 'package:breathin/features/home/home_screen.dart';
import 'package:breathin/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'без AuthService.init (isReady=false) — показывает challengesSignInHint '
    'и кнопку createGuestProfile; список и кнопки создания скрыты',
    (tester) async {
      await tester.pumpWidget(wrap(const ChallengesScreen()));
      await tester.pump();

      // Подсказка входа (challengesSignInHint)
      expect(find.textContaining('Challenges are friendly competitions'), findsOneWidget);

      // Кнопка «Создать профиль» (createGuestProfile)
      expect(find.widgetWithText(FilledButton, 'Create profile (no sign-up)'), findsOneWidget);

      // Кнопок действий с челленджами нет
      expect(find.textContaining('Create challenge'), findsNothing);
      expect(find.textContaining('Enter code'), findsNothing);
    },
  );

  testWidgets(
    'home: тап по tooltip Challenges with friends открывает ChallengesScreen',
    (tester) async {
      await tester.pumpWidget(wrap(const HomeScreen()));
      await tester.pump();

      // Находим кнопку по tooltip
      final tooltipFinder = find.byTooltip('Challenges with friends');
      expect(tooltipFinder, findsOneWidget);

      await tester.tap(tooltipFinder);
      await tester.pumpAndSettle();

      // Открылся ChallengesScreen
      expect(find.byType(ChallengesScreen), findsOneWidget);
    },
  );
}
