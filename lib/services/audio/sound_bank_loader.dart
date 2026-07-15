import 'dart:typed_data';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import 'timeline_renderer.dart';
import 'wav_io.dart';

/// Пути клипов-событий (см. tools/generate_audio.py). Единственный звуковой
/// вариант — «прибой» (решение владельца 2026-07-15): фазы синтезируются
/// рендерером (surf_synth.dart), клипами остались события — отсчёт, гонг,
/// тики метронома — и фиксированные волны вдоха/выдоха для one-shot'ов
/// Вима Хофа. Покрыто тестом полноты (каждый ClipId имеет путь).
const Map<ClipId, String> soundAssetPaths = {
  ClipId.inhale: 'assets/audio/common/breath_in.wav',
  ClipId.exhale: 'assets/audio/common/breath_out.wav',
  ClipId.prepBeep: 'assets/audio/common/prep_beep.wav',
  ClipId.gong: 'assets/audio/common/gong.wav',
  ClipId.tick: 'assets/audio/common/tick.wav',
  ClipId.tickAccent: 'assets/audio/common/tick_accent.wav',
};

/// Загружает и декодирует клипы-события из ассетов приложения.
///
/// [bundle] внедряется для тестов (rootBundle требует биндинга/ассетов).
/// Все клипы обязаны иметь один sample rate (гарантия generate_audio.py);
/// расхождение — [FormatException]: лучше упасть громко на старте сессии,
/// чем тихо рассинхронизировать таймлайн.
Future<SoundBank> loadSoundBank({AssetBundle? bundle}) async {
  final b = bundle ?? rootBundle;
  int? sampleRate;
  final clips = <ClipId, Int16List>{};
  for (final entry in soundAssetPaths.entries) {
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
