import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/hant_theme.dart';

/// Фон-«чертёж» темы HANT: едва различимая сетка + разреженные звёзды
/// (циановые и редкие янтарные). В классической теме прозрачно возвращает
/// child. Полностью статичен — без анимаций и blur (дёшево для GPU/батареи).
class HantBackdrop extends StatelessWidget {
  final Widget child;

  const HantBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final hant = Theme.of(context).extension<HantStyle>();
    if (hant == null) return child;
    return CustomPaint(
      painter: _BackdropPainter(hant),
      child: child,
    );
  }
}

class _BackdropPainter extends CustomPainter {
  final HantStyle style;

  const _BackdropPainter(this.style);

  @override
  void paint(Canvas canvas, Size size) {
    // Сетка-чертёж: шаг 72, толщина 1 — как миллиметровка приборной панели.
    final gridPaint = Paint()
      ..color = style.grid.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    const step = 72.0;
    for (var x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Звёзды: детерминированный сид — рисунок неба стабилен между кадрами.
    final rnd = Random(7);
    final wireStar = Paint()..color = style.wire.withValues(alpha: 0.45);
    final sourceStar = Paint()..color = style.source.withValues(alpha: 0.55);
    const count = 54;
    for (var i = 0; i < count; i++) {
      final p = Offset(
        rnd.nextDouble() * size.width,
        rnd.nextDouble() * size.height,
      );
      final r = 0.7 + rnd.nextDouble() * 0.9;
      // Каждая девятая звезда — янтарная (как точки-акценты референсов).
      canvas.drawCircle(p, r, i % 9 == 0 ? sourceStar : wireStar);
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) =>
      oldDelegate.style != style;
}
