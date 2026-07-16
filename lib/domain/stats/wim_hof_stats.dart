import '../models/session_record.dart';

/// Одна ВХ-сессия для графика прогресса задержек (ПЛАН П19).
class WimHofSessionStat {
  /// Локальное время старта сессии.
  final DateTime date;

  /// Лучшая задержка сессии, секунды (max по раундам).
  final int bestSec;

  /// Все задержки раундов, секунды (для подписи/тултипа).
  final List<int> rounds;

  const WimHofSessionStat({
    required this.date,
    required this.bestSec,
    required this.rounds,
  });
}

/// Агрегации прогресса метода Вима Хофа по журналу сессий (ПЛАН П19).
/// Чистый Dart; данные уже копятся в [SessionRecord.retentionsSec] с v0.6.0 —
/// мигрировать нечего, у старых записей поле null (отфильтровываются).
abstract final class WimHofStats {
  static const techniqueId = 'wim_hof';

  /// Хронологический список ВХ-сессий с непустыми задержками, по возрастанию
  /// даты. Чужие техники и записи без задержек (старые версии) отброшены.
  static List<WimHofSessionStat> progress(Iterable<SessionRecord> log) {
    final stats = <WimHofSessionStat>[];
    for (final r in log) {
      if (r.techniqueId != techniqueId) continue;
      final rounds = r.retentionsSec;
      if (rounds == null || rounds.isEmpty) continue;
      stats.add(WimHofSessionStat(
        date: r.startedAt,
        bestSec: rounds.reduce((a, b) => a > b ? a : b),
        rounds: rounds,
      ));
    }
    stats.sort((a, b) => a.date.compareTo(b.date));
    return stats;
  }

  /// Лучшая задержка за всю историю; null — данных нет.
  static int? bestEver(Iterable<SessionRecord> log) {
    int? best;
    for (final s in progress(log)) {
      if (best == null || s.bestSec > best) best = s.bestSec;
    }
    return best;
  }

  /// Лучшая задержка за календарный день [day] (пояс устройства); null — за
  /// день данных нет.
  static int? bestOnDay(Iterable<SessionRecord> log, DateTime day) {
    int? best;
    for (final s in progress(log)) {
      if (s.date.year != day.year ||
          s.date.month != day.month ||
          s.date.day != day.day) {
        continue;
      }
      if (best == null || s.bestSec > best) best = s.bestSec;
    }
    return best;
  }
}
