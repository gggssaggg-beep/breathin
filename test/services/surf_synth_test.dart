import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:breathin/domain/models/technique.dart';
import 'package:breathin/services/audio/sound_bank_loader.dart';
import 'package:breathin/services/audio/surf_synth.dart';
import 'package:breathin/services/audio/timeline_renderer.dart';

const sr = 44100;

Int32List synthPhase(PhaseKind kind, int durMs,
    {double startLevel = 0.0, int chunkStart = 0, int? chunkLen}) {
  final samples = (durMs * sr / 1000).round();
  final acc = Int32List(chunkLen ?? samples);
  mixSurfPhase(
    acc: acc,
    kind: kind,
    startLevel: startLevel,
    phaseStartSample: 0,
    phaseSamples: samples,
    chunkStartSample: chunkStart,
    sampleRate: sr,
  );
  return acc;
}

double rms(Int32List a, int from, int to) {
  var sum = 0.0;
  for (var i = from; i < to; i++) {
    sum += a[i] * a[i].toDouble();
  }
  return (sum / (to - from)).abs();
}

void main() {
  test('вдох: волна накатывает всю фазу (RMS растёт по четвертям)', () {
    final a = synthPhase(PhaseKind.inhale, 4000);
    final q = a.length ~/ 4;
    final r = [for (var i = 0; i < 4; i++) rms(a, i * q, (i + 1) * q)];
    expect(r[1], greaterThan(r[0]));
    expect(r[2], greaterThan(r[1]));
    expect(r[3], greaterThan(r[2]));
  });

  test('выдох: волна отступает всю фазу (RMS спадает)', () {
    final a = synthPhase(PhaseKind.exhale, 4000, startLevel: 1.0);
    final q = a.length ~/ 4;
    final r = [for (var i = 0; i < 4; i++) rms(a, i * q, (i + 1) * q)];
    expect(r[1], lessThan(r[0]));
    expect(r[2], lessThan(r[1]));
    expect(r[3], lessThan(r[2]));
  });

  test('задержка: после рампы — ровный тихий фон', () {
    final a = synthPhase(PhaseKind.holdIn, 4000, startLevel: 1.0);
    final q = a.length ~/ 4;
    final tail1 = rms(a, q, 2 * q);
    final tail3 = rms(a, 3 * q, 4 * q);
    // Фон стабилен (четверти после рампы сопоставимы) и тише пика вдоха.
    expect((tail3 / tail1 - 1).abs(), lessThan(0.5));
    final inhaleEnd = rms(synthPhase(PhaseKind.inhale, 4000),
        (3.5 * sr).round(), 4 * sr);
    expect(tail1, lessThan(inhaleEnd / 4));
  });

  test('чанковый рендер == цельному (детерминизм на границах чанков)', () {
    final whole = synthPhase(PhaseKind.inhale, 2000);
    final n = whole.length;
    final half = (n / 2).floor();
    final chunk2 = Int32List(n - half);
    mixSurfPhase(
      acc: chunk2,
      kind: PhaseKind.inhale,
      startLevel: 0.0,
      phaseStartSample: 0,
      phaseSamples: n,
      chunkStartSample: half,
      sampleRate: sr,
    );
    for (var i = 0; i < chunk2.length; i += 997) {
      expect(chunk2[i], whole[half + i], reason: 'sample ${half + i}');
    }
  });

  test('уровни стыков: конец вдоха=пик→выдох стартует с пика; '
      'грамматика непрерывна', () {
    expect(surfEndLevel(PhaseKind.inhale), 1.0);
    expect(surfStartLevel(PhaseKind.exhale, PhaseKind.inhale), 1.0);
    expect(surfEndLevel(PhaseKind.exhale), 0.0);
    expect(surfStartLevel(PhaseKind.inhale, PhaseKind.holdOut),
        surfEndLevel(PhaseKind.holdOut));
  });

  test('soundAssetPaths покрывает все ClipId (страховка полноты)', () {
    expect(soundAssetPaths.keys.toSet(), ClipId.values.toSet());
  });
}
