/// Синтез «океанского прибоя» для фаз дыхания (спека владельца 2026-07-15).
///
/// Принцип из спеки (Web Audio API) перенесён в наш конвейер пре-рендера —
/// это даёт то же звучание, но синхронизацию ±50 мс по построению и работу
/// с выключенным экраном (веб-аудио в нативном Flutter недоступно, а рантайм-
/// модуляция не нужна: длительности фаз известны до старта):
///
/// * фильтрованный белый шум (one-pole lowpass) — мягкая волна, не шипение;
/// * вдох: громкость растёт 0→пик ВСЮ фазу, срез фильтра 400→1200 Гц —
///   волна «накатывает»; выдох: зеркально спадает — волна «отступает»;
/// * задержки: тихий фон (~12 % пика) без модуляции;
/// * без щелчков: старт каждой фазы — с уровня конца предыдущей (уровни
///   концов детерминированы грамматикой фаз), рампы ≥100 мс.
///
/// Громкость фильтрованного шума компенсируется по стационарной дисперсии
/// one-pole (var = α/(2−α)) — модуляция среза меняет ТЕМБР, а громкость
/// ведёт только огибающая (как в спеке: gain и cutoff — раздельные ручки).
library;

import 'dart:math' as math;
import 'dart:typed_data';

import '../../domain/models/technique.dart';

/// Пик волны (линейная амплитуда, ≈ −9 dBFS).
const double _peak = 0.35;

/// Фон задержек — доля пика (в спеке gain 0.03 при пике 0.25 ≈ 12 %).
const double _holdLevel = 0.12;

/// Уровень (доля пика), на котором фаза [kind] ЗАКАНЧИВАЕТСЯ — с него
/// стартует следующая фаза (непрерывность стыков без знания соседа).
double surfEndLevel(PhaseKind kind) {
  switch (kind) {
    case PhaseKind.inhale:
      return 1.0;
    case PhaseKind.exhale:
      return 0.0;
    case PhaseKind.holdIn:
    case PhaseKind.holdOut:
      return _holdLevel;
  }
}

/// Уровень старта фазы [kind]: конец предыдущей по грамматике техник
/// (…→вдох→[задержка]→выдох→[задержка]→вдох…). Первую фазу сессии и фазу
/// после паузы безопасно начинать с 0 — но вдох после holdOut стартует
/// с фона, а выдох после вдоха — с пика.
double surfStartLevel(PhaseKind kind, PhaseKind? previous) =>
    previous == null ? 0.0 : surfEndLevel(previous);

/// Микширует прибой одной фазы в аккумулятор чанка [acc].
///
/// Фаза занимает сэмплы [phaseStartSample, phaseStartSample+phaseSamples);
/// чанк — [chunkStartSample, chunkStartSample+acc.length). Синтез идёт
/// с начала фазы (IIR-фильтр стейтфул), в acc попадает только пересечение —
/// чанковый рендер длинных сессий даёт побайтово тот же результат, что
/// цельный (шум детерминирован: xorshift32 от сэмпла старта фазы).
void mixSurfPhase({
  required Int32List acc,
  required PhaseKind kind,
  required double startLevel,
  required int phaseStartSample,
  required int phaseSamples,
  required int chunkStartSample,
  required int sampleRate,
}) {
  final chunkEnd = chunkStartSample + acc.length;
  final phaseEnd = phaseStartSample + phaseSamples;
  if (phaseStartSample >= chunkEnd || phaseEnd <= chunkStartSample) return;

  // Траектории громкости (доли пика) и среза по фазе.
  final endLevel = surfEndLevel(kind);
  final rampSamples = math.min(phaseSamples, (0.15 * sampleRate).round());
  final (double fcFrom, double fcTo) = switch (kind) {
    PhaseKind.inhale => (400.0, 1200.0),
    PhaseKind.exhale => (1200.0, 400.0),
    PhaseKind.holdIn || PhaseKind.holdOut => (550.0, 550.0),
  };

  var seed = 0x9E3779B9 ^ phaseStartSample;
  if (seed == 0) seed = 1;
  double lp = 0.0;
  final invSr = 1.0 / sampleRate;
  final n = math.min(phaseSamples, chunkEnd - phaseStartSample);
  for (var i = 0; i < n; i++) {
    // xorshift32 → белый шум [-1, 1).
    seed ^= (seed << 13) & 0xFFFFFFFF;
    seed ^= seed >>> 17;
    seed ^= (seed << 5) & 0xFFFFFFFF;
    final noise = (seed & 0xFFFFFF) / 0x800000 - 1.0;

    final t = i / phaseSamples; // 0..1 по фазе
    final fc = fcFrom + (fcTo - fcFrom) * t;
    final alpha = 1.0 - math.exp(-2.0 * math.pi * fc * invSr);
    lp += alpha * (noise - lp);
    // Компенсация громкости фильтра: var(lp) = α/(2−α) на белом шуме.
    final norm = lp / math.sqrt(alpha / (2.0 - alpha));

    final double level;
    switch (kind) {
      case PhaseKind.inhale:
      case PhaseKind.exhale:
        level = startLevel + (endLevel - startLevel) * t;
      case PhaseKind.holdIn:
      case PhaseKind.holdOut:
        level = i < rampSamples
            ? startLevel + (endLevel - startLevel) * (i / rampSamples)
            : endLevel;
    }

    final global = phaseStartSample + i;
    if (global < chunkStartSample) continue;
    final v = (norm * _peak * level * 32767.0).round();
    acc[global - chunkStartSample] += v;
  }
}
