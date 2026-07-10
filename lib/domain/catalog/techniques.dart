import '../models/technique.dart';

/// Квадратное дыхание 4-4-4-4 (ТЗ §2.1) — первая техника вертикального
/// среза №1. Визуализация — квадрат; все фазы настраиваются 2–10 с.
const boxBreathing = Technique(
  id: 'box',
  type: TechniqueType.counted,
  defaultCycles: 10,
  phases: [
    PhaseSpec(kind: PhaseKind.inhale, defaultSec: 4),
    PhaseSpec(kind: PhaseKind.holdIn, defaultSec: 4),
    PhaseSpec(kind: PhaseKind.exhale, defaultSec: 4),
    PhaseSpec(kind: PhaseKind.holdOut, defaultSec: 4),
  ],
);

/// Каталог MVP. В срезе №1 — только box; остальные 11 техник добавляются в П6
/// (см. ПЛАН §5.2, §9).
const List<Technique> catalog = [boxBreathing];

/// Поиск техники по id; бросает [ArgumentError], если id неизвестен.
Technique techniqueById(String id) => catalog.firstWhere(
      (t) => t.id == id,
      orElse: () => throw ArgumentError('Неизвестная техника: $id'),
    );
