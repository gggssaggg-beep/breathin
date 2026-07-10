import 'dart:typed_data';

import '../../domain/engine/session_plan.dart';
import '../../domain/models/technique.dart';

/// Логический звук в наборе. Резолвится из [EngineEvent] (см. ниже).
enum ClipId { inhale, holdIn, exhale, holdOut, prepBeep, gong }

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

  /// Сопоставить событие клипу набора. Возвращает null для событий без звука.
  static ClipId? clipForEvent(EngineEvent e) {
    switch (e.type) {
      case EngineEventType.prepCountdown:
        return ClipId.prepBeep;
      case EngineEventType.gong:
        return ClipId.gong;
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

  /// Отрендерить план в PCM 16-бит моно. Микс идёт в 32-битный аккумулятор,
  /// затем клампится в int16 (сумма перекрывающихся клипов может превысить пик).
  Int16List render(SessionPlan plan, SoundBank bank) {
    if (bank.sampleRate != sampleRate) {
      throw ArgumentError(
        'sample rate набора (${bank.sampleRate}) != рендерера ($sampleRate)',
      );
    }

    // Заранее считаем длину буфера: максимум по (offset + длина клипа).
    var totalSamples = sampleOffsetForMs(plan.totalDurationMs);
    for (final e in plan.events) {
      final id = clipForEvent(e);
      if (id == null) continue;
      final clip = bank.clips[id];
      if (clip == null) continue;
      final end = sampleOffsetForMs(e.tMs) + clip.length;
      if (end > totalSamples) totalSamples = end;
    }

    final acc = Int32List(totalSamples);
    for (final e in plan.events) {
      final id = clipForEvent(e);
      if (id == null) continue;
      final clip = bank.clips[id];
      if (clip == null) continue;
      final start = sampleOffsetForMs(e.tMs);
      for (var i = 0; i < clip.length; i++) {
        acc[start + i] += clip[i];
      }
    }

    final out = Int16List(totalSamples);
    for (var i = 0; i < totalSamples; i++) {
      final v = acc[i];
      out[i] = v > 32767 ? 32767 : (v < -32768 ? -32768 : v);
    }
    return out;
  }
}
