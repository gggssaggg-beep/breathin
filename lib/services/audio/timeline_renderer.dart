import 'dart:typed_data';

import '../../domain/engine/session_plan.dart';
import '../../domain/models/technique.dart';
import 'pad_synth.dart';

/// Логический звук: клипы-события всегда, фазовые клипы — только у наборов
/// с [SoundBank.synthPhases] == false («Чаши»); у «Потока» фазы синтезируются
/// рендерером на всю длительность (pad_synth.dart).
enum ClipId {
  inhale,
  holdIn,
  exhale,
  holdOut,
  prepBeep,
  gong,
  tick,
  tickAccent,
}

/// Набор декодированных PCM-клипов одного sample rate (ПЛАН §10.2).
/// [synthPhases] == true — фазы озвучивает синтез «Потока», фазовые клипы
/// в [clips] отсутствуют (иначе звучали бы дважды).
class SoundBank {
  final int sampleRate;
  final Map<ClipId, Int16List> clips;
  final bool synthPhases;
  const SoundBank({
    required this.sampleRate,
    required this.clips,
    this.synthPhases = false,
  });
}

/// Рендерер таймлайна: раскладывает события [SessionPlan] на единый PCM-буфер,
/// смешивая клипы на точных сэмплах (ПЛАН §3.3, п.2).
///
/// Ключевое свойство: событие с t=X мс кладётся на сэмпл round(X·SR/1000).
/// Именно поэтому дрейф фаз — нулевой по построению, а не «почти точный
/// таймер»: часами становится само аудио-железо, тянущее этот буфер.
class TimelineRenderer {
  final int sampleRate;
  const TimelineRenderer({this.sampleRate = 44100});

  /// Позиция сэмпла для момента [ms]. Публичный — проверяется тестом.
  int sampleOffsetForMs(int ms) => (ms * sampleRate / 1000).round();

  /// Сопоставить событие клипу. phaseStart маппится на фазовый клип — но у
  /// «Потока» таких клипов в банке нет (synthPhases), событие просто молчит.
  static ClipId? clipForEvent(EngineEvent e) {
    switch (e.type) {
      case EngineEventType.prepCountdown:
        return ClipId.prepBeep;
      case EngineEventType.gong:
        return ClipId.gong;
      case EngineEventType.metronomeTick:
        return e.accent ? ClipId.tickAccent : ClipId.tick;
      case EngineEventType.sessionEnd:
        return null;
      case EngineEventType.phaseStart:
        switch (e.phase!) {
          case PhaseKind.inhale:
            return ClipId.inhale;
          case PhaseKind.holdIn:
            return ClipId.holdIn;
          case PhaseKind.exhale:
            return ClipId.exhale;
          case PhaseKind.holdOut:
            return ClipId.holdOut;
        }
    }
  }

  /// Интервалы фаз плана для синтеза «Потока»: (kind, старт, длительность,
  /// стартовый уровень, стартовые углы гармоник). Длительность — до
  /// следующего phaseStart, иначе до конца плана; уровень и углы стартуют
  /// с конца предыдущей фазы — стыки непрерывны и по громкости, и по волне.
  List<
      ({
        PhaseKind kind,
        int tMs,
        int durMs,
        double startLevel,
        PadAngles startAngles,
      })> _phaseSpans(SessionPlan plan) {
    final starts = plan.phaseStarts.toList(growable: false);
    var angles = padInitialAngles();
    final spans = <({
      PhaseKind kind,
      int tMs,
      int durMs,
      double startLevel,
      PadAngles startAngles,
    })>[];
    for (var i = 0; i < starts.length; i++) {
      final kind = starts[i].phase!;
      final tMs = starts[i].tMs;
      final durMs =
          (i + 1 < starts.length ? starts[i + 1].tMs : plan.totalDurationMs) -
              tMs;
      final samples =
          sampleOffsetForMs(tMs + durMs) - sampleOffsetForMs(tMs);
      spans.add((
        kind: kind,
        tMs: tMs,
        durMs: durMs,
        startLevel: padStartLevel(kind, i > 0 ? starts[i - 1].phase : null),
        startAngles: angles,
      ));
      angles = padEndAngles(angles, kind, samples, sampleRate);
    }
    return spans;
  }

  /// Полная длина сессии в сэмплах: конец плана либо хвост последнего клипа
  /// (гонг в t=конец звучит дольше плана — его хвост входит в буфер).
  int totalSamplesFor(SessionPlan plan, SoundBank bank) {
    var totalSamples = sampleOffsetForMs(plan.totalDurationMs);
    for (final e in plan.events) {
      // «Поток»: фазы поёт синтез — фазовый клип не кладём, даже если
      // тестовый банк его содержит (иначе звучало бы дважды).
      if (bank.synthPhases && e.type == EngineEventType.phaseStart) continue;
      final id = clipForEvent(e);
      if (id == null) continue;
      final clip = bank.clips[id];
      if (clip == null) continue;
      final end = sampleOffsetForMs(e.tMs) + clip.length;
      if (end > totalSamples) totalSamples = end;
    }
    return totalSamples;
  }

  /// Микширует в [out] фрагмент таймлайна с сэмпла [startSample] (16-бит моно;
  /// 32-битный аккумулятор, клампится — сумма перекрывающихся клипов может
  /// превысить пик). Память O(len(out)): длинная сессия рендерится чанками и
  /// целиком в RAM не живёт (ревью К2: час таймлайна в RAM ронял процесс).
  void renderRange(
    SessionPlan plan,
    SoundBank bank,
    Int16List out,
    int startSample,
  ) {
    if (bank.sampleRate != sampleRate) {
      throw ArgumentError(
        'sample rate набора (${bank.sampleRate}) != рендерера ($sampleRate)',
      );
    }
    final end = startSample + out.length;
    final acc = Int32List(out.length);
    for (final e in plan.events) {
      if (bank.synthPhases && e.type == EngineEventType.phaseStart) continue;
      final id = clipForEvent(e);
      if (id == null) continue;
      final clip = bank.clips[id];
      if (clip == null) continue;
      final clipStart = sampleOffsetForMs(e.tMs);
      if (clipStart >= end || clipStart + clip.length <= startSample) continue;
      final from = clipStart < startSample ? startSample - clipStart : 0;
      final toEnd = end - clipStart;
      final to = toEnd < clip.length ? toEnd : clip.length;
      for (var i = from; i < to; i++) {
        acc[clipStart + i - startSample] += clip[i];
      }
    }
    // «Поток»: тон тянется ВСЮ фазу (вдох — вверх и ярче, выдох — зеркально,
    // задержки — тихий звон). Чанковость сохраняется: синтез детерминирован,
    // углы гармоник аккумулируются по спанам аналитически.
    if (bank.synthPhases) {
      for (final span in _phaseSpans(plan)) {
        mixPadPhase(
          acc: acc,
          kind: span.kind,
          startLevel: span.startLevel,
          startAngles: span.startAngles,
          phaseStartSample: sampleOffsetForMs(span.tMs),
          phaseSamples: sampleOffsetForMs(span.tMs + span.durMs) -
              sampleOffsetForMs(span.tMs),
          chunkStartSample: startSample,
          sampleRate: sampleRate,
        );
      }
    }
    for (var i = 0; i < out.length; i++) {
      final v = acc[i];
      out[i] = v > 32767 ? 32767 : (v < -32768 ? -32768 : v);
    }
  }

  /// Отрендерить план целиком (короткие планы и тесты; длинные сессии идут
  /// чанками через [renderRange] — см. writeSessionWavFile).
  Int16List render(SessionPlan plan, SoundBank bank) {
    final out = Int16List(totalSamplesFor(plan, bank));
    renderRange(plan, bank, out, 0);
    return out;
  }
}
