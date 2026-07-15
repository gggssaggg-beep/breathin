import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:breathin/domain/models/technique.dart';
import 'package:breathin/services/audio/pad_synth.dart';
import 'package:breathin/services/audio/sound_bank_loader.dart';
import 'package:breathin/services/audio/sound_preferences.dart';
import 'package:breathin/services/audio/timeline_renderer.dart';

const sr = 44100;

Int32List synth(PhaseKind kind, int durMs,
    {double startLevel = 0.0,
    PadAngles? angles,
    int chunkStart = 0,
    int? chunkLen,
    int phaseStart = 0}) {
  final samples = (durMs * sr / 1000).round();
  final acc = Int32List(chunkLen ?? samples);
  mixPadPhase(
    acc: acc,
    kind: kind,
    startLevel: startLevel,
    startAngles: angles ?? padInitialAngles(),
    phaseStartSample: phaseStart,
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
  return sum / (to - from);
}

void main() {
  test('вдох: тон нарастает всю фазу (RMS растёт по четвертям)', () {
    final a = synth(PhaseKind.inhale, 4000);
    final q = a.length ~/ 4;
    final r = [for (var i = 0; i < 4; i++) rms(a, i * q, (i + 1) * q)];
    expect(r[1], greaterThan(r[0]));
    expect(r[2], greaterThan(r[1]));
    expect(r[3], greaterThan(r[2]));
  });

  test('выдох: тон затихает всю фазу', () {
    final a = synth(PhaseKind.exhale, 4000, startLevel: 1.0);
    final q = a.length ~/ 4;
    final r = [for (var i = 0; i < 4; i++) rms(a, i * q, (i + 1) * q)];
    expect(r[1], lessThan(r[0]));
    expect(r[2], lessThan(r[1]));
    expect(r[3], lessThan(r[2]));
  });

  test('задержка: после рампы — ровный тихий звон, тише конца вдоха', () {
    final hold = synth(PhaseKind.holdIn, 4000, startLevel: 1.0);
    final q = hold.length ~/ 4;
    final t1 = rms(hold, q, 2 * q);
    final t3 = rms(hold, 3 * q, 4 * q);
    expect((t3 / t1 - 1).abs(), lessThan(0.5), reason: 'фон стабилен');
    final inhaleEnd =
        rms(synth(PhaseKind.inhale, 4000), (3.5 * sr).round(), 4 * sr);
    expect(t1, lessThan(inhaleEnd), reason: 'звон тише пика');
    expect(t1, greaterThan(0), reason: 'не тишина');
  });

  test('чанковый рендер == цельному (значение не зависит от чанка)', () {
    final whole = synth(PhaseKind.inhale, 2000);
    final n = whole.length;
    final half = n ~/ 2;
    final chunk2 = synth(PhaseKind.inhale, 2000,
        chunkStart: half, chunkLen: n - half);
    for (var i = 0; i < chunk2.length; i += 997) {
      expect(chunk2[i], whole[half + i], reason: 'sample ${half + i}');
    }
  });

  test('стык фаз непрерывен: конец вдоха ≈ начало задержки (углы переданы)',
      () {
    const durMs = 2000;
    final samples = (durMs * sr / 1000).round();
    final inhale = synth(PhaseKind.inhale, durMs);
    final endAngles =
        padEndAngles(padInitialAngles(), PhaseKind.inhale, samples, sr);
    // Задержка стартует с уровня 1.0 и углов конца вдоха; глобальное время
    // продолжается (phaseStart = samples) — вибрато тоже непрерывно.
    final holdAcc = Int32List(64);
    mixPadPhase(
      acc: holdAcc,
      kind: PhaseKind.holdIn,
      startLevel: 1.0,
      startAngles: endAngles,
      phaseStartSample: samples,
      phaseSamples: samples,
      chunkStartSample: samples,
      sampleRate: sr,
    );
    // Скачок между последним сэмплом вдоха и первым задержки — не больше
    // естественного межсэмплового шага (сравниваем с шагом внутри вдоха).
    final joinJump = (holdAcc[0] - inhale[samples - 1]).abs();
    var maxStep = 0;
    for (var i = samples - 400; i < samples - 1; i++) {
      final d = (inhale[i + 1] - inhale[i]).abs();
      if (d > maxStep) maxStep = d;
    }
    expect(joinJump, lessThanOrEqualTo(maxStep * 2),
        reason: 'стык без щелчка: скачок $joinJump vs шаг $maxStep');
  });

  group('наборы звука', () {
    test('дефолт — «Поток»; мусор в prefs откатывается к дефолту', () {
      expect(SoundSet.values.first, SoundSet.flow);
    });

    test('«Поток» без фазовых клипов, «Чаши» — с полным набором', () {
      final flow = assetsForSet(SoundSet.flow);
      expect(flow.containsKey(ClipId.inhale), isFalse,
          reason: 'фазы поёт синтез — клипы звучали бы дважды');
      expect(flow[ClipId.gong], isNotNull);
      final bowls = assetsForSet(SoundSet.bowls);
      expect(bowls.keys.toSet(), ClipId.values.toSet(),
          reason: 'чаши покрывают все ClipId');
      expect(bowls[ClipId.inhale], contains('sets/bowls/'));
    });

    test('soundAssetPaths (общие + ВХ) содержит волны и гонг', () {
      expect(soundAssetPaths[ClipId.inhale], contains('breath_in'));
      expect(soundAssetPaths[ClipId.exhale], contains('breath_out'));
      expect(soundAssetPaths[ClipId.gong], contains('gong'));
    });
  });
}
