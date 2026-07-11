import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

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

  /// Загружает WAV-файл сессии и публикует MediaItem (название на локскрине).
  Future<void> loadSessionFile(
    String path, {
    required String title,
    required Duration duration,
  }) async {
    mediaItem.add(MediaItem(
      id: path,
      title: title,
      album: 'Дыши',
      duration: duration,
    ));
    await player.setFilePath(path);
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
