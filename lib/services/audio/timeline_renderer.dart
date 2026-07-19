import 'dart:typed_data';

import '../../domain/engine/session_plan.dart';
import '../../domain/models/technique.dart';
import 'harp_melody.dart';

/// Логический звук: клипы-события всегда, фазовые клипы — только у наборов
/// без лесенки ([SoundBank.scale] == null, «Чаши»); у «Арфы» фазы озвучивает
/// мелодия из нот лесенки (harp_melody.dart).
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
/// [scale] — лесенка нот мелодии фаз (пентатоника, [harpScaleSize] нот);
/// если задана, фазовые клипы из [clips] не кладутся (звучали бы дважды).
class SoundBank {
  final int sampleRate;
  final Map<ClipId, Int16List> clips;
  final List<Int16List>? scale;
  const SoundBank({
    required this.sampleRate,
    required this.clips,
    this.scale,
  });
}

/// Порог «длинной» фазы для голоса: вдох/выдох от этой длительности
/// озвучиваются медленным клипом (влад. 2026-07-18: «если вдох или выдох
/// долгий — бери медленную версию, чтоб спокойствие интуитивно считывалось»).
const int voiceSlowPhaseMs = 6000;

/// Голосовые подсказки фаз (П8): отдельный банк, микшируется ПОВЕРХ
/// выбранного набора звука (аддитивный слой — набор пользователя не
/// трогаем). [hold] звучит на обеих задержках; [inhaleSlow]/[exhaleSlow] —
/// спокойные варианты для фаз ≥ [voiceSlowPhaseMs].
class VoiceBank {
  final int sampleRate;
  final Int16List inhale;
  final Int16List exhale;
  final Int16List hold;
  final Int16List prep;
  final Int16List inhaleSlow;
  final Int16List exhaleSlow;
  const VoiceBank({
    required this.sampleRate,
    required this.inhale,
    required this.exhale,
    required this.hold,
    required this.prep,
    required this.inhaleSlow,
    required this.exhaleSlow,
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

  /// Сопоставить событие клипу. phaseStart маппится на фазовый клип — режим
  /// «Чаш»; у «Арфы» (bank.scale != null) фазы озвучивает мелодия.
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

  /// Ноты мелодии всего плана: (сэмпл старта, нота лесенки, громкость).
  /// Длительность фазы — до следующего phaseStart, иначе до конца плана;
  /// раскладка нот по фазе — notesForPhase (harp_melody.dart).
  List<({int atSample, int scaleIndex, double gain})> _melodyNotes(
      SessionPlan plan) {
    final starts = plan.phaseStarts.toList(growable: false);
    return [
      for (var i = 0; i < starts.length; i++)
        for (final note in notesForPhase(
          starts[i].phase!,
          (i + 1 < starts.length ? starts[i + 1].tMs : plan.totalDurationMs) -
              starts[i].tMs,
        ))
          (
            atSample: sampleOffsetForMs(starts[i].tMs + note.offsetMs),
            scaleIndex: note.scaleIndex,
            gain: note.gain,
          ),
    ];
  }

  /// Голосовые подсказки плана: (сэмпл старта, клип). Фазы — по [PhaseKind],
  /// длинные вдох/выдох (≥ [voiceSlowPhaseMs], до следующего phaseStart) —
  /// медленным клипом; «приготовьтесь» — один раз, на первом событии
  /// отсчёта подготовки.
  List<({int atSample, Int16List clip})> _voiceCues(
      SessionPlan plan, VoiceBank voice) {
    final cues = <({int atSample, Int16List clip})>[];
    final starts = plan.phaseStarts.toList(growable: false);
    for (var i = 0; i < starts.length; i++) {
      final e = starts[i];
      final durMs =
          (i + 1 < starts.length ? starts[i + 1].tMs : plan.totalDurationMs) -
              e.tMs;
      final slow = durMs >= voiceSlowPhaseMs;
      final clip = switch (e.phase!) {
        PhaseKind.inhale => slow ? voice.inhaleSlow : voice.inhale,
        PhaseKind.exhale => slow ? voice.exhaleSlow : voice.exhale,
        PhaseKind.holdIn || PhaseKind.holdOut => voice.hold,
      };
      cues.add((atSample: sampleOffsetForMs(e.tMs), clip: clip));
    }
    EngineEvent? firstPrep;
    for (final e in plan.events) {
      if (e.type == EngineEventType.prepCountdown &&
          (firstPrep == null || e.tMs < firstPrep.tMs)) {
        firstPrep = e;
      }
    }
    if (firstPrep != null) {
      // Не с самого нуля: старт аудио-пайплайна съедает первые ~100 мс
      // файла — «Приготовьтесь» теряло «При-» (влад. 2026-07-19 №1).
      final tMs = firstPrep.tMs < 150 ? 150 : firstPrep.tMs;
      cues.add((atSample: sampleOffsetForMs(tMs), clip: voice.prep));
    }
    return cues;
  }

  /// Полная длина сессии в сэмплах: конец плана либо хвост последнего клипа
  /// (гонг в t=конец звучит дольше плана — его хвост входит в буфер).
  int totalSamplesFor(SessionPlan plan, SoundBank bank, {VoiceBank? voice}) {
    var totalSamples = sampleOffsetForMs(plan.totalDurationMs);
    for (final e in plan.events) {
      // «Арфа»: фазы озвучивает мелодия — фазовый клип не кладём, даже если
      // тестовый банк его содержит (иначе звучало бы дважды).
      if (bank.scale != null && e.type == EngineEventType.phaseStart) continue;
      final id = clipForEvent(e);
      if (id == null) continue;
      final clip = bank.clips[id];
      if (clip == null) continue;
      final end = sampleOffsetForMs(e.tMs) + clip.length;
      if (end > totalSamples) totalSamples = end;
    }
    if (voice != null) {
      for (final c in _voiceCues(plan, voice)) {
        final end = c.atSample + c.clip.length;
        if (end > totalSamples) totalSamples = end;
      }
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
    int startSample, {
    VoiceBank? voice,
  }) {
    if (bank.sampleRate != sampleRate) {
      throw ArgumentError(
        'sample rate набора (${bank.sampleRate}) != рендерера ($sampleRate)',
      );
    }
    if (voice != null && voice.sampleRate != sampleRate) {
      throw ArgumentError(
        'sample rate голоса (${voice.sampleRate}) != рендерера ($sampleRate)',
      );
    }
    final end = startSample + out.length;
    final acc = Int32List(out.length);
    for (final e in plan.events) {
      if (bank.scale != null && e.type == EngineEventType.phaseStart) continue;
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
    // «Арфа»: мелодия фаз — живые ноты лесенки на точных сэмплах (вдох —
    // лесенка вверх, выдох — вниз, задержки — тихая нота). Хвост ноты
    // свободно звенит поверх следующей фазы — арфа затухает естественно.
    final scale = bank.scale;
    if (scale != null) {
      for (final m in _melodyNotes(plan)) {
        final note = scale[m.scaleIndex.clamp(0, scale.length - 1)];
        if (m.atSample >= end || m.atSample + note.length <= startSample) {
          continue;
        }
        final from = m.atSample < startSample ? startSample - m.atSample : 0;
        final toEnd = end - m.atSample;
        final to = toEnd < note.length ? toEnd : note.length;
        for (var i = from; i < to; i++) {
          acc[m.atSample + i - startSample] += (note[i] * m.gain).round();
        }
      }
    }
    // Голосовые подсказки (П8) — аддитивный слой поверх набора: слова ложатся
    // на старты фаз, «приготовьтесь» — на начало отсчёта подготовки.
    if (voice != null) {
      for (final c in _voiceCues(plan, voice)) {
        if (c.atSample >= end || c.atSample + c.clip.length <= startSample) {
          continue;
        }
        final from = c.atSample < startSample ? startSample - c.atSample : 0;
        final toEnd = end - c.atSample;
        final to = toEnd < c.clip.length ? toEnd : c.clip.length;
        for (var i = from; i < to; i++) {
          acc[c.atSample + i - startSample] += c.clip[i];
        }
      }
    }
    for (var i = 0; i < out.length; i++) {
      final v = acc[i];
      out[i] = v > 32767 ? 32767 : (v < -32768 ? -32768 : v);
    }
  }

  /// Отрендерить план целиком (короткие планы и тесты; длинные сессии идут
  /// чанками через [renderRange] — см. writeSessionWavFile).
  Int16List render(SessionPlan plan, SoundBank bank, {VoiceBank? voice}) {
    final out = Int16List(totalSamplesFor(plan, bank, voice: voice));
    renderRange(plan, bank, out, 0, voice: voice);
    return out;
  }
}
