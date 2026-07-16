import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breathin/data/session_log_repository.dart';
import 'package:breathin/domain/catalog/techniques.dart';
import 'package:breathin/domain/engine/timer_session.dart';
import 'package:breathin/features/timer_session/timer_session_screen.dart';
import 'package:breathin/l10n/generated/app_localizations.dart';

Widget wrap(Widget child) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('поток: prep → практика (смена ноздри по времени) → финиш '
      'с записью', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repo = SessionLogRepository();
    await tester.pumpWidget(wrap(TimerSessionScreen(
      technique: nadiShodhana,
      config: const TimerSessionConfig(
        minutes: 1,
        prepSeconds: 1,
        cueIntervalSec: 15,
      ),
      sound: false,
      vibration: false,
      log: repo,
    )));

    expect(find.text('Get ready'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1200)); // prep 1 c
    // Практика: первая подсказка — левая, оставшееся время (ceil) — 1:00.
    expect(find.text('Left nostril'), findsOneWidget);
    expect(find.text('1:00'), findsOneWidget);

    await tester.pump(const Duration(seconds: 15)); // отметка 15 c — правая
    expect(find.text('Right nostril'), findsOneWidget);

    await tester.pump(const Duration(seconds: 45)); // конец практики
    expect(find.text('Done'), findsOneWidget);

    final records = await repo.all();
    expect(records, hasLength(1));
    expect(records.single.techniqueId, 'nadi_shodhana');
    expect(records.single.completed, isTrue);
    expect(records.single.cyclesCompleted, 0);
    expect(records.single.variant, isNull);
    expect(records.single.durationSec, 61);

    // Тап по финишу закрывает экран (на каталог).
    await tester.tap(find.text('Done'));
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('стоп раньше минуты практики — записи нет', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repo = SessionLogRepository();
    await tester.pumpWidget(wrap(TimerSessionScreen(
      technique: diaphragmatic,
      config: const TimerSessionConfig(minutes: 5, prepSeconds: 0),
      sound: false,
      vibration: false,
      log: repo,
    )));
    await tester.pump(const Duration(seconds: 10));
    await tester.tap(find.text('Stop'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(await repo.all(), isEmpty);
  });

  testWidgets('стоп после минуты практики — прерванная запись', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repo = SessionLogRepository();
    await tester.pumpWidget(wrap(TimerSessionScreen(
      technique: diaphragmatic,
      config: const TimerSessionConfig(minutes: 5, prepSeconds: 0),
      sound: false,
      vibration: false,
      log: repo,
    )));
    await tester.pump(const Duration(seconds: 70));
    await tester.tap(find.text('Stop'));
    await tester.pump(const Duration(milliseconds: 300));
    final records = await repo.all();
    expect(records, hasLength(1));
    expect(records.single.completed, isFalse);
    expect(records.single.durationSec, 70);
  });

  testWidgets('пауза замораживает время, резюм продолжает', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(wrap(TimerSessionScreen(
      technique: axisBreath,
      config: const TimerSessionConfig(minutes: 5, prepSeconds: 0),
      sound: false,
      vibration: false,
      log: SessionLogRepository(),
    )));
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('4:55'), findsOneWidget);

    await tester.tap(find.text('Pause'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 30)); // на паузе время стоит
    expect(find.text('4:55'), findsOneWidget);

    await tester.tap(find.text('Resume'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('4:50'), findsOneWidget);

    // Уходим с экрана — таймер не должен «висеть» после dispose.
    await tester.tap(find.text('Stop'));
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('у техники без подсказок метки ноздри нет', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(wrap(TimerSessionScreen(
      technique: soundBreath,
      config: const TimerSessionConfig(minutes: 5, prepSeconds: 0),
      sound: false,
      vibration: false,
      log: SessionLogRepository(),
    )));
    await tester.pump(const Duration(seconds: 20));
    expect(find.text('Left nostril'), findsNothing);
    expect(find.text('Right nostril'), findsNothing);
    await tester.tap(find.text('Stop'));
    await tester.pump(const Duration(milliseconds: 300));
  });
}
