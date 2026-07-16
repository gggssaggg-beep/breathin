import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breathin/data/session_log_repository.dart';
import 'package:breathin/domain/catalog/techniques.dart';
import 'package:breathin/domain/engine/wim_hof_machine.dart';
import 'package:breathin/domain/models/session_record.dart';
import 'package:breathin/features/catalog/technique_card_screen.dart';
import 'package:breathin/features/wim_hof/wim_hof_session_screen.dart';
import 'package:breathin/features/wim_hof/wim_hof_setup_screen.dart';
import 'package:breathin/l10n/generated/app_localizations.dart';

Widget wrap(Widget child) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('карточка ВХ: кнопка Start активна (stage2 снят)',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(wrap(TechniqueCardScreen(technique: wimHof)));
    await tester.pump();
    expect(find.text('Coming in a future update'), findsNothing);
    final ink =
        tester.widget<InkWell>(find.byKey(const ValueKey('start_button')));
    expect(ink.onTap, isNotNull);
  });

  testWidgets('карточка ВХ: секции прогресса нет без истории', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(wrap(
      TechniqueCardScreen(technique: wimHof, log: SessionLogRepository()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Your progress'), findsNothing);
  });

  testWidgets('карточка ВХ: секция прогресса появляется при наличии задержек',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repo = SessionLogRepository();
    await repo.add(SessionRecord(
      id: 's1',
      techniqueId: 'wim_hof',
      startedAt: DateTime(2026, 7, 15),
      durationSec: 300,
      cyclesCompleted: 3,
      completed: true,
      retentionsSec: const [40, 62, 58],
    ));
    await tester.pumpWidget(wrap(
      TechniqueCardScreen(technique: wimHof, log: repo),
    ));
    await tester.pumpAndSettle(); // грузит журнал (initState)
    // Секция ниже сгиба ленивого ListView — проматываем к её нижней строке.
    await tester.scrollUntilVisible(
      find.text('Last session: 40 / 62 / 58'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Your progress'), findsOneWidget);
    expect(find.text('Best hold: 62 s'), findsOneWidget);
    expect(find.text('Last session: 40 / 62 / 58'), findsOneWidget);
  });

  testWidgets('setup: три слайдера и путь через предупреждение к сессии',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(wrap(const WimHofSetupScreen(technique: wimHof)));
    await tester.pumpAndSettle();

    expect(find.text('Breaths per round'), findsOneWidget);
    expect(find.text('Breathing pace'), findsOneWidget);
    expect(find.text('Rounds'), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(3));

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    // Полноэкранное предупреждение: явное подтверждение обязательно.
    expect(find.text('Before you start'), findsOneWidget);
    expect(find.textContaining('IMPORTANT'), findsOneWidget);
    await tester.tap(find.text('I understand the risks — start'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Началась подготовка сессии.
    expect(find.byType(WimHofSessionScreen), findsOneWidget);
    expect(find.text('Get ready'), findsOneWidget);
  });

  testWidgets('сессия: prep → дыхания → задержка (тап) → recovery → финиш '
      'с задержками и записью', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repo = SessionLogRepository();
    const config = WimHofConfig(
      breaths: 2,
      paceSec: 1.0,
      rounds: 1,
      recoveryHoldSec: 2,
      prepSeconds: 1,
    );
    await tester.pumpWidget(wrap(WimHofSessionScreen(
      technique: wimHof,
      config: config,
      log: repo,
    )));

    await tester.pump(const Duration(milliseconds: 1100)); // prep 1 c
    expect(find.text('Round 1 of 1'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2100)); // 2 дыхания
    expect(find.text('Exhale — and hold'), findsOneWidget);

    await tester.pump(const Duration(seconds: 33)); // задержка 33 c
    await tester.tap(find.text('Breathe in'));
    await tester.pump();
    expect(find.text('Deep breath in — and hold'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2100)); // recovery 2 c
    expect(find.text('Retentions by round'), findsOneWidget);
    expect(find.text('33 s'), findsOneWidget);

    // Запись в историю: 1 раунд, retentions зафиксированы.
    final records = await repo.all();
    expect(records, hasLength(1));
    expect(records.single.techniqueId, 'wim_hof');
    expect(records.single.completed, isTrue);
    expect(records.single.cyclesCompleted, 1);
    expect(records.single.retentionsSec, [33]);
    expect(records.single.variant, '2×1');
  });

  testWidgets('стоп во время дыханий БЕЗ завершённой задержки — без записи',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repo = SessionLogRepository();
    await tester.pumpWidget(wrap(WimHofSessionScreen(
      technique: wimHof,
      config: const WimHofConfig(
          breaths: 3, paceSec: 1.0, rounds: 1, prepSeconds: 0),
      log: repo,
    )));
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();
    expect(await repo.all(), isEmpty);
  });
}
