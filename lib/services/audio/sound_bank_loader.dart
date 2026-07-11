import 'dart:typed_data';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import 'timeline_renderer.dart';
import 'wav_io.dart';

/// Пути ассетов набора «Минимал» (см. tools/generate_audio.py, ПЛАН §10.2).
/// Наборы этапа 3 добавятся через манифест; для П4 достаточно констант —
/// набор один и вшит в pubspec.
const Map<ClipId, String> _minimalSetAssets = {
  ClipId.inhale: 'assets/audio/sets/minimal/inhale.wav',
  ClipId.holdIn: 'assets/audio/sets/minimal/hold_in.wav',
  ClipId.exhale: 'assets/audio/sets/minimal/exhale.wav',
  ClipId.holdOut: 'assets/audio/sets/minimal/hold_out.wav',
  ClipId.tick: 'assets/audio/sets/minimal/tick.wav',
  ClipId.tickAccent: 'assets/audio/sets/minimal/tick_accent.wav',
  ClipId.prepBeep: 'assets/audio/common/prep_beep.wav',
  ClipId.gong: 'assets/audio/common/gong.wav',
};

/// Загружает и декодирует звуковой набор из ассетов приложения.
///
/// [bundle] внедряется для тестов (rootBundle требует биндинга/ассетов).
/// Все клипы обязаны иметь один sample rate (гарантия generate_audio.py);
/// расхождение — [FormatException]: лучше упасть громко на старте сессии,
/// чем тихо рассинхронизировать таймлайн.
Future<SoundBank> loadMinimalSoundBank({AssetBundle? bundle}) async {
  final b = bundle ?? rootBundle;
  int? sampleRate;
  final clips = <ClipId, Int16List>{};
  for (final entry in _minimalSetAssets.entries) {
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
