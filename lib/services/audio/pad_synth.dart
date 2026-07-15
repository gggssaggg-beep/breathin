/// «Поток» — поющий тон, дышащий вместе с фазами (выбор владельца 2026-07-15
/// после прослушки прототипов; шум-прибой отклонён как «сумбурный»).
///
/// Звук: мягкий гармонический тон (5 гармоник с тёплым детюном и лёгким
/// вибрато). На вдохе нота плывёт вверх на квинту (до→соль малой октавы),
/// громкость и яркость растут ВСЮ фазу; на выдохе — зеркально вниз;
/// на задержках тон тихо звенит на достигнутой ноте.
///
/// Без щелчков — двумя механизмами:
/// * громкость: фаза стартует с уровня конца предыдущей (грамматика
///   вдох→[задержка]→выдох→[задержка] делает стыки непрерывными);
/// * сама синусоида: фазовые углы гармоник НЕ сбрасываются на границе —
///   угол конца фазы вычисляется аналитически (интеграл глайда) и передаётся
///   следующей ([PadAngles]), поэтому волна физически непрерывна.
///
/// Синтез детерминирован и чанкуем: значение сэмпла зависит только от
/// позиции внутри фазы и стартовых углов — чанковый рендер часовой сессии
/// побайтово равен цельному.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import '../../domain/models/technique.dart';

/// Ноты глайда: до и соль малой октавы (тёплый низкий регистр).
const double _fLow = 130.81; // C3
const double _fHigh = 196.0; // G3

/// Пик громкости (≈ −10 dBFS) и фон задержек (доля пика).
const double _peak = 0.32;
const double _holdLevel = 0.30;

/// Гармоники: номер, вес 1/k^1.6, детюн ±0.12 % (тёплые биения).
const _harmonics = [1, 2, 3, 4, 5];
List<double> get _weights =>
    [for (final k in _harmonics) 1.0 / math.pow(k, 1.6)];
List<double> get _detunes =>
    [for (final k in _harmonics) k.isOdd ? 1.0012 : 0.9988];

/// Уровень, на котором фаза [kind] заканчивается (старт следующей).
double padEndLevel(PhaseKind kind) {
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

/// Уровень старта фазы: конец предыдущей; первая фаза — с тишины.
double padStartLevel(PhaseKind kind, PhaseKind? previous) =>
    previous == null ? 0.0 : padEndLevel(previous);

/// Частоты глайда фазы: (от, до).
(double, double) _glide(PhaseKind kind) {
  switch (kind) {
    case PhaseKind.inhale:
      return (_fLow, _fHigh);
    case PhaseKind.exhale:
      return (_fHigh, _fLow);
    case PhaseKind.holdIn:
      return (_fHigh, _fHigh); // звенит на верхней ноте
    case PhaseKind.holdOut:
      return (_fLow, _fLow);
  }
}

/// Яркость фазы: (от, до) — гейт высоких гармоник.
(double, double) _brightness(PhaseKind kind) {
  switch (kind) {
    case PhaseKind.inhale:
      return (0.15, 1.0);
    case PhaseKind.exhale:
      return (1.0, 0.15);
    case PhaseKind.holdIn:
    case PhaseKind.holdOut:
      return (0.25, 0.25);
  }
}

/// Интеграл частоты глайда за [samples] сэмплов: Δугол базовой гармоники.
/// Экспоненциальный глайд f(t) = f0·r^(t/T): ∫₀ᵀ f dt = f0·T·(r−1)/ln r.
double _phaseDelta(double f0, double f1, int samples, int sampleRate) {
  final T = samples / sampleRate;
  if (samples <= 0) return 0.0;
  final r = f1 / f0;
  final integral =
      (r - 1.0).abs() < 1e-9 ? f0 * T : f0 * T * (r - 1.0) / math.log(r);
  return 2.0 * math.pi * integral;
}

/// Стартовые фазовые углы гармоник (по одному на гармонику).
typedef PadAngles = List<double>;

/// Нулевые углы начала сессии.
PadAngles padInitialAngles() => List.filled(_harmonics.length, 0.0);

/// Углы в конце фазы [kind] длиной [samples] при стартовых [start] —
/// передаются следующей фазе (непрерывность синусоид на стыке).
PadAngles padEndAngles(
    PadAngles start, PhaseKind kind, int samples, int sampleRate) {
  final (f0, f1) = _glide(kind);
  final base = _phaseDelta(f0, f1, samples, sampleRate);
  return [
    for (var i = 0; i < _harmonics.length; i++)
      start[i] + base * _harmonics[i] * _detunes[i],
  ];
}

/// Микширует «Поток» одной фазы в аккумулятор чанка [acc].
/// Интерфейс идентичен прежнему прибою + стартовые углы гармоник.
void mixPadPhase({
  required Int32List acc,
  required PhaseKind kind,
  required double startLevel,
  required PadAngles startAngles,
  required int phaseStartSample,
  required int phaseSamples,
  required int chunkStartSample,
  required int sampleRate,
}) {
  final chunkEnd = chunkStartSample + acc.length;
  final phaseEnd = phaseStartSample + phaseSamples;
  if (phaseStartSample >= chunkEnd || phaseEnd <= chunkStartSample) return;
  if (phaseSamples <= 0) return;

  final (f0, f1) = _glide(kind);
  final (b0, b1) = _brightness(kind);
  final endLevel = padEndLevel(kind);
  final rampSamples = math.min(phaseSamples, (0.15 * sampleRate).round());
  final weights = _weights;
  final detunes = _detunes;
  final r = f1 / f0;
  final T = phaseSamples / sampleRate;
  final lnR = (r - 1.0).abs() < 1e-9 ? 0.0 : math.log(r);
  final twoPi = 2.0 * math.pi;

  final from = math.max(phaseStartSample, chunkStartSample) - phaseStartSample;
  final to = math.min(phaseEnd, chunkEnd) - phaseStartSample;
  for (var i = from; i < to; i++) {
    final tSec = i / sampleRate;
    final x = i / phaseSamples; // 0..1 по фазе
    // Аналитический угол базовой гармоники в момент t (интеграл глайда) —
    // не зависит от чанка, только от позиции в фазе.
    final baseAngle = lnR == 0.0
        ? twoPi * f0 * tSec
        : twoPi * f0 * (T / lnR) * (math.pow(r, x) - 1.0);
    // Вибрато — АДДИТИВНАЯ фазовая модуляция по глобальному времени сессии:
    // непрерывна между фазами и не трогает аккумулируемые углы (мультипликатор
    // на угле рвал бы стык — углы к концу фазы исчисляются тысячами радиан).
    final tGlobal = (phaseStartSample + i) / sampleRate;
    final vib = 0.35 * math.sin(twoPi * 4.7 * tGlobal);

    final bright = b0 + (b1 - b0) * x;
    var sig = 0.0;
    for (var h = 0; h < _harmonics.length; h++) {
      final k = _harmonics[h];
      // Гейт высоких гармоник от яркости; первая гармоника звучит всегда.
      final gate = (bright * 2.2 - (k - 1) * 0.5).clamp(0.0, 1.0);
      if (gate == 0.0) continue;
      sig += weights[h] *
          gate *
          math.sin(startAngles[h] + baseAngle * k * detunes[h] + vib * k);
    }

    final double level;
    switch (kind) {
      case PhaseKind.inhale:
      case PhaseKind.exhale:
        level = startLevel + (endLevel - startLevel) * x;
      case PhaseKind.holdIn:
      case PhaseKind.holdOut:
        level = i < rampSamples
            ? startLevel + (endLevel - startLevel) * (i / rampSamples)
            : endLevel;
    }

    final v = (sig * _peak * level * 32767.0).round();
    acc[phaseStartSample + i - chunkStartSample] += v;
  }
}
