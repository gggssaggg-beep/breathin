import 'package:breathin/data/favorites_store.dart';
import 'package:breathin/data/session_log_repository.dart';
import 'package:breathin/domain/models/session_record.dart';
import 'package:breathin/features/home/home_screen.dart';
import 'package:breathin/features/session/session_runner.dart';
import 'package:breathin/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget wrap(Widget child) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

SessionRecord rec(DateTime at,
        {String technique = 'box', bool completed = true}) =>
    SessionRecord(
      id: '${at.millisecondsSinceEpoch}-$technique',
      techniqueId: technique,
      startedAt: at,
      durationSec: 300,
      cyclesCompleted: 10,
      completed: completed,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('группы: заголовки секций на месте, «Избранного» нет без звёзд',
      (tester) async {
    await tester.pumpWidget(wrap(HomeScreen(today: DateTime(2026, 7, 16))));
    await tester.pumpAndSettle();
    expect(find.text('Calm & sleep'), findsOneWidget);
    expect(find.text('Favorites'), findsNothing);
    // Дальние секции строятся лениво — доскроллим.
    await tester.scrollUntilVisible(
      find.text('Energy & transformation'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Energy & transformation'), findsOneWidget);
  });

  testWidgets('избранная техника ДУБЛИРУЕТСЯ: и в «Избранном», и в группе',
      (tester) async {
    await FavoritesStore().toggle('box');
    await tester.pumpWidget(wrap(HomeScreen(today: DateTime(2026, 7, 16))));
    await tester.pumpAndSettle();
    expect(find.text('Favorites'), findsOneWidget);
    // Дубль: карточка бокса и в «Избранном», и в группе «Спокойствие»
    // (обе секции в тестовом вьюпорте построены).
    expect(find.text('Box Breathing'), findsNWidgets(2));
  });

  testWidgets('быстрый старт: карточка «Быстрый старт» ведёт сразу в сессию',
      (tester) async {
    final repo = SessionLogRepository();
    await repo.add(rec(DateTime(2026, 7, 16, 8)));
    await tester
        .pumpWidget(wrap(HomeScreen(log: repo, today: DateTime(2026, 7, 16))));
    await tester.pumpAndSettle();

    expect(find.text('Quick start'), findsOneWidget);
    expect(find.textContaining('Box Breathing ·'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('quick_start')));
    // Сессия стартует (визуал-режим в тестах): SessionRunner на экране,
    // минуя карточку и setup.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SessionRunner), findsOneWidget);
  });

  testWidgets('без истории карточки «Быстрый старт» нет', (tester) async {
    await tester.pumpWidget(wrap(HomeScreen(today: DateTime(2026, 7, 16))));
    await tester.pumpAndSettle();
    expect(find.text('Quick start'), findsNothing);
  });

  testWidgets(
      'прерванные практики не задают карточку; '
      'завершённая из более ранней записи — показывается',
      (tester) async {
    final repo = SessionLogRepository();
    // Старая завершённая — техника box.
    await repo.add(rec(DateTime(2026, 7, 16, 8), technique: 'box'));
    // Свежая прерванная — другая техника.
    await repo.add(rec(DateTime(2026, 7, 16, 9),
        technique: 'four_seven_eight', completed: false));
    await tester
        .pumpWidget(wrap(HomeScreen(log: repo, today: DateTime(2026, 7, 16))));
    await tester.pumpAndSettle();

    // Карточка есть (завершённая существует).
    expect(find.text('Quick start'), findsOneWidget);
    // Показывает технику завершённой записи (box), не прерванной.
    expect(find.textContaining('Box Breathing ·'), findsOneWidget);
  });

  testWidgets('только прерванная запись — карточки нет', (tester) async {
    final repo = SessionLogRepository();
    await repo.add(rec(DateTime(2026, 7, 16, 8),
        technique: 'box', completed: false));
    await tester
        .pumpWidget(wrap(HomeScreen(log: repo, today: DateTime(2026, 7, 16))));
    await tester.pumpAndSettle();

    expect(find.text('Quick start'), findsNothing);
  });
}
