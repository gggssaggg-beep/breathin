import 'dart:typed_data';

import '../../domain/engine/session_plan.dart';
import '../../domain/models/feedback_channels.dart';
import 'timeline_renderer.dart';
import 'wav_io.dart';

/// Собирает WAV всей сессии из плана с учётом каналов сопровождения
/// (ТЗ §3.3): звук фаз и/или метроном. Чистая логика поверх
/// [TimelineRenderer] — тестируется с синтетическим [SoundBank].
///
/// Возвращает null, если аудио-каналы выключены (звук и метроном) —
/// вызывающая сторона тогда не строит аудио-путь вовсе.
///
/// ВАЖНО: буфер тянется до plan.totalDurationMs даже если последние
/// миллисекунды — тишина: непрерывный поток и есть механизм «ОС не
/// усыпляет процесс» (ПЛАН §3.3 п.2).
Uint8List? buildSessionWav(
  SessionPlan plan,
  SoundBank bank,
  FeedbackChannels feedback,
) {
  if (!feedback.sound && !feedback.metronome) return null;

  bool keep(EngineEvent e) {
    switch (e.type) {
      case EngineEventType.prepCountdown:
      case EngineEventType.phaseStart:
      case EngineEventType.gong:
        return feedback.sound;
      case EngineEventType.metronomeTick:
        return feedback.metronome;
      case EngineEventType.sessionEnd:
        return true; // без звука, но событие остаётся событием плана
    }
  }

  final filtered = SessionPlan(
    events: plan.events.where(keep).toList(growable: false),
    totalCycles: plan.totalCycles,
    totalDurationMs: plan.totalDurationMs,
  );

  final renderer = TimelineRenderer(sampleRate: bank.sampleRate);
  final pcm = renderer.render(filtered, bank);
  return WavIo.encode(pcm, bank.sampleRate);
}
