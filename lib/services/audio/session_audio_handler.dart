import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:just_audio/just_audio.dart';

import '../../l10n/system_l10n.dart';

/// Медиа-обработчик сессии: обёртка just_audio-плеера под audio_service.
///
/// Именно он делает звук «живым» при выключенном экране: Android поднимает
/// foreground service mediaPlayback с уведомлением (пауза/стоп на локскрине),
/// iOS получает категорию playback (ПЛАН §3.3 «Фон и экран»).
///
/// Часы движка = [player].position — единственный источник времени для
/// вибрации и визуала (ПЛАН §3.3 п.4).
class SessionAudioHandler extends BaseAudioHandler {
  final AudioPlayer player = AudioPlayer();

  SessionAudioHandler() {
    // Транслируем состояние плеера в playbackState для локскрин-контролов.
    player.playbackEventStream.listen((event) {
      playbackState.add(playbackState.value.copyWith(
        controls: [
          if (player.playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
        ],
        systemActions: const {MediaAction.seek},
        processingState: switch (player.processingState) {
          ProcessingState.idle => AudioProcessingState.idle,
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.ready => AudioProcessingState.ready,
          ProcessingState.completed => AudioProcessingState.completed,
        },
        playing: player.playing,
        updatePosition: player.position,
      ));
    });
  }

  /// Загружает WAV сессии и публикует MediaItem (название на локскрине).
  /// [source] — путь к файлу (io) или Blob-URL (web).
  Future<void> loadSessionFile(
    String source, {
    required String title,
    required Duration duration,
  }) async {
    mediaItem.add(MediaItem(
      id: source,
      title: title,
      // Альбом на локскрине — имя приложения по системной локали.
      album: systemL10n().appTitle,
      duration: duration,
    ));
    // На вебе источник — Blob-URL: setFilePath (Uri.file) его не понимает,
    // нужен setUrl. На мобилках — файловый путь.
    if (kIsWeb) {
      await player.setUrl(source);
    } else {
      await player.setFilePath(source);
    }
  }

  /// Загружает зацикленный ассет (фоновый трек таймер-режима, ПЛАН §10) —
  /// якорь foreground-сервиса вместо пре-рендеренного WAV. Время сессии
  /// считают Dart-часы экрана (луп короче сессии), поэтому [sessionDuration]
  /// задаёт длительность MediaItem, а не длину лупа.
  Future<void> loadLoopingAsset(
    String asset, {
    required String title,
    Duration? sessionDuration,
  }) async {
    mediaItem.add(MediaItem(
      id: asset,
      title: title,
      album: systemL10n().appTitle,
      duration: sessionDuration,
    ));
    await player.setAsset(asset);
    await player.setLoopMode(LoopMode.all);
  }

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> stop() async {
    await player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => player.seek(position);
}
