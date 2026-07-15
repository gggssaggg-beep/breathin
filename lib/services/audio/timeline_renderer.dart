import 'dart:typed_data';

import '../../domain/engine/session_plan.dart';
import '../../domain/models/technique.dart';
import 'surf_synth.dart';

/// Логический клип-событие. Фазы дыхания клипами НЕ являются — их звук
/// («прибой») синтезируется на всю длительность фазы (surf_synth.dart);
/// inhale/exhale остались для one-shot'ов Вима Хофа (фиксированные волны).
enum ClipId {
  inhale,
  exhale,
  prepBeep,
  gong,
  tick,
  tickAccent,
}

/// Набор декодированных PCM-клипов одного sample rate (ПЛАН §10.2).
class SoundBank {
  final int sampleRate;
  final Map<ClipId, Int16List> clips;
  const SoundBank({required this.sampleRate, required this.clips});
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

  /// Сопоставить событие клипу. Возвращает null для событий без клипа
  /// (фазы звучат синтезом прибоя, не клипом — см. [_phaseSpans]).
  static ClipId? clipForEvent(EngineEvent e) {
    switch (e.type) {
      case EngineEventType.prepCountdown:
        return ClipId.prepBeep;
      case EngineEventType.gong:
        return ClipId.gong;
      case EngineEventType.metronomeTick:
        return e.accent ? ClipId.tickAccent : ClipId.tick;
      case EngineEventType.sessionEnd:
      case EngineEventType.phaseStart:
        return null;
    }
  }

  /// Интервалы фаз плана: (kind, старт, длительность, стартовый уровень).
  /// Длительность — до следующего phaseStart, иначе до конца плана; стартовый
  /// уровень прибоя — уровень конца предыдущей фазы (без щелчков на стыках).
  static List<({PhaseKind kind, int tMs, int durMs, double startLevel})>
      _phaseSpans(SessionPlan plan) {
    final starts = plan.phaseStarts.toList(growable: false);
    return [
      for (var i = 0; i < starts.length; i++)
        (
          kind: starts[i].phase!,
          tMs: starts[i].tMs,
          durMs: (i + 1 < starts.length
                  ? starts[i + 1].tMs
                  : plan.totalDurationMs) -
              starts[i].tMs,
          startLevel: surfStartLevel(
            starts[i].phase!,
            i > 0 ? starts[i - 1].phase : null,
          ),
        ),
    ];
  }

  /// Полная длина сессии в сэмплах: конец плана либо хвост последнего клипа
  /// (гонг в t=конец звучит дольше плана — его хвост входит в буфер).
  int totalSamplesFor(SessionPlan plan, SoundBank bank) {
    var totalSamples = sampleOffsetForMs(plan.totalDurationMs);
    for (final e in plan.events) {
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
    // Прибой фаз: волна тянется ВСЮ фазу (вдох накатывает, выдох отступает,
    // задержки — тихий фон). Чанковость сохраняется: синтез детерминирован.
    for (final span in _phaseSpans(plan)) {
      mixSurfPhase(
        acc: acc,
        kind: span.kind,
        startLevel: span.startLevel,
        phaseStartSample: sampleOffsetForMs(span.tMs),
        phaseSamples: sampleOffsetForMs(span.tMs + span.durMs) -
            sampleOffsetForMs(span.tMs),
        chunkStartSample: startSample,
        sampleRate: sampleRate,
      );
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
