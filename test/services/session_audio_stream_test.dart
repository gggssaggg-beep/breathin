import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:breathin/domain/catalog/techniques.dart';
import 'package:breathin/domain/engine/session_plan_compiler.dart';
import 'package:breathin/domain/models/feedback_channels.dart';
import 'package:breathin/domain/models/session_config.dart';
import 'package:breathin/services/audio/session_audio_builder.dart';
import 'package:breathin/services/audio/timeline_renderer.dart';
import 'package:breathin/services/audio/wav_io.dart';

/// Синтетический набор: клипы разной длины (некоторые длиннее секунды —
/// перекрытия с тиками метронома гарантированы), детерминированные сэмплы.
SoundBank _bank({int sampleRate = 8000}) {
  Int16List clip(int n, int seed) => Int16List.fromList([
        for (var i = 0; i < n; i++) (((i * seed) % 199) - 99) * 90,
      ]);
  final clips = <ClipId, Int16List>{};
  var k = 0;
  for (final id in ClipId.values) {
    k++;
    // от 0.35 до 1.4 с — хвост гонга выйдет за конец плана
    clips[id] = clip(sampleRate * (k % 4 + 1) * 7 ~/ 20, k + 3);
  }
  return SoundBank(sampleRate: sampleRate, clips: clips);
}

void main() {
  final plan = const SessionPlanCompiler().compile(
    boxBreathing,
    SessionConfig.classic(boxBreathing).let((c) => SessionConfig(
          endMode: EndMode.cycles,
          cycles: 3,
          phaseSeconds: c.phaseSeconds,
          prepSeconds: 3,
        )),
    metronome: true,
  );
  final bank = _bank();
  const renderer = TimelineRenderer(sampleRate: 8000);

  test('renderRange чанками == render целиком (границы не делят ровно)', () {
    final whole = renderer.render(plan, bank);
    for (final chunkSamples in [997, 4096, whole.length + 5000]) {
      final assembled = Int16List(whole.length);
      for (var start = 0; start < whole.length; start += chunkSamples) {
        final rest = whole.length - start;
        final chunk = Int16List(rest < chunkSamples ? rest : chunkSamples);
        renderer.renderRange(plan, bank, chunk, start);
        assembled.setRange(start, start + chunk.length, chunk);
      }
      expect(assembled, whole, reason: 'чанк $chunkSamples');
    }
  });

  test('totalSamplesFor учитывает хвост гонга за концом плана', () {
    final total = renderer.totalSamplesFor(plan, bank);
    expect(total, greaterThan(renderer.sampleOffsetForMs(plan.totalDurationMs)));
    expect(renderer.render(plan, bank).length, total);
  });

  test('writeSessionWavFile байт-в-байт совпадает с buildSessionWav', () async {
    const feedback = FeedbackChannels(sound: true, metronome: true);
    final expected = buildSessionWav(plan, bank, feedback)!;
    final dir = await Directory.systemTemp.createTemp('breathin_wav_test');
    try {
      final file = File('${dir.path}/session.wav');
      final ok =
          await writeSessionWavFile(plan, bank, feedback, file, chunkSeconds: 1);
      expect(ok, isTrue);
      expect(await file.readAsBytes(), expected);
      // И это валидный WAV с теми же сэмплами, что у прямого рендера.
      final decoded = WavIo.decode(await file.readAsBytes());
      expect(decoded.sampleRate, bank.sampleRate);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('writeSessionWavFile: каналы выключены → false и файла нет', () async {
    const silent = FeedbackChannels(sound: false, metronome: false);
    final dir = await Directory.systemTemp.createTemp('breathin_wav_test');
    try {
      final file = File('${dir.path}/session.wav');
      expect(await writeSessionWavFile(plan, bank, silent, file), isFalse);
      expect(await file.exists(), isFalse);
    } finally {
      await dir.delete(recursive: true);
    }
  });
}

extension<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
