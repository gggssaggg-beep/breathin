import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';

import 'session_audio_handler.dart';

/// Глобальный обработчик аудио-сессии; null — аудио-путь недоступен
/// (юнит-тесты, платформа без плагинов) и раннер работает от Ticker.
SessionAudioHandler? sessionAudioHandler;

/// Инициализация аудио-подсистемы; вызывать из main() до runApp.
///
/// Конфигурация audio_session — ПЛАН §3.3: категория playback,
/// mixWithOthers=false (наша практика — основной звук), usage=media.
/// Любой сбой (нет плагинов — тесты) тихо оставляет
/// [sessionAudioHandler] == null.
Future<void> initSessionAudio() async {
  try {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    sessionAudioHandler = await AudioService.init(
      builder: SessionAudioHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'app.dyshi.breathin.session',
        androidNotificationChannelName: 'Дыхательная сессия',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
  } catch (_) {
    sessionAudioHandler = null;
  }
}
