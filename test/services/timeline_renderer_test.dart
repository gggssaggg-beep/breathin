import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:breathin/domain/catalog/techniques.dart';
import 'package:breathin/domain/engine/session_plan_compiler.dart';
import 'package:breathin/domain/models/session_config.dart';
import 'package:breathin/domain/models/technique.dart';
import 'package:breathin/services/audio/harp_melody.dart';
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

    test('«Арфа»: ноты лесенки ложатся на точные позиции, фазовые клипы '
        'не кладутся (мелодия вместо них)', () {
      const cfg = SessionConfig(
        endMode: EndMode.cycles,
        cycles: 1,
        phaseSeconds: [4, 4, 4, 4],
        prepSeconds: 0,
      );
      final plan = compiler.compile(boxBreathing, cfg);
      // Маркерная лесенка: нота i — константа (i+1)·10 длиной 5 сэмплов.
      final scale = [
        for (var i = 0; i < 8; i++) Int16List(5)..fillRange(0, 5, (i + 1) * 10),
      ];
      final buf = renderer.render(
        plan,
        SoundBank(
          sampleRate: 44100,
          clips: {
            // Фазовый клип в банке НЕ должен звучать при мелодии.
            ClipId.inhale: Int16List(5)..fillRange(0, 5, 9999),
            ClipId.gong: Int16List(10),
          },
          scale: scale,
        ),
      );

      // Вдох 4 c → 4 ноты (0..3) на 0/1000/2000/3000 мс (гейн 0.8).
      expect(buf[renderer.sampleOffsetForMs(0)], 8);
      expect(buf[renderer.sampleOffsetForMs(1000)], 16);
      expect(buf[renderer.sampleOffsetForMs(2000)], 24);
      expect(buf[renderer.sampleOffsetForMs(3000)], 32);
      // Задержка после вдоха: одна тихая верхняя нота (C5, индекс 5,
      // гейн 0.3 → 60·0.3=18).
      expect(buf[renderer.sampleOffsetForMs(4000)], 18);
      // Выдох: те же ноты вниз — на 8000 мс нота индекса 3 (40·0.8=32).
      expect(buf[renderer.sampleOffsetForMs(8000)], 32);
      expect(buf[renderer.sampleOffsetForMs(11000)], 8); // индекс 0
      // Маркер фазового клипа (9999) нигде не всплыл.
      expect(buf.any((s) => s > 5000), isFalse,
          reason: 'фазовый клип не должен звучать при мелодии');
    });

    test('«Арфа»: число нот адаптивно к длительности фазы', () {
      // 8-секундный вдох → 8 нот лесенки; 2-секундный выдох → 2 ноты.
      final up = notesForPhase(PhaseKind.inhale, 8000);
      expect(up, hasLength(8));
      expect(up.first.scaleIndex, 0);
      expect(up.last.scaleIndex, 7);
      final down = notesForPhase(PhaseKind.exhale, 2000);
      expect(down, hasLength(2));
      expect(down.first.scaleIndex, 1);
      expect(down.last.scaleIndex, 0);
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
