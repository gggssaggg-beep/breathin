import 'dart:typed_data';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import 'sound_preferences.dart';
import 'timeline_renderer.dart';
import 'wav_io.dart';

/// Пути ассетов по наборам (см. tools/generate_audio.py, ПЛАН §10.2).
/// Клипы фаз/тиков лежат в sets/<набор>/, события сессии (отсчёт, гонг) —
/// общие в common/. Манифест JSON Dart не читает — пути вшиты и покрыты
/// тестом полноты (каждый ClipId в каждом наборе).
Map<ClipId, String> assetsForSet(SoundSet set) {
  final dir = switch (set) {
    SoundSet.nature => 'nature',
    SoundSet.minimal => 'minimal',
  };
  return {
    ClipId.inhale: 'assets/audio/sets/$dir/inhale.wav',
    ClipId.holdIn: 'assets/audio/sets/$dir/hold_in.wav',
    ClipId.exhale: 'assets/audio/sets/$dir/exhale.wav',
    ClipId.holdOut: 'assets/audio/sets/$dir/hold_out.wav',
    ClipId.tick: 'assets/audio/sets/$dir/tick.wav',
    ClipId.tickAccent: 'assets/audio/sets/$dir/tick_accent.wav',
    ClipId.prepBeep: 'assets/audio/common/prep_beep.wav',
    ClipId.gong: 'assets/audio/common/gong.wav',
  };
}

/// Загружает и декодирует звуковой набор [set] из ассетов приложения.
///
/// [bundle] внедряется для тестов (rootBundle требует биндинга/ассетов).
/// Все клипы обязаны иметь один sample rate (гарантия generate_audio.py);
/// расхождение — [FormatException]: лучше упасть громко на старте сессии,
/// чем тихо рассинхронизировать таймлайн.
Future<SoundBank> loadSoundBank(
  SoundSet set, {
  AssetBundle? bundle,
}) async {
  final b = bundle ?? rootBundle;
  int? sampleRate;
  final clips = <ClipId, Int16List>{};
  for (final entry in assetsForSet(set).entries) {
    final data = await b.load(entry.value);
    final wav = WavIo.decode(data.buffer.asUint8List());
    sampleRate ??= wav.sampleRate;
    if (wav.sampleRate != sampleRate) {
      throw FormatException(
        '${entry.value}: sample rate ${wav.sampleRate} != $sampleRate',
      );
    }
    clips[entry.key] = wav.samples;
  }
  return SoundBank(sampleRate: sampleRate!, clips: clips);
}
