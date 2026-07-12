import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../../../domain/engine/session_plan.dart';
import '../../../domain/models/feedback_channels.dart';
import '../session_audio_builder.dart';
import '../timeline_renderer.dart';
import '../wav_io.dart';
import 'session_wav_target.dart';

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
  final filtered = audioPlanFor(plan, feedback);
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

/// io-реализация: WAV пишется во временный файл чанками (память O(чанка),
/// ревью К2); фиксированное имя — кэш не растёт (К3), cleanup удаляет файл.
Future<SessionWavTarget?> prepareSessionWav(
  SessionPlan plan,
  SoundBank bank,
  FeedbackChannels feedback,
) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/session_current.wav');
  final written = await writeSessionWavFile(plan, bank, feedback, file);
  if (!written) return null;
  return SessionWavTarget(
    source: file.path,
    cleanup: () => file.delete().then((_) {}),
  );
}
