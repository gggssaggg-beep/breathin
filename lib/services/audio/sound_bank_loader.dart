import 'dart:typed_data';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import 'sound_preferences.dart';
import 'timeline_renderer.dart';
import 'wav_io.dart';

/// Клипы-события, общие для всех вариантов звука (+ фиксированные волны
/// вдоха/выдоха для one-shot'ов Вима Хофа — его задержка недетерминирована,
/// таймлайн не собрать).
const Map<ClipId, String> soundAssetPaths = {
  ClipId.inhale: 'assets/audio/common/breath_in.wav',
  ClipId.exhale: 'assets/audio/common/breath_out.wav',
  ClipId.prepBeep: 'assets/audio/common/prep_beep.wav',
  ClipId.gong: 'assets/audio/common/gong.wav',
  ClipId.tick: 'assets/audio/common/tick.wav',
  ClipId.tickAccent: 'assets/audio/common/tick_accent.wav',
};

/// Пути клипов набора [set]. «Поток» фазовых клипов НЕ имеет (фазы поёт
/// синтез — включать клипы нельзя, звучали бы дважды); «Чаши» кладут чашу/
/// колокольчики на старты фаз. Покрыто тестом полноты.
Map<ClipId, String> assetsForSet(SoundSet set) {
  switch (set) {
    case SoundSet.flow:
      return {
        ClipId.prepBeep: soundAssetPaths[ClipId.prepBeep]!,
        ClipId.gong: soundAssetPaths[ClipId.gong]!,
        ClipId.tick: soundAssetPaths[ClipId.tick]!,
        ClipId.tickAccent: soundAssetPaths[ClipId.tickAccent]!,
      };
    case SoundSet.bowls:
      return {
        ClipId.inhale: 'assets/audio/sets/bowls/inhale.wav',
        ClipId.holdIn: 'assets/audio/sets/bowls/hold_in.wav',
        ClipId.exhale: 'assets/audio/sets/bowls/exhale.wav',
        ClipId.holdOut: 'assets/audio/sets/bowls/hold_out.wav',
        ClipId.prepBeep: soundAssetPaths[ClipId.prepBeep]!,
        ClipId.gong: soundAssetPaths[ClipId.gong]!,
        ClipId.tick: 'assets/audio/sets/bowls/tick.wav',
        ClipId.tickAccent: 'assets/audio/sets/bowls/tick_accent.wav',
      };
  }
}

/// Загружает и декодирует клипы варианта [set] из ассетов приложения.
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
  return SoundBank(
    sampleRate: sampleRate!,
    clips: clips,
    synthPhases: set == SoundSet.flow,
  );
}
