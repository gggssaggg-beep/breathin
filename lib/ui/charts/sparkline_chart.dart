import 'package:flutter/material.dart';

/// Спарклайн: линия по последним [maxPoints] значениям + точки, с опорными
/// линиями min/max по краям. Свой CustomPainter (без сторонних чарт-пакетов —
/// по образцу BreathingPainter). Вынесен из [BoltChart] для переиспользования
/// (ПЛАН П19: график задержек Вима Хофа по той же механике).
class SparklineChart extends StatelessWidget {
  final List<int> values;
  final int maxPoints;
  final double height;

  const SparklineChart({
    super.key,
    required this.values,
    this.maxPoints = 30,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = values.length > maxPoints
        ? values.sublist(values.length - maxPoints)
        : values;
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: SparklinePainter(
          values: shown,
          line: theme.colorScheme.primary,
          fill: theme.colorScheme.primary.withValues(alpha: 0.12),
          grid: theme.colorScheme.outlineVariant,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class SparklinePainter extends CustomPainter {
  final List<int> values;
  final Color line;
  final Color fill;
  final Color grid;

  SparklinePainter({
    required this.values,
    required this.line,
    required this.fill,
    required this.grid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const pad = 8.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;

    // Диапазон значений с небольшим запасом; плоская серия не делится на ноль.
    var lo = values.reduce((a, b) => a < b ? a : b).toDouble();
    var hi = values.reduce((a, b) => a > b ? a : b).toDouble();
    if (hi - lo < 4) {
      lo -= 2;
      hi += 2;
    }
    lo = lo.clamp(0, double.infinity);
    final span = hi - lo == 0 ? 1.0 : hi - lo;

    double x(int i) => values.length == 1
        ? pad + w / 2
        : pad + w * i / (values.length - 1);
    double y(int v) => pad + h * (1 - (v - lo) / span);

    // Опорные линии min/max.
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    canvas.drawLine(Offset(pad, pad), Offset(size.width - pad, pad), gridPaint);
    canvas.drawLine(Offset(pad, size.height - pad),
        Offset(size.width - pad, size.height - pad), gridPaint);

    // Заливка под линией.
    final path = Path()..moveTo(x(0), y(values[0]));
    for (var i = 1; i < values.length; i++) {
      path.lineTo(x(i), y(values[i]));
    }
    final area = Path.from(path)
      ..lineTo(x(values.length - 1), size.height - pad)
      ..lineTo(x(0), size.height - pad)
      ..close();
    canvas.drawPath(area, Paint()..color = fill);

    // Линия.
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Точки.
    final dot = Paint()..color = line;
    for (var i = 0; i < values.length; i++) {
      canvas.drawCircle(Offset(x(i), y(values[i])), 3, dot);
    }
  }

  @override
  bool shouldRepaint(SparklinePainter old) =>
      old.values != values ||
      old.line != line ||
      old.fill != fill ||
      old.grid != grid;
}
