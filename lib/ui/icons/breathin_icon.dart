import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import 'breathin_icons.dart';

/// Виджет-иконка из набора [BreathinIconData].
///
/// Рисует SVG-пути (viewBox 0 0 24 24) через [CustomPaint] в стиле Tabler:
/// штрих 2/24 от размера, круглые концы и стыки. Цвет — [color] или
/// [IconTheme] (аналог currentColor из веб-подхода RESOURCES_ICONS).
class BreathinIcon extends StatelessWidget {
  final BreathinIconData data;
  final double size;
  final Color? color;

  const BreathinIcon(this.data, {super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? IconTheme.of(context).color ?? Colors.black;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BreathinIconPainter(data: data, color: effectiveColor),
      ),
    );
  }
}

class _BreathinIconPainter extends CustomPainter {
  final BreathinIconData data;
  final Color color;

  // Кэш распарсенных путей: const-данные набора → список Path.
  static final _cache = <BreathinIconData, List<Path>>{};

  _BreathinIconPainter({required this.data, required this.color});

  List<Path> _parsedPaths() => _cache.putIfAbsent(
        data,
        () => data.paths.map(parseSvgPathData).toList(growable: false),
      );

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final scale = canvasSize.shortestSide / 24.0;
    // Толщина задаётся в координатах viewBox (2/24): canvas.scale масштабирует
    // и штрих — задавать её в экранных пикселях нельзя (штрих раздуло бы в
    // scale² раз). visualScale выравнивает оптический вес «худых» иконок
    // (аудит 2026-07-16 §1): растёт фигура, штрих остаётся 2/24 — компенсируем
    // делением strokeWidth.
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 / data.visualScale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    canvas.save();
    canvas.scale(scale, scale);
    if (data.visualScale != 1.0) {
      // Масштаб вокруг центра вьюбокса (12,12).
      canvas.translate(12, 12);
      canvas.scale(data.visualScale, data.visualScale);
      canvas.translate(-12, -12);
    }
    for (final path in _parsedPaths()) {
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BreathinIconPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.color != color;
}
