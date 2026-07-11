import '../models/technique.dart';
import '../models/technique_settings.dart';

/// Логика слайдеров длительностей фаз (ТЗ §3.2, ПЛАН §5.1): применение
/// изменения одной фазы к полному списку с учётом режима масштабирования
/// техники. Чистый Dart, без побочных эффектов.
///
/// Шаг слайдера — 0.5 с; все результаты квантуются к нему.
const double sliderStepSec = 0.5;

/// Спецификации фаз, действующие для текущего режима 4-16-8
/// (упрощённый 4-8-8 или полный).
List<PhaseSpec> activeSpecs(Technique t, TechniqueSettings s) {
  if (s.useSimplified && t.simplifiedPhases != null) {
    return t.simplifiedPhases!;
  }
  return t.phases ?? const [];
}

/// Длительности по умолчанию для текущего режима — то, что даёт
/// «Сбросить к классике».
List<double> classicSeconds(Technique t, TechniqueSettings s) =>
    activeSpecs(t, s).map((p) => p.defaultSec).toList();

double _quantize(double sec) => (sec / sliderStepSec).round() * sliderStepSec;

double _clampToSpec(double sec, PhaseSpec spec) =>
    sec.clamp(spec.minSec, spec.maxSec);

/// Применяет изменение фазы [index] → [newSec] к списку длительностей.
///
/// * [ScalingMode.perPhase] — меняется только одна фаза (клэмп в диапазон).
/// * [ScalingMode.ratioLock] — пропорция из дефолтов держится всегда:
///   изменение любой фазы масштабирует все; общий масштаб клэмпится так,
///   чтобы каждая фаза осталась в своём диапазоне (пропорция не ломается).
/// * [ScalingMode.ratioOptional] — как ratioLock при `keepRatio`, иначе
///   как perPhase.
/// * [ScalingMode.tempoMultiplier] — фазы нередактируемы; возвращается
///   список без изменений (темп меняется отдельным параметром).
List<double> applyPhaseChange(
  Technique t,
  TechniqueSettings s,
  int index,
  double newSec,
) {
  final specs = activeSpecs(t, s);
  if (index < 0 || index >= specs.length) {
    throw RangeError.index(index, specs, 'index');
  }

  switch (t.scaling) {
    case ScalingMode.tempoMultiplier:
      return List.of(s.phaseSeconds);

    case ScalingMode.perPhase:
    case null:
      return _perPhase(specs, s.phaseSeconds, index, newSec);

    case ScalingMode.ratioOptional:
      if (!s.keepRatio) {
        return _perPhase(specs, s.phaseSeconds, index, newSec);
      }
      return _ratioScaled(specs, index, newSec);

    case ScalingMode.ratioLock:
      return _ratioScaled(specs, index, newSec);
  }
}

List<double> _perPhase(
  List<PhaseSpec> specs,
  List<double> current,
  int index,
  double newSec,
) {
  final result = List.of(current);
  result[index] = _clampToSpec(_quantize(newSec), specs[index]);
  return result;
}

List<double> _ratioScaled(List<PhaseSpec> specs, int index, double newSec) {
  // Масштаб относительно дефолтной пропорции; границы масштаба — пересечение
  // ограничений всех фаз, поэтому пропорция сохраняется точно.
  var minScale = double.negativeInfinity;
  var maxScale = double.infinity;
  for (final spec in specs) {
    final lo = spec.minSec / spec.defaultSec;
    final hi = spec.maxSec / spec.defaultSec;
    if (lo > minScale) minScale = lo;
    if (hi < maxScale) maxScale = hi;
  }
  final def = specs[index].defaultSec;
  final scale = (newSec / def).clamp(minScale, maxScale);
  // К шагу слайдера квантуется только изменяемая фаза (в ratio-режимах слайдер
  // один — база); производные фазы считаются точно по пропорции, иначе
  // независимое округление ломает соотношение (напр., 1:4:2 → 4.5:17.5:9).
  final quantScale =
      (_quantize(def * scale) / def).clamp(minScale, maxScale);
  return specs
      .map((spec) => spec.defaultSec * quantScale)
      .toList(growable: false);
}

/// Клэмп числа циклов (ТЗ §3.1: 1..100).
int clampCycles(int cycles) => cycles.clamp(1, 100);

/// Клэмп таймера в минутах: 1..60, для timer-техник — их собственный
/// диапазон (обычно 1..30, ТЗ §3.1/§2.2).
int clampTimerMinutes(Technique t, int minutes) =>
    minutes.clamp(t.minTimerMin ?? 1, t.maxTimerMin ?? 60);

/// Клэмп подготовительного отсчёта (ТЗ §3.4: 3–5 с).
int clampPrepSeconds(int seconds) => seconds.clamp(3, 5);

/// Переключение режима 4-16-8 «упрощённый/полный»: длительности
/// сбрасываются к дефолтам нового режима (диапазоны фаз различаются).
TechniqueSettings switchSimplified(
  Technique t,
  TechniqueSettings s,
  bool useSimplified,
) {
  if (t.simplifiedPhases == null || s.useSimplified == useSimplified) {
    return s;
  }
  final next = s.copyWith(useSimplified: useSimplified);
  return next.copyWith(phaseSeconds: classicSeconds(t, next));
}
