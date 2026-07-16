import 'package:breathin/data/session_log_repository.dart';
import 'package:breathin/domain/models/session_record.dart';
import 'package:breathin/features/stats/stats_screen.dart';
import 'package:breathin/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

SessionRecord rec(DateTime at, {int durationSec = 300}) => SessionRecord(
      id: '${at.millisecondsSinceEpoch}',
      techniqueId: 'box',
      startedAt: at,
      durationSec: durationSec,
      cyclesCompleted: 10,
      completed: true,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('пустая история — заглушка вместо календаря', (tester) async {
    await tester.pumpWidget(wrap(StatsScreen(today: DateTime(2026, 7, 12))));
    await tester.pumpAndSettle();
    expect(find.textContaining('No practice yet'), findsOneWidget);
  });

  testWidgets('история: streak, минуты, сессии и заголовок месяца',
      (tester) async {
    final repo = SessionLogRepository();
    await repo.add(rec(DateTime(2026, 7, 11, 8)));
    await repo.add(rec(DateTime(2026, 7, 12, 9), durationSec: 240));

    await tester.pumpWidget(
      wrap(StatsScreen(log: repo, today: DateTime(2026, 7, 12, 20))),
    );
    await tester.pumpAndSettle();

    expect(find.text('2'), findsWidgets); // streak = 2
    expect(find.textContaining('day streak'), findsOneWidget);
    expect(find.text('July 2026'), findsOneWidget);

    // Итоги месяца — ниже сгиба ленивого ListView; докручиваем до
    // разбивки по технике (уникальный якорь: 'sessions' встречается и в
    // итогах месяца, и в разбивке, а scrollUntilVisible требует ровно один).
    await tester.scrollUntilVisible(
      find.text('Box Breathing'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('9'), findsWidgets); // 5+4 минут за месяц
    expect(find.textContaining('sessions'), findsWidgets);
  });

  testWidgets('разбивка по техникам: название и «сессии · минуты»',
      (tester) async {
    final repo = SessionLogRepository();
    await repo.add(rec(DateTime(2026, 7, 11, 8))); // box, 5 мин
    await repo.add(rec(DateTime(2026, 7, 12, 9), durationSec: 240));
    await tester.pumpWidget(
      wrap(StatsScreen(log: repo, today: DateTime(2026, 7, 12, 20))),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Box Breathing'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Box Breathing'), findsOneWidget);
    expect(find.text('2 sessions · 9 min'), findsOneWidget);
  });

  // В1: гостевая подсказка о локальности истории

  SessionRecord _rec10(int i) => rec(
        DateTime(2026, 7, i + 1, 8),
      );

  Future<SessionLogRepository> _repoWith10() async {
    final repo = SessionLogRepository();
    for (var i = 0; i < 10; i++) {
      await repo.add(_rec10(i));
    }
    return repo;
  }

  testWidgets('В1: ≥10 записей + не закрывалась → карточка видна',
      (tester) async {
    final repo = await _repoWith10();
    await tester.pumpWidget(
      wrap(StatsScreen(log: repo, today: DateTime(2026, 7, 15))),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('only on this device'), findsOneWidget);
    expect(find.text('Dismiss'), findsOneWidget);
  });

  testWidgets('В1: тап «Скрыть» — карточка исчезает', (tester) async {
    final repo = await _repoWith10();
    await tester.pumpWidget(
      wrap(StatsScreen(log: repo, today: DateTime(2026, 7, 15))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.textContaining('only on this device'), findsNothing);
  });

  testWidgets('В1: после закрытия пересоздание экрана → не появляется',
      (tester) async {
    SharedPreferences.setMockInitialValues(
      {'stats.guest_hint_dismissed.v1': true},
    );
    final repo = await _repoWith10();
    await tester.pumpWidget(
      wrap(StatsScreen(log: repo, today: DateTime(2026, 7, 15))),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('only on this device'), findsNothing);
  });

  testWidgets('В1: 5 записей → карточка не показывается', (tester) async {
    final repo = SessionLogRepository();
    for (var i = 0; i < 5; i++) {
      await repo.add(rec(DateTime(2026, 7, i + 1, 8)));
    }
    await tester.pumpWidget(
      wrap(StatsScreen(log: repo, today: DateTime(2026, 7, 15))),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('only on this device'), findsNothing);
  });

  testWidgets('навигация к прошлому месяцу и запрет будущего', (tester) async {
    final repo = SessionLogRepository();
    await repo.add(rec(DateTime(2026, 7, 12, 9)));
    await tester.pumpWidget(
      wrap(StatsScreen(log: repo, today: DateTime(2026, 7, 12, 20))),
    );
    await tester.pumpAndSettle();

    final buttons =
        tester.widgetList<IconButton>(find.byType(IconButton)).toList();
    // Последняя IconButton — «вперёд»; на текущем месяце она выключена.
    expect(buttons.last.onPressed, isNull);

    await tester.tap(find.byType(IconButton).first); // назад
    await tester.pumpAndSettle();
    expect(find.text('June 2026'), findsOneWidget);
  });
}
