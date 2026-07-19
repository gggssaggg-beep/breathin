import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/hant_theme.dart';
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
/// Для треугольника (равносторонний ОСНОВАНИЕМ ВВЕРХ, 3 фазы; влад.
/// 2026-07-19: задержка — горизонталь, а не ребро вниз):
///   Старт — нижняя вершина.
///   Фаза 0: подъём по левому ребру к левому верхнему углу (вдох).
///   Фаза 1: горизонтально по верхнему основанию (задержка).
///   Фаза 2: спуск по правому ребру к нижней вершине (выдох).
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

/// Позиция точки на периметре равностороннего треугольника ОСНОВАНИЕМ ВВЕРХ
/// (влад. 2026-07-19: вдох — подъём, задержка — горизонталь, выдох — спуск;
/// раньше вершина была сверху и задержка шла ребром вниз — нелогично).
/// Стартовая точка — нижняя вершина.
/// Фаза 0: подъём по левому ребру (вдох).
/// Фаза 1: горизонтально по верхнему основанию (задержка).
/// Фаза 2: спуск по правому ребру (выдох).
Offset _triangleDotPosition({
  required int phaseIndex,
  required double progress,
  required double size,
}) {
  // Равносторонний треугольник, вписанный в квадрат size×size:
  // нижняя вершина: (size/2, size)
  // левый верхний: (0, 0)
  // правый верхний: (size, 0)
  final bottom = Offset(size / 2, size);
  final topLeft = Offset(0, 0);
  final topRight = Offset(size, 0);

  final corners = [
    bottom,   // старт
    topLeft,  // после фазы 0 (вдох поднялся)
    topRight, // после фазы 1 (задержка прошла по основанию)
    bottom,   // после фазы 2 (выдох спустился, замыкаем)
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

  /// Токены HANT: не null → фигура рисуется как калибровочный прицел
  /// (орбитальное кольцо с делениями, уголки-скобки, янтарное ядро-«источник»).
  final HantStyle? hant;

  const BreathingPainter({
    required this.shape,
    required this.state,
    required this.primary,
    required this.outline,
    this.hant,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final h = hant;
    if (h != null) _paintReticle(canvas, size, h);
    switch (shape) {
      case VisualShape.circle:
        _paintCircle(canvas, size);
      case VisualShape.square:
        _paintSquare(canvas, size);
      case VisualShape.triangle:
        _paintTriangle(canvas, size);
    }
  }

  /// Статичная HUD-обвязка HANT (не зависит от фазы — visualSignature
  /// не меняется): уголки-скобки по углам поля, для круга — орбитальное
  /// кольцо с делениями шкалы, как рамки калибровки на референсах.
  void _paintReticle(Canvas canvas, Size size, HantStyle h) {
    final bracket = Paint()
      ..color = h.wire.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    const len = 16.0;
    final w = size.width;
    final hgt = size.height;
    // Четыре уголка-скобки [ ] по углам поля фигуры.
    for (final (corner, dx, dy) in [
      (Offset.zero, 1.0, 1.0),
      (Offset(w, 0), -1.0, 1.0),
      (Offset(0, hgt), 1.0, -1.0),
      (Offset(w, hgt), -1.0, -1.0),
    ]) {
      canvas.drawLine(corner, corner + Offset(dx * len, 0), bracket);
      canvas.drawLine(corner, corner + Offset(0, dy * len), bracket);
    }

    if (shape != VisualShape.circle) return;
    final center = Offset(w / 2, hgt / 2);
    final orbitR = size.shortestSide * 0.47;
    final orbit = Paint()
      ..color = h.wireDim.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, orbitR, orbit);
    // Деления шкалы: 36 коротких, каждое девятое (кардинальное) — длиннее
    // и ярче.
    for (var i = 0; i < 36; i++) {
      final a = i * pi / 18;
      final cardinal = i % 9 == 0;
      final tick = Paint()
        ..color = cardinal ? h.wire : h.wireDim
        ..strokeWidth = 1;
      final from = center + Offset(cos(a), sin(a)) * orbitR;
      final to =
          center + Offset(cos(a), sin(a)) * (orbitR - (cardinal ? 7 : 4));
      canvas.drawLine(from, to, tick);
    }
  }

  void _paintCircle(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final minR = size.shortestSide * 0.25;
    final maxR = size.shortestSide * 0.45;
    final fraction = breathFraction(state);
    final r = minR + (maxR - minR) * fraction;

    final h = hant;
    if (h != null) {
      // HANT: дышащий круг — «источник»: янтарное ядро-свечение внутри
      // тонкого проволочного контура (по референсу «ИСТОЧНИК» с орбитами).
      final glow = Paint()
        ..shader = RadialGradient(
          colors: [
            h.sourceGlow.withValues(alpha: 0.55),
            h.source.withValues(alpha: 0.18),
            h.source.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: r));
      canvas.drawCircle(center, r, glow);
      final wire = Paint()
        ..color = h.wire
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, r, wire);
      canvas.drawCircle(center, 5, Paint()..color = h.source);
      return;
    }

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

    // Вершины: основание вверху, вершина внизу (влад. 2026-07-19 —
    // геометрия согласована с маршрутом точки: вдох-подъём/задержка-
    // горизонталь/выдох-спуск).
    final bottom = Offset(left + triSize / 2, top + triSize);
    final topLeft = Offset(left, top);
    final topRight = Offset(left + triSize, top);

    final path = Path()
      ..moveTo(bottom.dx, bottom.dy)
      ..lineTo(topLeft.dx, topLeft.dy)
      ..lineTo(topRight.dx, topRight.dy)
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
        oldDelegate.outline != outline ||
        oldDelegate.hant != hant;
  }
}
