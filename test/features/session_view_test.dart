import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breathin/domain/engine/phase_engine.dart';
import 'package:breathin/domain/models/technique.dart';
import 'package:breathin/features/session/session_view.dart';

SessionState breathing({
  PhaseKind phase = PhaseKind.inhale,
  int cycleIndex = 0,
  int totalCycles = 10,
  int phaseElapsedMs = 0,
  int phaseDurationMs = 4000,
}) =>
    SessionState(
      stage: SessionStage.breathing,
      phase: phase,
      cycleIndex: cycleIndex,
      totalCycles: totalCycles,
      phaseElapsedMs: phaseElapsedMs,
      phaseDurationMs: phaseDurationMs,
      prepRemainingMs: 0,
      sessionElapsedMs: 5000,
      sessionDurationMs: 163000,
    );

Widget wrap(SessionState s, {VoidCallback? onPauseStop}) => MaterialApp(
      home: SessionView(state: s, onPauseStop: onPauseStop),
    );

void main() {
  testWidgets('фаза вдоха: подпись, отсчёт и номер цикла', (tester) async {
    await tester.pumpWidget(wrap(breathing(
      phase: PhaseKind.inhale,
      cycleIndex: 0,
      totalCycles: 10,
      phaseElapsedMs: 0,
      phaseDurationMs: 4000,
    )));
    expect(find.text('Вдох'), findsOneWidget);
    expect(find.text('4'), findsOneWidget); // отсчёт секунд фазы
    expect(find.text('1 / 10'), findsOneWidget); // 0-based → 1-based
  });

  testWidgets('задержки обеих фаз подписаны «Задержка»', (tester) async {
    await tester.pumpWidget(wrap(breathing(phase: PhaseKind.holdOut)));
    expect(find.text('Задержка'), findsOneWidget);
  });

  testWidgets('подготовка: «Приготовьтесь» и обратный отсчёт', (tester) async {
    await tester.pumpWidget(wrap(const SessionState(
      stage: SessionStage.prep,
      phase: null,
      cycleIndex: -1,
      totalCycles: 10,
      phaseElapsedMs: 0,
      phaseDurationMs: 0,
      prepRemainingMs: 2500,
      sessionElapsedMs: 500,
      sessionDurationMs: 163000,
    )));
    expect(find.text('Приготовьтесь'), findsOneWidget);
    expect(find.text('3'), findsOneWidget); // ceil(2500/1000)
    expect(find.text('—'), findsOneWidget); // цикл не начался
  });

  testWidgets('завершение показывает «Готово»', (tester) async {
    await tester.pumpWidget(wrap(const SessionState(
      stage: SessionStage.finished,
      phase: null,
      cycleIndex: -1,
      totalCycles: 10,
      phaseElapsedMs: 0,
      phaseDurationMs: 0,
      prepRemainingMs: 0,
      sessionElapsedMs: 163000,
      sessionDurationMs: 163000,
    )));
    expect(find.text('Готово'), findsOneWidget);
  });

  testWidgets('кнопка паузы/стоп вызывает колбэк', (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(breathing(), onPauseStop: () => tapped = true));
    await tester.tap(find.byType(FilledButton));
    expect(tapped, isTrue);
  });
}
