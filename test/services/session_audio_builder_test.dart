import 'dart:typed_data';

import 'package:breathin/domain/catalog/techniques.dart';
import 'package:breathin/domain/engine/session_plan.dart';
import 'package:breathin/domain/engine/session_plan_compiler.dart';
import 'package:breathin/domain/models/feedback_channels.dart';
import 'package:breathin/domain/models/session_config.dart';
import 'package:breathin/services/audio/session_audio_builder.dart';
import 'package:breathin/services/audio/timeline_renderer.dart';
import 'package:breathin/services/audio/wav_io.dart';
import 'package:flutter_test/flutter_test.dart';

/// Маркерные клипы: у каждого клипа своя амплитуда — по значению сэмпла в
/// буфере можно понять, какой клип туда лёг.
SoundBank markerBank() {
  Int16List clip(int amp) => Int16List.fromList([amp, amp]);
  return SoundBank(sampleRate: 1000, clips: {
    ClipId.inhale: clip(100),
    ClipId.holdIn: clip(200),
    ClipId.exhale: clip(300),
    ClipId.holdOut: clip(400),
    ClipId.prepBeep: clip(500),
    ClipId.gong: clip(600),
    ClipId.tick: clip(700),
    ClipId.tickAccent: clip(800),
  });
}

void main() {
  // Квадрат 4-4-4-4 × 1 цикл, подготовка 3 c → фазы на 3000/7000/11000/15000,
  // гонг на 19000. SR=1000 → сэмпл == миллисекунда, удобно проверять.
  const oneCycle = SessionConfig(
    endMode: EndMode.cycles,
    cycles: 1,
    phaseSeconds: [4, 4, 4, 4],
    prepSeconds: 3,
  );
  final plan = const SessionPlanCompiler()
      .compile(boxBreathing, oneCycle, metronome: true);

  group('компилятор: метроном', () {
    test('тики каждую секунду дыхательной части, гонговый момент не тикает',
        () {
      final ticks = plan.events
          .where((e) => e.type == EngineEventType.metronomeTick)
          .toList();
      // 3000..18000 включительно = 16 тиков (шаг 1000, 19000 — не тик).
      expect(ticks, hasLength(16));
      expect(ticks.first.tMs, 3000);
      expect(ticks.last.tMs, 18000);
    });

    test('акценты — ровно на стартах фаз', () {
      final accents = plan.events
          .where((e) => e.type == EngineEventType.metronomeTick && e.accent)
          .map((e) => e.tMs);
      expect(accents, [3000, 7000, 11000, 15000]);
    });

    test('события отсортированы по времени', () {
      for (var i = 1; i < plan.events.length; i++) {
        expect(plan.events[i].tMs, greaterThanOrEqualTo(plan.events[i - 1].tMs));
      }
    });

    test('без флага metronome тиков нет', () {
      final quiet =
          const SessionPlanCompiler().compile(boxBreathing, oneCycle);
      expect(
        quiet.events.where((e) => e.type == EngineEventType.metronomeTick),
        isEmpty,
      );
    });
  });

  group('buildSessionWav', () {
    test('оба канала: и сигнал фазы, и тик в буфере', () {
      final wav = buildSessionWav(
        plan,
        markerBank(),
        const FeedbackChannels(sound: true, metronome: true),
      );
      final pcm = WavIo.decode(wav!).samples;
      // t=3000 мс → сэмпл 3000: вдох (100) + акцент-тик (800) = 900.
      expect(pcm[3000], 900);
      // t=4000: только обычный тик.
      expect(pcm[4000], 700);
      // Гонг на 19000.
      expect(pcm[19000], 600);
      // Длина ≥ полной сессии.
      expect(pcm.length, greaterThanOrEqualTo(19000));
    });

    test('только метроном: сигналов фаз и гонга нет', () {
      final wav = buildSessionWav(
        plan,
        markerBank(),
        const FeedbackChannels(sound: false, metronome: true),
      );
      final pcm = WavIo.decode(wav!).samples;
      expect(pcm[3000], 800); // только акцент-тик
      // Гонга нет, но буфер тянется ровно до конца сессии (тишиной) —
      // непрерывность потока и есть защита от засыпания процесса.
      expect(pcm.length, 19000);
      expect(pcm[18999], 0);
    });

    test('только звук: тиков нет', () {
      final wav = buildSessionWav(
        plan,
        markerBank(),
        const FeedbackChannels(sound: true, metronome: false),
      );
      final pcm = WavIo.decode(wav!).samples;
      expect(pcm[4000], 0);
      expect(pcm[3000], 100);
    });

    test('аудио-каналы выключены → null', () {
      expect(
        buildSessionWav(
          plan,
          markerBank(),
          const FeedbackChannels(sound: false, metronome: false),
        ),
        isNull,
      );
    });
  });
}
