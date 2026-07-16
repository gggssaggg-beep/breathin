import '../../domain/models/technique.dart';

/// Вибро-паттерны смены фазы (ПЛАН §6, ТЗ §3.3): короткая = вдох,
/// двойная = задержка, длинная = выдох. Режим для полной тишины.
///
/// Формат совместим с пакетом `vibration`: список миллисекунд
/// `[пауза, вибро, пауза, вибро, …]` (нечётные индексы — вибрация).
/// Здесь только данные — вызов плагина живёт в платформенном сервисе,
/// поэтому маппинг тестируется без устройства.
class VibrationPattern {
  static const int _short = 80;
  static const int _long = 300;
  static const int _gap = 90;

  /// Паттерн для начала фазы. Обе задержки (holdIn/holdOut) — двойной импульс.
  static List<int> forPhase(PhaseKind phase) {
    switch (phase) {
      case PhaseKind.inhale:
        return const [0, _short];
      case PhaseKind.exhale:
        return const [0, _long];
      case PhaseKind.holdIn:
      case PhaseKind.holdOut:
        return const [0, _short, _gap, _short];
    }
  }

  /// Одиночный короткий импульс для тиков обратного отсчёта подготовки.
  static List<int> get prepTick => const [0, _short];

  /// Тройной импульс завершения сессии (сопровождает гонг).
  static List<int> get sessionEnd =>
      const [0, _short, _gap, _short, _gap, _long];

  /// Подсказки смены ноздри (таймер-режим, ПЛАН §10): левая — один импульс,
  /// правая — два. Различимо с закрытыми глазами.
  static List<int> get cueLeft => const [0, _short];
  static List<int> get cueRight => const [0, _short, _gap, _short];
}
