import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breathin/domain/engine/phase_engine.dart';
import 'package:breathin/domain/models/technique.dart';
import 'package:breathin/features/session/session_view.dart';
import 'package:breathin/l10n/generated/app_localizations.dart';

SessionState breathing({
  PhaseKind phase = PhaseKind.inhale,
  int cycleIndex = 0,
  int totalCycles = 10,
  int phaseElapsedMs = 0,
  int phaseDurationMs = 4000,
  int phaseIndexInCycle = 0,
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
      phaseIndexInCycle: phaseIndexInCycle,
    );

const finished = SessionState(
  stage: SessionStage.finished,
  phase: null,
  cycleIndex: -1,
  totalCycles: 10,
  phaseElapsedMs: 0,
  phaseDurationMs: 0,
  prepRemainingMs: 0,
  sessionElapsedMs: 163000,
  sessionDurationMs: 163000,
  phaseIndexInCycle: -1,
);

// Локаль тестов — en (дефолт flutter_test): ожидания на EN-строках ARB.
Widget wrap(
  SessionState s, {
  bool paused = false,
  VoidCallback? onPauseResume,
  VoidCallback? onStop,
  VisualShape shape = VisualShape.circle,
  BreathSegment? segment,
  ({String inhale, String exhale})? phraseTexts,
}) =>
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SessionView(
        state: s,
        shape: shape,
        paused: paused,
        onPauseResume: onPauseResume,
        onStop: onStop,
        segment: segment,
        phraseTexts: phraseTexts,
      ),
    );

void main() {
  group('фразы фикра (№10)', () {
    testWidgets('на вдохе — фраза вдоха, на выдохе — фраза выдоха',
        (tester) async {
      const p = (inhale: 'I am here', exhale: 'Now');
      await tester.pumpWidget(
          wrap(breathing(phase: PhaseKind.inhale), phraseTexts: p));
      expect(find.text('I am here'), findsOneWidget);
      expect(find.text('Now'), findsNothing);

      await tester.pumpWidget(
          wrap(breathing(phase: PhaseKind.exhale), phraseTexts: p));
      await tester.pumpAndSettle(); // AnimatedSwitcher доигрывает смену
      expect(find.text('Now'), findsOneWidget);
    });

    testWidgets('без фразы (обычная техника) текстов фикра нет',
        (tester) async {
      await tester.pumpWidget(wrap(breathing(phase: PhaseKind.inhale)));
      expect(find.text('I am here'), findsNothing);
    });
  });

  testWidgets('фаза вдоха: подпись, отсчёт и номер цикла', (tester) async {
    await tester.pumpWidget(wrap(breathing(
      phase: PhaseKind.inhale,
      cycleIndex: 0,
      totalCycles: 10,
      phaseElapsedMs: 0,
      phaseDurationMs: 4000,
    )));
    expect(find.text('Inhale'), findsOneWidget);
    expect(find.text('4'), findsOneWidget); // отсчёт секунд фазы
    expect(find.text('1 / 10'), findsOneWidget); // 0-based → 1-based
  });

  testWidgets('задержки обеих фаз подписаны «Hold»', (tester) async {
    await tester.pumpWidget(wrap(breathing(phase: PhaseKind.holdOut)));
    expect(find.text('Hold'), findsOneWidget);
  });

  testWidgets('подготовка: «Get ready» и обратный отсчёт', (tester) async {
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
      phaseIndexInCycle: -1,
    )));
    expect(find.text('Get ready'), findsOneWidget);
    expect(find.text('3'), findsOneWidget); // ceil(2500/1000)
    expect(find.text('—'), findsOneWidget); // цикл не начался
  });

  testWidgets('пауза — тапом по экрану, «Стоп» — кнопкой (влад. 2026-07-16)',
      (tester) async {
    var paused = false;
    var stopped = false;
    await tester.pumpWidget(wrap(
      breathing(),
      onPauseResume: () => paused = true,
      onStop: () => stopped = true,
    ));
    // Растворяющаяся подсказка видна на старте.
    expect(find.text('Tap the screen to pause'), findsOneWidget);
    // Тап по фигуре (любое место экрана) — пауза; кнопки паузы больше нет.
    expect(find.text('Pause'), findsNothing);
    await tester.tap(find.text('Inhale'));
    expect(paused, isTrue);
    expect(stopped, isFalse);
    await tester.tap(find.text('Stop'));
    expect(stopped, isTrue);
    // Дожигаем таймер подсказки (4 c + fade), чтобы тест не ругался.
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('на паузе — пилюля «тап — продолжить», тап снимает паузу',
      (tester) async {
    var resumed = false;
    await tester.pumpWidget(wrap(
      breathing(),
      paused: true,
      onPauseResume: () => resumed = true,
    ));
    expect(find.text('Paused · tap to resume'), findsOneWidget);
    await tester.tap(find.text('Inhale'));
    expect(resumed, isTrue);
  });

  testWidgets('финиш: кнопок нет, тап по кругу закрывает', (tester) async {
    var stopped = false;
    await tester.pumpWidget(wrap(finished, onStop: () => stopped = true));
    expect(find.text('Done'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing); // кнопки исчезли
    // Галочка теперь векторная (единый SessionFinish) — тапаем по заголовку.
    await tester.tap(find.text('Done'));
    expect(stopped, isTrue);
  });

  testWidgets('SessionView с shape=square рендерится без ошибок',
      (tester) async {
    await tester.pumpWidget(wrap(
      breathing(
        phase: PhaseKind.inhale,
        phaseIndexInCycle: 0,
        phaseElapsedMs: 0,
        phaseDurationMs: 4000,
      ),
      shape: VisualShape.square,
    ));
    // Должен отрендериться без исключений; проверяем наличие ключевых виджетов
    expect(find.text('Inhale'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('сегмент элементов: метка и маршрут', (tester) async {
    const seg = BreathSegment(
      id: 'earth',
      cycles: 5,
      inhale: BreathRoute.nose,
      exhale: BreathRoute.nose,
    );
    await tester.pumpWidget(wrap(
      breathing(phase: PhaseKind.inhale),
      segment: seg,
    ));
    // Метка элемента и маршрут вдоха видны
    expect(find.text('Earth'), findsOneWidget);
    expect(find.text('Inhale through the nose'), findsOneWidget);
    // Стандартный «Inhale» без уточнения — не должен присутствовать
    expect(find.text('Inhale'), findsNothing);
  });
}
