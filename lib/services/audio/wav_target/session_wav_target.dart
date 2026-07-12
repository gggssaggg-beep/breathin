/// Подготовка WAV-источника сессии: платформенная развилка.
/// io (Android/iOS/desktop) — временный файл; web — Blob-URL в памяти
/// (файловой системы нет). Выбор реализации — условным импортом.
library;

export 'session_wav_target_io.dart'
    if (dart.library.js_interop) 'session_wav_target_web.dart';

/// Готовый источник для плеера + освобождение ресурса после сессии.
class SessionWavTarget {
  /// Путь к файлу (io) либо blob:-URL (web) — понимает
  /// SessionAudioHandler.loadSessionFile.
  final String source;

  /// Удалить файл / отозвать URL. Ошибки глотаются вызывающим.
  final Future<void> Function() cleanup;

  const SessionWavTarget({required this.source, required this.cleanup});
}
