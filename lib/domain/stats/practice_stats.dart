import '../models/session_record.dart';

/// Агрегации локальной статистики практик (ТЗ §5, ПЛАН П11): календарь,
/// минуты, streak. Чистый Dart; все даты — локальные (пояс устройства,
/// без сети — ТЗ §7). День определяется календарной датой локального времени.
abstract final class PracticeStats {
  /// Календарная дата (без времени) для локального момента [t].
  static DateTime dayKey(DateTime t) => DateTime(t.year, t.month, t.day);

  /// Дни месяца [year]-[month], в которые была практика (номера 1..31).
  static Set<int> practisedDays(
    Iterable<SessionRecord> records,
    int year,
    int month,
  ) {
    return records
        .where((r) => r.startedAt.year == year && r.startedAt.month == month)
        .map((r) => r.startedAt.day)
        .toSet();
  }

  /// Сумма минут практики по дням месяца: день → минуты (округление вверх,
  /// чтобы минутная сессия не выглядела нулём).
  static Map<int, int> minutesByDay(
    Iterable<SessionRecord> records,
    int year,
    int month,
  ) {
    final result = <int, int>{};
    for (final r in records) {
      if (r.startedAt.year != year || r.startedAt.month != month) continue;
      result.update(
        r.startedAt.day,
        (m) => m + (r.durationSec + 59) ~/ 60,
        ifAbsent: () => (r.durationSec + 59) ~/ 60,
      );
    }
    return result;
  }

  /// Минуты практики за месяц.
  static int minutesInMonth(
    Iterable<SessionRecord> records,
    int year,
    int month,
  ) =>
      minutesByDay(records, year, month)
          .values
          .fold(0, (a, b) => a + b);

  /// Число сессий за месяц.
  static int sessionsInMonth(
    Iterable<SessionRecord> records,
    int year,
    int month,
  ) =>
      records
          .where((r) => r.startedAt.year == year && r.startedAt.month == month)
          .length;

  /// Разбивка месяца по техникам: id → (сессии, минуты), отсортирована
  /// по минутам по убыванию.
  static List<(String, ({int sessions, int minutes}))> byTechnique(
    Iterable<SessionRecord> records,
    int year,
    int month,
  ) {
    final acc = <String, (int, int)>{};
    for (final r in records) {
      if (r.startedAt.year != year || r.startedAt.month != month) continue;
      final prev = acc[r.techniqueId] ?? (0, 0);
      acc[r.techniqueId] =
          (prev.$1 + 1, prev.$2 + (r.durationSec + 59) ~/ 60);
    }
    final entries = [
      for (final e in acc.entries)
        (e.key, (sessions: e.value.$1, minutes: e.value.$2)),
    ]..sort((a, b) => b.$2.minutes.compareTo(a.$2.minutes));
    return entries;
  }

  /// Частоты вариантов паттерна техники за месяц: «4-8-8» → сколько сессий.
  /// Записи без варианта (старые версии) не учитываются. Порядок — по
  /// убыванию частоты (влад. §15: виден прогресс упрощённый → полный).
  static List<(String, int)> variantsFor(
    Iterable<SessionRecord> records,
    int year,
    int month,
    String techniqueId,
  ) {
    final acc = <String, int>{};
    for (final r in records) {
      if (r.techniqueId != techniqueId ||
          r.startedAt.year != year ||
          r.startedAt.month != month) {
        continue;
      }
      final v = r.variant;
      if (v == null) continue;
      acc.update(v, (n) => n + 1, ifAbsent: () => 1);
    }
    final entries = [for (final e in acc.entries) (e.key, e.value)]
      ..sort((a, b) => b.$2.compareTo(a.$2));
    return entries;
  }

  /// Streak — число дней подряд с практикой, заканчивая сегодня.
  ///
  /// Правило: если сегодня практики ещё не было, серия НЕ рвётся до конца
  /// дня — отсчёт начинается со вчера (стандартное поведение streak-механик).
  /// [today] — для тестируемости; по умолчанию — текущая локальная дата.
  static int streakDays(Iterable<SessionRecord> records, {DateTime? today}) {
    final days = records.map((r) => dayKey(r.startedAt)).toSet();
    if (days.isEmpty) return 0;
    var cursor = dayKey(today ?? DateTime.now());
    // DST-безопасный шаг на день назад: Duration(days: 1) в переходные сутки
    // короче/длиннее 24 ч и может сдвинуть дату на два дня. Конструктор с
    // day-1 Dart нормализует (в т.ч. переход через границу месяца/года).
    if (!days.contains(cursor)) {
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return streak;
  }
}
