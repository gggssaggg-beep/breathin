import 'package:flutter/material.dart';

import '../../domain/models/bolt_result.dart';

/// Спарклайн динамики BOLT: линия по последним результатам + точки, с
/// подписью min/max по оси. Свой CustomPainter (без сторонних чарт-пакетов —
/// по образцу BreathingPainter). Показывает до [maxPoints] последних замеров.
class BoltChart extends StatelessWidget {
  final List<BoltResult> results;
  final int maxPoints;

  const BoltChart({super.key, required this.results, this.maxPoints = 30});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = results.length > maxPoints
        ? results.sublist(results.length - maxPoints)
        : results;
    return SizedBox(
      height: 120,
      child: CustomPaint(
        painter: _SparklinePainter(
          seconds: [for (final r in shown) r.seconds],
          line: theme.colorScheme.primary,
          fill: theme.colorScheme.primary.withValues(alpha: 0.12),
          grid: theme.colorScheme.outlineVariant,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<int> seconds;
  final Color line;
  final Color fill;
  final Color grid;

  _SparklinePainter({
    required this.seconds,
    required this.line,
    required this.fill,
    required this.grid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (seconds.isEmpty) return;
    const pad = 8.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;

    // Диапазон значений с небольшим запасом; плоская серия не делится на ноль.
    var lo = seconds.reduce((a, b) => a < b ? a : b).toDouble();
    var hi = seconds.reduce((a, b) => a > b ? a : b).toDouble();
    if (hi - lo < 4) {
      lo -= 2;
      hi += 2;
    }
    lo = lo.clamp(0, double.infinity);
    final span = hi - lo == 0 ? 1.0 : hi - lo;

    double x(int i) => seconds.length == 1
        ? pad + w / 2
        : pad + w * i / (seconds.length - 1);
    double y(int v) => pad + h * (1 - (v - lo) / span);

    // Опорные линии min/max.
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    canvas.drawLine(Offset(pad, pad), Offset(size.width - pad, pad), gridPaint);
    canvas.drawLine(Offset(pad, size.height - pad),
        Offset(size.width - pad, size.height - pad), gridPaint);

    // Заливка под линией.
    final path = Path()..moveTo(x(0), y(seconds[0]));
    for (var i = 1; i < seconds.length; i++) {
      path.lineTo(x(i), y(seconds[i]));
    }
    final area = Path.from(path)
      ..lineTo(x(seconds.length - 1), size.height - pad)
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
    for (var i = 0; i < seconds.length; i++) {
      canvas.drawCircle(Offset(x(i), y(seconds[i])), 3, dot);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.seconds != seconds ||
      old.line != line ||
      old.fill != fill ||
      old.grid != grid;
}
