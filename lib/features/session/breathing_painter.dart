import 'package:flutter/material.dart';

import '../../domain/engine/phase_engine.dart';
import '../../domain/models/technique.dart';

/// Вычисляет долю «раздутости» фигуры (breathFraction) из текущего состояния.
/// 0.0 — минимум, 1.0 — максимум.
double breathFraction(SessionState state) {
  return switch (state.phase) {
    PhaseKind.inhale => state.phaseProgress,
    PhaseKind.exhale => 1.0 - state.phaseProgress,
    PhaseKind.holdIn => 1.0,
    PhaseKind.holdOut => 0.0,
    null => 0.35, // prep / finished
  };
}

/// «Визуальная подпись» кадра: всё, что реально видно на экране сессии,
/// сведённое к сравнимому значению (record). Если подпись не изменилась —
/// кадр можно НЕ перестраивать.
///
/// Энергосбережение: тикер идёт 60 Гц, но у круга на задержках фигура
/// статична (breathFraction константен), на подготовке меняется лишь цифра
/// раз в секунду — без подписи экран перестраивался бы 60 раз/с всю сессию.
/// Непрерывный прогресс квантуется до подпиксельного шага (движение точки
/// и «дыхание» круга остаются гладкими):
/// * фигура — 1/512 фазы (~0.5 px на стороне 230 px);
/// * прогресс-бар — 1/200 сессии (~2 px на всю ширину).
Object visualSignature(SessionState s, VisualShape shape) {
  final int figureQ;
  if (shape == VisualShape.circle) {
    // Круг зависит только от breathFraction: на задержках он константен.
    figureQ = (breathFraction(s) * 512).round();
  } else {
    // Точка на периметре движется в каждой фазе, включая задержки.
    figureQ = s.phase == null ? -1 : (s.phaseProgress * 512).round();
  }
  final barQ = s.sessionDurationMs <= 0
      ? 0
      : 200 * s.sessionElapsedMs ~/ s.sessionDurationMs;
  return (
    s.stage,
    s.phase,
    s.phaseIndexInCycle,
    s.cycleIndex,
    (s.prepRemainingMs / 1000).ceil(),
    s.phaseRemainingSec,
    figureQ,
    barQ,
  );
}

/// Возвращает позицию точки на периметре скруглённого квадрата/треугольника.
///
/// [shape] — фигура (square или triangle).
/// [phaseCount] — число фаз в цикле (обычно 3 или 4).
/// [phaseIndex] — текущий индекс фазы (0-based; -1 → стартовая позиция).
/// [progress] — прогресс фазы 0..1.
/// [size] — размер описывающего квадрата (стороны фигуры вписаны в этот квадрат).
///
/// Для квадрата:
///   Стартовая точка — левый нижний угол.
///   Обход по часовой: вверх по левой стороне (вдох), вправо по верхней,
///   вниз по правой, влево по нижней.
///
/// Для треугольника (равносторонний вершиной вверх, 3 фазы):
///   Старт — левый нижний угол.
///   Фаза 0: вверх к вершине (вдох).
///   Фаза 1: вниз к правому нижнему (задержка).
///   Фаза 2: влево по основанию (выдох).
Offset dotPosition({
  required VisualShape shape,
  required int phaseCount,
  required int phaseIndex,
  required double progress,
  required double size,
}) {
  if (shape == VisualShape.square) {
    return _squareDotPosition(
      phaseCount: phaseCount,
      phaseIndex: phaseIndex,
      progress: progress,
      size: size,
    );
  }
  if (shape == VisualShape.triangle) {
    return _triangleDotPosition(
      phaseIndex: phaseIndex,
      progress: progress,
      size: size,
    );
  }
  // circle: возвращаем центр (точка не нужна)
  return Offset(size / 2, size / 2);
}

/// Позиция точки на периметре квадрата.
Offset _squareDotPosition({
  required int phaseCount,
  required int phaseIndex,
  required double progress,
  required double size,
}) {
  // Квадрат: левый нижний угол (0, size), обход по часовой:
  // сторона 0: вверх по левой — (0, size) → (0, 0)
  // сторона 1: вправо по верхней — (0, 0) → (size, 0)
  // сторона 2: вниз по правой — (size, 0) → (size, size)
  // сторона 3: влево по нижней — (size, size) → (0, size)
  //
  // Если phaseCount < 4, стороны делятся на phaseCount сегментов.
  // В задании для 4 фаз — 4 стороны, 1 сторона = 1 фаза.

  final sides = phaseCount.clamp(1, 4);

  // Вершины по часовой, старт левый нижний:
  final corners = [
    Offset(0, size),    // левый нижний
    Offset(0, 0),       // левый верхний
    Offset(size, 0),    // правый верхний
    Offset(size, size), // правый нижний
    Offset(0, size),    // левый нижний (замыкаем)
  ];

  if (phaseIndex < 0) {
    // prep / finished → стартовая точка
    return corners[0];
  }

  // Делим периметр на sides частей, каждая фаза проходит одну часть
  final segCount = sides;
  final segIdx = phaseIndex % segCount;
  final t = progress.clamp(0.0, 1.0);

  final start = corners[segIdx];
  final end = corners[segIdx + 1];
  return Offset(
    start.dx + (end.dx - start.dx) * t,
    start.dy + (end.dy - start.dy) * t,
  );
}

/// Позиция точки на периметре равностороннего треугольника (вершиной вверх).
/// Стартовая точка — левый нижний угол.
/// Фаза 0: вверх к вершине (вдох).
/// Фаза 1: вниз к правому нижнему (задержка).
/// Фаза 2: влево по основанию (выдох).
Offset _triangleDotPosition({
  required int phaseIndex,
  required double progress,
  required double size,
}) {
  // Равносторонний треугольник, вписанный в квадрат size×size:
  // вершина верхняя: (size/2, 0)
  // левый нижний: (0, size)
  // правый нижний: (size, size)
  final top = Offset(size / 2, 0);
  final bottomLeft = Offset(0, size);
  final bottomRight = Offset(size, size);

  final corners = [
    bottomLeft,  // старт
    top,         // после фазы 0
    bottomRight, // после фазы 1
    bottomLeft,  // после фазы 2 (замыкаем)
  ];

  if (phaseIndex < 0) {
    return corners[0];
  }

  final segIdx = phaseIndex.clamp(0, 2);
  final t = progress.clamp(0.0, 1.0);

  final start = corners[segIdx];
  final end = corners[segIdx + 1];
  return Offset(
    start.dx + (end.dx - start.dx) * t,
    start.dy + (end.dy - start.dy) * t,
  );
}

/// CustomPainter для дыхательной фигуры (ТЗ §3.3, ПЛАН §9 П9).
///
/// Поддерживает три режима:
/// - [VisualShape.circle]: расширяющийся/сжимающийся круг.
/// - [VisualShape.square]: статичный контур скруглённого квадрата +
///   движущаяся точка по периметру.
/// - [VisualShape.triangle]: равносторонний треугольник + движущаяся точка.
class BreathingPainter extends CustomPainter {
  final VisualShape shape;
  final SessionState state;
  final Color primary;
  final Color outline;

  const BreathingPainter({
    required this.shape,
    required this.state,
    required this.primary,
    required this.outline,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (shape) {
      case VisualShape.circle:
        _paintCircle(canvas, size);
      case VisualShape.square:
        _paintSquare(canvas, size);
      case VisualShape.triangle:
        _paintTriangle(canvas, size);
    }
  }

  void _paintCircle(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final minR = size.shortestSide * 0.25;
    final maxR = size.shortestSide * 0.45;
    final fraction = breathFraction(state);
    final r = minR + (maxR - minR) * fraction;

    // Мягкая заливка
    final fillPaint = Paint()
      ..color = primary.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, r, fillPaint);

    // Контур
    final strokePaint = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, r, strokePaint);
  }

  void _paintSquare(Canvas canvas, Size size) {
    final padding = size.shortestSide * 0.12;
    final squareSize = size.shortestSide - padding * 2;
    final left = (size.width - squareSize) / 2;
    final top = (size.height - squareSize) / 2;
    final rect = Rect.fromLTWH(left, top, squareSize, squareSize);
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(16));

    // Статичный контур
    final strokePaint = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(rRect, strokePaint);

    // Движущаяся точка
    // Число сторон = число фаз в цикле (берём из phaseIndexInCycle — косвенно
    // через кол-во phaseStart на цикл; используем 4 как дефолт для квадрата).
    // Для удобства передаём phaseCount=4, это соответствует box-breathing.
    // Реальный phaseCount выводится по state внутри runner (4 фаз → 4 стороны).
    const phaseCount = 4;
    final dotPos = dotPosition(
      shape: VisualShape.square,
      phaseCount: phaseCount,
      phaseIndex: state.phaseIndexInCycle,
      progress: state.phaseProgress,
      size: squareSize,
    );

    final dotPaint = Paint()
      ..color = primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(left + dotPos.dx, top + dotPos.dy),
      6,
      dotPaint,
    );
  }

  void _paintTriangle(Canvas canvas, Size size) {
    final padding = size.shortestSide * 0.1;
    final triSize = size.shortestSide - padding * 2;
    final left = (size.width - triSize) / 2;
    final top = (size.height - triSize) / 2;

    // Вершины: вершина вверху, основание внизу
    final apex = Offset(left + triSize / 2, top);
    final bottomLeft = Offset(left, top + triSize);
    final bottomRight = Offset(left + triSize, top + triSize);

    final path = Path()
      ..moveTo(apex.dx, apex.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..close();

    // Статичный контур
    final strokePaint = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);

    // Движущаяся точка
    final dotPos = dotPosition(
      shape: VisualShape.triangle,
      phaseCount: 3,
      phaseIndex: state.phaseIndexInCycle,
      progress: state.phaseProgress,
      size: triSize,
    );

    final dotPaint = Paint()
      ..color = primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(left + dotPos.dx, top + dotPos.dy),
      6,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(BreathingPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.shape != shape ||
        oldDelegate.primary != primary ||
        oldDelegate.outline != outline;
  }
}
