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

/// Маркерные клипы-события: у каждого своя амплитуда — по значению сэмпла в
/// буфере видно, какой клип туда лёг. Банк режима «Арфа» (scale задан):
/// фазы озвучивает мелодия из лесенки; маркер-ноты — константа 100 —
/// на первом сэмпле вдоха лежит нота лесенки (100·0.8 = 80).
SoundBank markerBank() {
  Int16List clip(int amp) => Int16List.fromList([amp, amp]);
  return SoundBank(
    sampleRate: 1000,
    scale: [for (var i = 0; i < 8; i++) clip(100)],
    clips: {
      ClipId.prepBeep: clip(500),
      ClipId.gong: clip(600),
      ClipId.tick: clip(700),
      ClipId.tickAccent: clip(800),
    },
  );
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
    test('оба канала: нота мелодии и тик в буфере', () {
      final wav = buildSessionWav(
        plan,
        markerBank(),
        const FeedbackChannels(sound: true, metronome: true),
      );
      final pcm = WavIo.decode(wav!).samples;
      // t=3000 мс → сэмпл 3000: акцент-тик 800 + первая нота лесенки
      // (маркер 100 · гейн 0.8 = 80).
      expect(pcm[3000], 880);
      // Вторая нота вдоха — на 4000 мс: тик 700 + нота 80.
      expect(pcm[4000], 780);
      // Гонг на 19000 (мелодия фаз закончилась).
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

    test('только звук: тиков нет, мелодия есть', () {
      final wav = buildSessionWav(
        plan,
        markerBank(),
        const FeedbackChannels(sound: true, metronome: false),
      );
      final pcm = WavIo.decode(wav!).samples;
      // Старт вдоха: без акцент-тика остаётся только нота лесенки.
      expect(pcm[3000], 80);
      // Между нотами — тишина (щипки короткие, маркер 2 сэмпла).
      expect(pcm[3500], 0);
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

  group('голос (П8)', () {
    // Маркеры голоса: по амплитуде видно, какой клип лёг в буфер.
    VoiceBank markerVoice() {
      Int16List clip(int amp) => Int16List.fromList([amp, amp]);
      return VoiceBank(
        sampleRate: 1000,
        inhale: clip(10),
        exhale: clip(20),
        hold: clip(30),
        prep: clip(40),
        inhaleSlow: clip(50),
        exhaleSlow: clip(60),
      );
    }

    test('только голос: слова на фазах, «приготовьтесь» один раз, '
        'мелодия и гонг молчат', () {
      final wav = buildSessionWav(
        plan,
        markerBank(),
        const FeedbackChannels(sound: false, metronome: false, voice: true),
        voice: markerVoice(),
      );
      final pcm = WavIo.decode(wav!).samples;
      // «Приготовьтесь» — один раз, у начала отсчёта; сдвиг 150 мс — чтобы
      // старт аудио-пайплайна не съедал «При-» (влад. 2026-07-19 №1).
      expect(pcm[0], 0);
      expect(pcm[150], 40);
      expect(pcm[1000], 0);
      expect(pcm[2000], 0);
      // Фазы квадрата 4-4-4-4 (короче порога 6 с → обычные клипы).
      expect(pcm[3000], 10); // вдох
      expect(pcm[7000], 30); // задержка
      expect(pcm[11000], 20); // выдох
      expect(pcm[15000], 30); // задержка
      // Звук выключен: мелодии между словами нет, гонга нет — буфер ровно
      // до конца сессии.
      expect(pcm[4000], 0);
      expect(pcm.length, 19000);
    });

    test('длинный выдох (≥6 с) озвучивается медленным клипом', () {
      const longExhale = SessionConfig(
        endMode: EndMode.cycles,
        cycles: 1,
        phaseSeconds: [4, 4, 8, 4],
        prepSeconds: 3,
      );
      final p = const SessionPlanCompiler().compile(boxBreathing, longExhale);
      final wav = buildSessionWav(
        p,
        markerBank(),
        const FeedbackChannels(sound: false, metronome: false, voice: true),
        voice: markerVoice(),
      );
      final pcm = WavIo.decode(wav!).samples;
      expect(pcm[3000], 10); // вдох 4 с — обычный
      expect(pcm[11000], 60); // выдох 8 с — медленный
    });

    test('голос поверх звука — аддитивный слой: мелодия, бип и гонг на месте',
        () {
      final wav = buildSessionWav(
        plan,
        markerBank(),
        const FeedbackChannels(sound: true, metronome: false, voice: true),
        voice: markerVoice(),
      );
      final pcm = WavIo.decode(wav!).samples;
      expect(pcm[0], 500); // бип подготовки — на месте
      expect(pcm[150], 40); // «приготовьтесь» — со сдвигом 150 мс
      expect(pcm[3000], 90); // нота лесенки 80 + «вдох» 10
      expect(pcm[19000], 600); // гонг звучит как раньше
    });
  });
}
