import '../models/session_record.dart';
import 'practice_stats.dart';

/// Метрика челленджа (соответствует check-констрейнту в схеме Supabase,
/// docs/supabase/schema.sql).
enum ChallengeMetric { sessions, minutes, streak }

/// Локальный прогресс пользователя в челлендже: вычисляется из истории
/// сессий по окну дат [startsOn]..[endsOn] (обе границы включительно,
/// календарные даты локального пояса). Чистый Dart; результат периодически
/// синкается в challenge_participants.progress.
///
/// * [ChallengeMetric.sessions] — число сессий в окне;
/// * [ChallengeMetric.minutes] — минуты практики (округление каждой сессии
///   вверх — как в календаре);
/// * [ChallengeMetric.streak] — максимальная серия дней подряд внутри окна.
int challengeProgress(
  Iterable<SessionRecord> records,
  ChallengeMetric metric,
  DateTime startsOn,
  DateTime endsOn,
) {
  final from = PracticeStats.dayKey(startsOn);
  final to = PracticeStats.dayKey(endsOn);
  bool inWindow(SessionRecord r) {
    final d = PracticeStats.dayKey(r.startedAt);
    return !d.isBefore(from) && !d.isAfter(to);
  }

  final windowRecords = records.where(inWindow);
  switch (metric) {
    case ChallengeMetric.sessions:
      return windowRecords.length;
    case ChallengeMetric.minutes:
      return windowRecords.fold(0, (a, r) => a + (r.durationSec + 59) ~/ 60);
    case ChallengeMetric.streak:
      final days = windowRecords
          .map((r) => PracticeStats.dayKey(r.startedAt))
          .toSet();
      var best = 0;
      for (final d in days) {
        // Начало серии — день, которому не предшествует практикованный.
        // Шаг на день через конструктор (Dart нормализует ±day) — DST-безопасно,
        // в отличие от Duration(days: 1), который в переходные сутки ≠ 24 ч.
        if (days.contains(DateTime(d.year, d.month, d.day - 1))) continue;
        var len = 0;
        var cursor = d;
        while (days.contains(cursor)) {
          len++;
          cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
        }
        if (len > best) best = len;
      }
      return best;
  }
}
