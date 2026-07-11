import 'package:breathin/domain/catalog/techniques.dart';
import 'package:breathin/domain/engine/phase_engine.dart';
import 'package:breathin/domain/engine/session_plan_compiler.dart';
import 'package:breathin/domain/models/session_config.dart';
import 'package:breathin/domain/models/technique.dart';
import 'package:breathin/features/session/breathing_painter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Классический box: подготовка 3 c, затем циклы 4-4-4-4 (фаза = 4000 мс).
  // Вдох 1-го цикла: 3000..7000, задержка (holdIn): 7000..11000.
  final engine = PhaseEngine(
    const SessionPlanCompiler()
        .compile(boxBreathing, SessionConfig.classic(boxBreathing)),
  );

  group('visualSignature (энергосбережение экрана сессии)', () {
    test('одинаковое время → одинаковая подпись', () {
      expect(
        visualSignature(engine.stateAt(5000), VisualShape.circle),
        visualSignature(engine.stateAt(5000), VisualShape.circle),
      );
    });

    test('круг на задержке: соседние кадры БЕЗ смены секунды не перестраивают',
        () {
      // 7100 и 7300 мс: та же задержка, остаток 4 c, фигура статична.
      final a = visualSignature(engine.stateAt(7100), VisualShape.circle);
      final b = visualSignature(engine.stateAt(7300), VisualShape.circle);
      expect(a, b);
    });

    test('квадрат на задержке: точка движется — подпись меняется', () {
      final a = visualSignature(engine.stateAt(7100), VisualShape.square);
      final b = visualSignature(engine.stateAt(7300), VisualShape.square);
      expect(a, isNot(b));
    });

    test('круг на вдохе: фигура дышит — подпись меняется', () {
      final a = visualSignature(engine.stateAt(3100), VisualShape.circle);
      final b = visualSignature(engine.stateAt(3600), VisualShape.circle);
      expect(a, isNot(b));
    });

    test('задержка: смена секунды отсчёта меняет подпись', () {
      // Остаток 4 c (7100) против 3 c (8100).
      final a = visualSignature(engine.stateAt(7100), VisualShape.circle);
      final b = visualSignature(engine.stateAt(8100), VisualShape.circle);
      expect(a, isNot(b));
    });

    test('подготовка: внутри одной секунды подпись стабильна, между — нет', () {
      final a = visualSignature(engine.stateAt(500), VisualShape.circle);
      final b = visualSignature(engine.stateAt(700), VisualShape.circle);
      final c = visualSignature(engine.stateAt(1600), VisualShape.circle);
      expect(a, b);
      expect(a, isNot(c));
    });

    test('финиш отличим от дыхания', () {
      final total = engine.stateAt(0).sessionDurationMs;
      final a = visualSignature(engine.stateAt(total + 10), VisualShape.circle);
      final b = visualSignature(engine.stateAt(5000), VisualShape.circle);
      expect(a, isNot(b));
    });
  });
}
