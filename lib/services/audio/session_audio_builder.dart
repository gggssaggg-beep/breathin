import 'dart:typed_data';

import '../../domain/engine/session_plan.dart';
import '../../domain/models/feedback_channels.dart';
import 'timeline_renderer.dart';
import 'wav_io.dart';

/// Собирает WAV всей сессии из плана с учётом каналов сопровождения
/// (ТЗ §3.3): звук фаз, метроном и/или голос (П8). Чистая логика поверх
/// [TimelineRenderer] — тестируется с синтетическим [SoundBank]. Без dart:io:
/// файл-запись живёт в io-таргете (wav_target/), web собирает Blob.
///
/// Возвращает null, если аудио-каналы выключены (звук, метроном и голос) —
/// вызывающая сторона тогда не строит аудио-путь вовсе.
///
/// ВАЖНО: буфер тянется до plan.totalDurationMs даже если последние
/// миллисекунды — тишина: непрерывный поток и есть механизм «ОС не
/// усыпляет процесс» (ПЛАН §3.3 п.2).
Uint8List? buildSessionWav(
  SessionPlan plan,
  SoundBank bank,
  FeedbackChannels feedback, {
  VoiceBank? voice,
}) {
  final filtered = audioPlanFor(plan, feedback);
  if (filtered == null) return null;

  final eff = effectiveBank(bank, feedback);
  final renderer = TimelineRenderer(sampleRate: bank.sampleRate);
  final pcm = renderer.render(filtered, eff, voice: voice);
  return WavIo.encode(pcm, bank.sampleRate);
}

/// План только со звучащими событиями по каналам [feedback];
/// null — аудио-каналы выключены. Публичный: используется io/web-таргетами.
///
/// Голос (П8) держит события фаз и подготовки в плане даже при выключенном
/// «Звуке» — клипы набора для них тогда режет [effectiveBank].
SessionPlan? audioPlanFor(SessionPlan plan, FeedbackChannels feedback) {
  if (!feedback.sound && !feedback.metronome && !feedback.voice) return null;

  bool keep(EngineEvent e) {
    switch (e.type) {
      case EngineEventType.prepCountdown:
      case EngineEventType.phaseStart:
        return feedback.sound || feedback.voice;
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

/// Банк с учётом каналов: при выключенном «Звуке» события фаз/подготовки
/// живут в плане ради голоса — чтобы набор при этом молчал, от него остаются
/// только тики метронома (отдельный канал). При включённом звуке банк не
/// трогаем: голос — аддитивный слой поверх выбранного набора.
SoundBank effectiveBank(SoundBank bank, FeedbackChannels feedback) {
  if (feedback.sound) return bank;
  return SoundBank(
    sampleRate: bank.sampleRate,
    clips: {
      for (final id in const [ClipId.tick, ClipId.tickAccent])
        if (bank.clips[id] != null) id: bank.clips[id]!,
    },
  );
}
