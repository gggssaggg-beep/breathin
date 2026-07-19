import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breathin/domain/engine/phase_engine.dart';
import 'package:breathin/domain/models/technique.dart';
import 'package:breathin/features/session/breathing_painter.dart';
import 'package:breathin/features/session/session_view.dart';
import 'package:breathin/l10n/generated/app_localizations.dart';

/// Вспомогательная фабрика SessionState для тестов.
SessionState _makeState({
  SessionStage stage = SessionStage.breathing,
  PhaseKind? phase = PhaseKind.inhale,
  int phaseIndexInCycle = 0,
  int phaseElapsedMs = 0,
  int phaseDurationMs = 4000,
  int cycleIndex = 0,
  int totalCycles = 4,
}) =>
    SessionState(
      stage: stage,
      phase: phase,
      cycleIndex: cycleIndex,
      totalCycles: totalCycles,
      phaseElapsedMs: phaseElapsedMs,
      phaseDurationMs: phaseDurationMs,
      prepRemainingMs: 0,
      sessionElapsedMs: 0,
      sessionDurationMs: 64000,
      phaseIndexInCycle: phaseIndexInCycle,
    );

void main() {
  group('dotPosition — квадрат', () {
    const size = 200.0;

    test('phaseIndex=0, progress=0 → левый нижний угол', () {
      final pos = dotPosition(
        shape: VisualShape.square,
        phaseCount: 4,
        phaseIndex: 0,
        progress: 0.0,
        size: size,
      );
      expect(pos.dx, closeTo(0, 1e-9));
      expect(pos.dy, closeTo(size, 1e-9));
    });

    test('phaseIndex=0, progress=1 → левый верхний угол', () {
      final pos = dotPosition(
        shape: VisualShape.square,
        phaseCount: 4,
        phaseIndex: 0,
        progress: 1.0,
        size: size,
      );
      expect(pos.dx, closeTo(0, 1e-9));
      expect(pos.dy, closeTo(0, 1e-9));
    });

    test('phaseIndex=1, progress=0 → левый верхний угол', () {
      final pos = dotPosition(
        shape: VisualShape.square,
        phaseCount: 4,
        phaseIndex: 1,
        progress: 0.0,
        size: size,
      );
      expect(pos.dx, closeTo(0, 1e-9));
      expect(pos.dy, closeTo(0, 1e-9));
    });

    test('phaseIndex=1, progress=1 → правый верхний угол', () {
      final pos = dotPosition(
        shape: VisualShape.square,
        phaseCount: 4,
        phaseIndex: 1,
        progress: 1.0,
        size: size,
      );
      expect(pos.dx, closeTo(size, 1e-9));
      expect(pos.dy, closeTo(0, 1e-9));
    });

    test('phaseIndex=2, progress=0.5 → середина правой стороны', () {
      final pos = dotPosition(
        shape: VisualShape.square,
        phaseCount: 4,
        phaseIndex: 2,
        progress: 0.5,
        size: size,
      );
      expect(pos.dx, closeTo(size, 1e-9));
      expect(pos.dy, closeTo(size / 2, 1e-9));
    });

    test('phaseIndex=-1 (prep) → левый нижний угол (стартовая позиция)', () {
      final pos = dotPosition(
        shape: VisualShape.square,
        phaseCount: 4,
        phaseIndex: -1,
        progress: 0.0,
        size: size,
      );
      expect(pos.dx, closeTo(0, 1e-9));
      expect(pos.dy, closeTo(size, 1e-9));
    });
  });

  group('dotPosition — треугольник', () {
    const size = 200.0;

    // Основание вверху (влад. 2026-07-19): вдох — подъём по левому ребру,
    // задержка — горизонталь по верхнему основанию, выдох — спуск к нижней
    // вершине.
    test('phaseIndex=0, progress=0 → нижняя вершина (старт)', () {
      final pos = dotPosition(
        shape: VisualShape.triangle,
        phaseCount: 3,
        phaseIndex: 0,
        progress: 0.0,
        size: size,
      );
      expect(pos.dx, closeTo(size / 2, 1e-9));
      expect(pos.dy, closeTo(size, 1e-9));
    });

    test('phaseIndex=0 (вдох), progress=1 → левый верхний', () {
      final pos = dotPosition(
        shape: VisualShape.triangle,
        phaseCount: 3,
        phaseIndex: 0,
        progress: 1.0,
        size: size,
      );
      expect(pos.dx, closeTo(0, 1e-9));
      expect(pos.dy, closeTo(0, 1e-9));
    });

    test('phaseIndex=1 (задержка), progress=1 → правый верхний', () {
      final pos = dotPosition(
        shape: VisualShape.triangle,
        phaseCount: 3,
        phaseIndex: 1,
        progress: 1.0,
        size: size,
      );
      expect(pos.dx, closeTo(size, 1e-9));
      expect(pos.dy, closeTo(0, 1e-9));
    });

    test('phaseIndex=2 (выдох), progress=1 → возврат в нижнюю вершину', () {
      final pos = dotPosition(
        shape: VisualShape.triangle,
        phaseCount: 3,
        phaseIndex: 2,
        progress: 1.0,
        size: size,
      );
      expect(pos.dx, closeTo(size / 2, 1e-9));
      expect(pos.dy, closeTo(size, 1e-9));
    });
  });

  group('breathFraction', () {
    test('вдох: прогресс 0.5 → fraction 0.5', () {
      final s = _makeState(phase: PhaseKind.inhale, phaseElapsedMs: 2000);
      expect(breathFraction(s), closeTo(0.5, 1e-9));
    });

    test('выдох: прогресс 0.5 → fraction 0.5 (инвертированный)', () {
      final s = _makeState(phase: PhaseKind.exhale, phaseElapsedMs: 2000);
      expect(breathFraction(s), closeTo(0.5, 1e-9));
    });

    test('holdIn → fraction 1.0', () {
      final s = _makeState(phase: PhaseKind.holdIn);
      expect(breathFraction(s), closeTo(1.0, 1e-9));
    });

    test('holdOut → fraction 0.0', () {
      final s = _makeState(phase: PhaseKind.holdOut);
      expect(breathFraction(s), closeTo(0.0, 1e-9));
    });

    test('prep (phase=null) → fraction 0.35', () {
      final s = _makeState(
        stage: SessionStage.prep,
        phase: null,
        phaseIndexInCycle: -1,
      );
      expect(breathFraction(s), closeTo(0.35, 1e-9));
    });
  });

  group('SessionView с shape=square — виджет-тест', () {
    testWidgets('рендерится без ошибок', (tester) async {
      final state = _makeState(
        phase: PhaseKind.inhale,
        phaseIndexInCycle: 0,
        phaseElapsedMs: 0,
        phaseDurationMs: 4000,
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SessionView(
            state: state,
            shape: VisualShape.square,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      // Локаль тестов — en (SessionView теперь берёт подписи из l10n).
      expect(find.text('Inhale'), findsOneWidget);
    });

    testWidgets('triangle рендерится без ошибок', (tester) async {
      final state = _makeState(
        phase: PhaseKind.inhale,
        phaseIndexInCycle: 0,
        totalCycles: 3,
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SessionView(
            state: state,
            shape: VisualShape.triangle,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
