import 'package:breathin/data/session_log_repository.dart';
import 'package:breathin/domain/models/session_record.dart';
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

SessionRecord rec(DateTime at) => SessionRecord(
      id: '${at.millisecondsSinceEpoch}',
      techniqueId: 'box',
      startedAt: at,
      durationSec: 300,
      cyclesCompleted: 10,
      completed: true,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('нет истории — стрик-баннер скрыт', (tester) async {
    await tester.pumpWidget(wrap(HomeScreen(today: DateTime(2026, 7, 15))));
    await tester.pumpAndSettle();
    expect(find.textContaining('day streak'), findsNothing);
  });

  testWidgets('серия из 2 дней — огонёк и подпись «day streak»',
      (tester) async {
    final repo = SessionLogRepository();
    await repo.add(rec(DateTime(2026, 7, 14, 8)));
    await repo.add(rec(DateTime(2026, 7, 15, 9)));

    await tester.pumpWidget(
      wrap(HomeScreen(log: repo, today: DateTime(2026, 7, 15, 20))),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('day streak'), findsOneWidget);
    expect(find.text('2'), findsWidgets); // число дней в баннере
  });

  testWidgets('серия не рвётся до конца дня: практика вчера, не сегодня',
      (tester) async {
    final repo = SessionLogRepository();
    await repo.add(rec(DateTime(2026, 7, 14, 8)));

    await tester.pumpWidget(
      wrap(HomeScreen(log: repo, today: DateTime(2026, 7, 15, 20))),
    );
    await tester.pumpAndSettle();

    // Стрик = 1 (вчера), баннер виден.
    expect(find.textContaining('day streak'), findsOneWidget);
  });
}
