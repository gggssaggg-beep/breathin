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

    // Итоги месяца — ниже сгиба ленивого ListView; докручиваем.
    await tester.scrollUntilVisible(
      find.textContaining('sessions'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('9'), findsWidgets); // 5+4 минут за месяц
    expect(find.textContaining('sessions'), findsOneWidget);
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
