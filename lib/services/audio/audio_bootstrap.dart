import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../l10n/system_l10n.dart';
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
    if (kIsWeb) {
      // Веб: foreground-сервис/локскрин-контролы не нужны и не существуют,
      // а AudioService.init на вебе (android-конфиг) — источник сбоев,
      // роняющих звук в визуал-режим. just_audio играет Blob-URL напрямую —
      // достаточно голого обработчика без audio_service.
      sessionAudioHandler = SessionAudioHandler();
      return;
    }
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    sessionAudioHandler = await AudioService.init(
      builder: SessionAudioHandler.new,
      config: AudioServiceConfig(
        androidNotificationChannelId: 'app.dyshi.breathin.session',
        // Имя канала видно в системных настройках уведомлений — по локали
        // системы (контекста здесь ещё нет; Android обновит имя при init).
        androidNotificationChannelName: systemL10n().sessionMediaTitle,
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
  } catch (_) {
    sessionAudioHandler = null;
  }
}
