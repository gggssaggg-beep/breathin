import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import '../../../domain/engine/session_plan.dart';
import '../../../domain/models/feedback_channels.dart';
import '../session_audio_builder.dart';
import '../timeline_renderer.dart';
import '../wav_io.dart';
import 'session_wav_target.dart';

/// Веб-реализация: WAV собирается чанками в Blob → object-URL для плеера
/// (файловой системы нет; StreamAudioSource just_audio на вебе не работает —
/// его проксирует dart:io HttpServer). cleanup отзывает URL.
///
/// Кап 20 минут аудио (~106 МБ PCM): длиннее на вебе не собираем — браузер
/// на телефоне столько в RAM не потянет; сессия честно идёт в визуальном
/// режиме (известное ограничение PWA, см. ПЛАН/память проекта).
Future<SessionWavTarget?> prepareSessionWav(
  SessionPlan plan,
  SoundBank bank,
  FeedbackChannels feedback, {
  VoiceBank? voice,
}) async {
  final filtered = audioPlanFor(plan, feedback);
  if (filtered == null) return null;

  final eff = effectiveBank(bank, feedback);
  final renderer = TimelineRenderer(sampleRate: bank.sampleRate);
  final total = renderer.totalSamplesFor(filtered, eff, voice: voice);
  if (total > bank.sampleRate * 1200) return null; // > 20 мин — без аудио

  final chunkSamples = 10 * bank.sampleRate;
  final parts = <JSUint8Array>[
    WavIo.header(total, bank.sampleRate).toJS,
  ];
  for (var start = 0; start < total; start += chunkSamples) {
    final rest = total - start;
    final chunk = Int16List(rest < chunkSamples ? rest : chunkSamples);
    renderer.renderRange(filtered, eff, chunk, start, voice: voice);
    parts.add(WavIo.pcmBytes(chunk).toJS);
    // Веб однопоточный: без уступки между чанками рендер минутной сессии
    // блокирует UI на секунды — визуал уже идущей сессии замирает.
    await Future<void>.delayed(Duration.zero);
  }

  final blob = web.Blob(
    parts.toJS,
    web.BlobPropertyBag(type: 'audio/wav'),
  );
  final url = web.URL.createObjectURL(blob);
  return SessionWavTarget(
    source: url,
    cleanup: () async => web.URL.revokeObjectURL(url),
  );
}
