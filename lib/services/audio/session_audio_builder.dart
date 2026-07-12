import 'dart:io';
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
  final filtered = _audioPlan(plan, feedback);
  if (filtered == null) return null;

  final renderer = TimelineRenderer(sampleRate: bank.sampleRate);
  final pcm = renderer.render(filtered, bank);
  return WavIo.encode(pcm, bank.sampleRate);
}

/// План только со звучащими событиями по каналам [feedback];
/// null — аудио-каналы выключены.
SessionPlan? _audioPlan(SessionPlan plan, FeedbackChannels feedback) {
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

  return SessionPlan(
    events: plan.events.where(keep).toList(growable: false),
    totalCycles: plan.totalCycles,
    totalDurationMs: plan.totalDurationMs,
  );
}

/// Пишет WAV сессии в [out] чанками по [chunkSeconds]: пиковая память —
/// O(чанка) вместо O(всей сессии) (ревью К2: часовой таймлайн, доступный из
/// UI через таймер/100 циклов, целиком в RAM ронял процесс).
/// true — файл записан; false — аудио-каналы выключены (файл не тронут).
Future<bool> writeSessionWavFile(
  SessionPlan plan,
  SoundBank bank,
  FeedbackChannels feedback,
  File out, {
  int chunkSeconds = 10,
}) async {
  final filtered = _audioPlan(plan, feedback);
  if (filtered == null) return false;

  final renderer = TimelineRenderer(sampleRate: bank.sampleRate);
  final total = renderer.totalSamplesFor(filtered, bank);
  final chunkSamples = chunkSeconds * bank.sampleRate;
  final sink = out.openWrite();
  try {
    sink.add(WavIo.header(total, bank.sampleRate));
    for (var start = 0; start < total; start += chunkSamples) {
      final rest = total - start;
      final chunk = Int16List(rest < chunkSamples ? rest : chunkSamples);
      renderer.renderRange(filtered, bank, chunk, start);
      sink.add(WavIo.pcmBytes(chunk));
    }
    await sink.flush();
  } finally {
    await sink.close();
  }
  return true;
}
