/// Глобальные пресеты сложности (эпик персонализации §4–5). Множитель на
/// классические длительности фаз counted-техник: мягче — короче, труднее —
/// длиннее (напр. box 4→~6 на «Волне»). «Своё дыхание» берёт множитель из
/// последнего результата BOLT (авто-сложность от характеристик, §4).
///
/// Нейминг в тему бренда: Штиль · Бриз · Волна · Прибой (+ Своё дыхание).
library;

import '../bolt/bolt_interpretation.dart';
import '../models/technique.dart';

enum DifficultyPreset {
  /// Штиль — самый мягкий (короче фазы).
  calm,

  /// Бриз — классический дефолт (×1.0).
  breeze,

  /// Волна — заметно длиннее.
  wave,

  /// Прибой — самый трудный.
  tide,

  /// Своё дыхание — множитель из уровня BOLT (или бриз, если теста не было).
  mine,
}

/// Базовый множитель пресета (для [DifficultyPreset.mine] — см.
/// [difficultyMultiplier], зависит от BOLT).
const Map<DifficultyPreset, double> _baseMultiplier = {
  DifficultyPreset.calm: 0.7,
  DifficultyPreset.breeze: 1.0,
  DifficultyPreset.wave: 1.3,
  DifficultyPreset.tide: 1.6,
};

/// Множитель длительностей для пресета. Для «Своего дыхания» выводится из
/// [boltLevel]: чем выше толерантность к CO₂, тем длиннее комфортные фазы.
/// Без результата BOLT «Своё» деградирует к бризу (×1.0).
double difficultyMultiplier(DifficultyPreset preset, {BoltLevel? boltLevel}) {
  if (preset != DifficultyPreset.mine) return _baseMultiplier[preset]!;
  switch (boltLevel) {
    case null:
      return 1.0;
    case BoltLevel.low:
      return 0.7;
    case BoltLevel.medium:
      return 1.0;
    case BoltLevel.high:
      return 1.3;
    case BoltLevel.veryHigh:
      return 1.6;
  }
}

/// Длительности фаз с применённым множителем, клэмп в [PhaseSpec.min/max] и
/// округление к шагу слайдера 0.5 c (ТЗ §3.2). Пресет масштабирует ТОЛЬКО
/// counted-техники со свободными фазами: у tempoMultiplier (4-7-8) фазы
/// нередактируемы, у timer/wimHof/scripted их нет — им возвращаем классику.
List<double> presetPhaseSeconds(Technique t, double multiplier) {
  final phases = t.defaultPhases;
  if (phases == null ||
      t.type != TechniqueType.counted ||
      t.scaling == ScalingMode.tempoMultiplier) {
    // Нечего масштабировать — классические дефолты.
    return (phases ?? const []).map((p) => p.defaultSec).toList();
  }
  return [
    for (final p in phases)
      (((p.defaultSec * multiplier) * 2).round() / 2)
          .clamp(p.minSec, p.maxSec),
  ];
}

/// Применим ли пресет к технике визуально (стоит ли показывать множитель).
bool presetAffects(Technique t) =>
    t.type == TechniqueType.counted &&
    t.scaling != ScalingMode.tempoMultiplier &&
    t.defaultPhases != null;
