import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:breathin/domain/catalog/techniques.dart';
import 'package:breathin/domain/engine/session_plan_compiler.dart';
import 'package:breathin/domain/models/session_config.dart';
import 'package:breathin/services/audio/timeline_renderer.dart';
import 'package:breathin/services/audio/wav_io.dart';

/// Синтетический набор: каждый клип — константа [value] длиной [len] сэмплов.
/// Позволяет точно детектировать позицию (у реальных клипов атака стартует с 0).
SoundBank constantBank(int sr, {int value = 1000, int len = 100}) {
  Int16List clip() => Int16List(len)..fillRange(0, len, value);
  return SoundBank(sampleRate: sr, clips: {
    for (final id in ClipId.values) id: clip(),
  });
}

void main() {
  const compiler = SessionPlanCompiler();
  const renderer = TimelineRenderer();

  group('sampleOffsetForMs', () {
    test('округляет к ближайшему сэмплу', () {
      expect(renderer.sampleOffsetForMs(1000), 44100);
      expect(renderer.sampleOffsetForMs(0), 0);
      // 12340 мс → round(12.340 × 44100) = 544194
      expect(renderer.sampleOffsetForMs(12340), 544194);
    });
  });

  group('render — точность позиций', () {
    test('клип-событие лежит ровно на round(t·SR/1000)', () {
      const cfg = SessionConfig(
        endMode: EndMode.cycles,
        cycles: 1,
        phaseSeconds: [4, 4, 4, 4],
        prepSeconds: 3, // бипы отсчёта на 0/1000/2000 — фазы после 3000
      );
      final plan = compiler.compile(boxBreathing, cfg);
      final buf = renderer.render(plan, constantBank(44100, len: 100));

      // Бип «2» стартует на 1000 мс; вокруг подготовки фаз ещё нет — тишина.
      final off = renderer.sampleOffsetForMs(1000); // 44100
      expect(buf[off - 1], 0, reason: 'сэмпл перед стартом клипа — тишина');
      expect(buf[off], 1000, reason: 'клип начинается ровно на off');
      expect(buf[off + 99], 1000);
      expect(buf[off + 100], 0, reason: 'после клипа снова тишина');
    });

    test('«Поток»: тон вдоха звучит всю фазу и нарастает, задержка — тихо',
        () {
      const cfg = SessionConfig(
        endMode: EndMode.cycles,
        cycles: 1,
        phaseSeconds: [4, 4, 4, 4],
        prepSeconds: 0,
      );
      final plan = compiler.compile(boxBreathing, cfg);
      final buf = renderer.render(
        plan,
        SoundBank(
          sampleRate: 44100,
          synthPhases: true,
          clips: {ClipId.gong: Int16List(10)},
        ),
      );

      double rms(int fromMs, int toMs) {
        final a = renderer.sampleOffsetForMs(fromMs);
        final b = renderer.sampleOffsetForMs(toMs);
        var sum = 0.0;
        for (var i = a; i < b; i++) {
          sum += buf[i] * buf[i].toDouble();
        }
        return sum / (b - a);
      }

      // Вдох [0..4000): энергия в конце фазы много выше начала (накат).
      expect(rms(3000, 3900), greaterThan(rms(100, 1000) * 4));
      // Задержка [4000..8000): фон стабилен и тише конца вдоха.
      expect(rms(6000, 7000), lessThan(rms(3000, 3900) / 4));
      expect(rms(6000, 7000), greaterThan(0), reason: 'фон не тишина');
    });

    test('длина буфера учитывает хвост гонга за концом сессии', () {
      const cfg = SessionConfig(
        endMode: EndMode.cycles,
        cycles: 1,
        phaseSeconds: [4, 4, 4, 4],
        prepSeconds: 0,
      );
      final plan = compiler.compile(boxBreathing, cfg);
      const gongLen = 500;
      final bank = SoundBank(sampleRate: 44100, clips: {
        for (final id in ClipId.values)
          id: Int16List(id == ClipId.gong ? gongLen : 10)
      });
      // gong-клип длиннее прочих → задаёт хвост
      for (final id in ClipId.values) {
        bank.clips[id]!.fillRange(0, bank.clips[id]!.length, 500);
      }
      final buf = renderer.render(plan, bank);
      expect(buf.length, renderer.sampleOffsetForMs(16000) + gongLen);
    });

    test('несовпадение sample rate набора → ArgumentError', () {
      final plan =
          compiler.compile(boxBreathing, SessionConfig.classic(boxBreathing));
      expect(
        () => renderer.render(plan, constantBank(48000)),
        throwsArgumentError,
      );
    });
  });

  group('WavIo round-trip', () {
    test('encode→decode сохраняет сэмплы и sample rate', () {
      final samples = Int16List.fromList([0, 1000, -1000, 32767, -32768, 42]);
      final bytes = WavIo.encode(samples, 44100);
      final back = WavIo.decode(bytes);
      expect(back.sampleRate, 44100);
      expect(back.samples, samples);
    });
  });

  group('Интеграция с реальными ассетами', () {
    // Тест-раннер стартует с корнем проекта как cwd → ассеты доступны по пути.
    final assetDir = Directory('assets/audio');

    test('реальный набор декодируется и рендерит непустую сессию', () {
      if (!assetDir.existsSync()) {
        fail('Нет assets/audio — сначала: python tools/generate_audio.py');
      }
      Int16List load(String rel) =>
          WavIo.decode(File('assets/audio/$rel').readAsBytesSync()).samples;

      // Режим «Чаши»: реальные клипы фаз кладутся на старты фаз.
      final bank = SoundBank(sampleRate: 44100, clips: {
        ClipId.inhale: load('sets/bowls/inhale.wav'),
        ClipId.holdIn: load('sets/bowls/hold_in.wav'),
        ClipId.exhale: load('sets/bowls/exhale.wav'),
        ClipId.holdOut: load('sets/bowls/hold_out.wav'),
        ClipId.prepBeep: load('common/prep_beep.wav'),
        ClipId.gong: load('common/gong.wav'),
      });

      final plan =
          compiler.compile(boxBreathing, SessionConfig.classic(boxBreathing));
      final buf = renderer.render(plan, bank);

      // Длина ≈ 163 с + хвост гонга (6 с).
      expect(buf.length, greaterThan(renderer.sampleOffsetForMs(163000)));
      expect(buf.any((s) => s != 0), isTrue, reason: 'буфер не должен быть тишиной');
    });
  });
}
