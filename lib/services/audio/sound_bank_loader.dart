import 'dart:typed_data';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import 'harp_melody.dart';
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

/// Фоновый медитативный трек (бесшовный луп): дрон живой виолончели +
/// «светлячки» арфы (tools/prepare_live_audio.py). Играется just_audio
/// отдельным слоем, в строгий таймлайн не входит (ПЛАН §10).
const String backgroundLoopAsset = 'assets/audio/common/background_loop.ogg';

/// Пути нот лесенки «Арфы» (пентатоника C4..E5, live-семплы VSCO CC0).
List<String> harpScalePaths() => [
      for (var i = 0; i < harpScaleSize; i++)
        'assets/audio/sets/harp/note_$i.wav',
    ];

/// Пути клипов набора [set]. «Арфа» фазовых клипов НЕ имеет (фазы поёт
/// мелодия из лесенки); «Чаши» кладут чашу/колокольчики на старты фаз.
Map<ClipId, String> assetsForSet(SoundSet set) {
  switch (set) {
    case SoundSet.harp:
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

/// Загружает и декодирует звук варианта [set] из ассетов приложения.
///
/// [bundle] внедряется для тестов (rootBundle требует биндинга/ассетов).
/// Все клипы обязаны иметь один sample rate (гарантия пайплайна ассетов);
/// расхождение — [FormatException]: лучше упасть громко на старте сессии,
/// чем тихо рассинхронизировать таймлайн.
Future<SoundBank> loadSoundBank(
  SoundSet set, {
  AssetBundle? bundle,
}) async {
  final b = bundle ?? rootBundle;
  int? sampleRate;

  Future<Int16List> loadWav(String path) async {
    final data = await b.load(path);
    final wav = WavIo.decode(data.buffer.asUint8List());
    sampleRate ??= wav.sampleRate;
    if (wav.sampleRate != sampleRate) {
      throw FormatException(
        '$path: sample rate ${wav.sampleRate} != $sampleRate',
      );
    }
    return wav.samples;
  }

  final clips = <ClipId, Int16List>{};
  for (final entry in assetsForSet(set).entries) {
    clips[entry.key] = await loadWav(entry.value);
  }
  final scale = set == SoundSet.harp
      ? [for (final p in harpScalePaths()) await loadWav(p)]
      : null;
  return SoundBank(sampleRate: sampleRate!, clips: clips, scale: scale);
}

/// Загружает голосовые подсказки (П8) по языку приложения: `ru` — все
/// русские локали, остальное — `en` (как резолюция MaterialApp). Голоса и
/// пайплайн обработки — assets/audio/voice/README.md; SR совпадает с
/// наборами звука (44,1 кГц) — рендерер микширует без ресемпла.
Future<VoiceBank> loadVoiceBank(
  String languageCode, {
  AssetBundle? bundle,
}) async {
  final lang = languageCode.toLowerCase().startsWith('ru') ? 'ru' : 'en';
  final b = bundle ?? rootBundle;
  int? sampleRate;

  Future<Int16List> loadWav(String name) async {
    final path = 'assets/audio/voice/$lang/$name.wav';
    final data = await b.load(path);
    final wav = WavIo.decode(data.buffer.asUint8List());
    sampleRate ??= wav.sampleRate;
    if (wav.sampleRate != sampleRate) {
      throw FormatException(
        '$path: sample rate ${wav.sampleRate} != $sampleRate',
      );
    }
    return wav.samples;
  }

  final inhale = await loadWav('inhale');
  final exhale = await loadWav('exhale');
  final hold = await loadWav('hold');
  final prep = await loadWav('prep');
  final inhaleSlow = await loadWav('inhale_slow');
  final exhaleSlow = await loadWav('exhale_slow');
  return VoiceBank(
    sampleRate: sampleRate!,
    inhale: inhale,
    exhale: exhale,
    hold: hold,
    prep: prep,
    inhaleSlow: inhaleSlow,
    exhaleSlow: exhaleSlow,
  );
}
