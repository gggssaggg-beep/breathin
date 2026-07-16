import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/models/session_record.dart';
import '../../domain/stats/practice_stats.dart';

/// Момент следующего вечернего напоминания о серии (С1, system review
/// 2026-07-16); null — напоминать не о чем. Чистая функция — юниты.
///
/// Правила:
/// * серии нет (streak == 0) — молчим (нечего терять);
/// * сегодня уже практиковали — след. напоминание завтра в 20:00
///   (серия жива до конца завтрашнего дня);
/// * сегодня не практиковали и ещё нет 20:00 — сегодня в 20:00;
/// * вечер без практики — уже не дёргаем (поздно менять планы человеку).
DateTime? nextStreakReminderAt(Iterable<SessionRecord> records, DateTime now) {
  final streak = PracticeStats.streakDays(records, today: now);
  if (streak == 0) return null;
  final todayKey = PracticeStats.dayKey(now);
  final practisedToday =
      records.any((r) => PracticeStats.dayKey(r.startedAt) == todayKey);
  if (practisedToday) {
    return DateTime(now.year, now.month, now.day + 1, 20);
  }
  final today20 = DateTime(now.year, now.month, now.day, 20);
  return now.isBefore(today20) ? today20 : null;
}

/// Планировщик вечернего напоминания «огонёк ждёт» через
/// flutter_local_notifications. Всегда ОДНО отложенное уведомление
/// (id [_id]): каждый выход на главный экран перепланирует его заново —
/// самообновляющаяся схема без фоновых задач. Любой сбой платформы
/// (тесты, web, старый Android) — тихий no-op.
class StreakReminder {
  static const _id = 700;
  static const _channelId = 'streak_reminder';

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<bool> _ensureInit() async {
    if (_initialized) return true;
    try {
      tzdata.initializeTimeZones();
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      _initialized = true;
      return true;
    } catch (_) {
      return false; // платформа без плагина/зоны — работаем без напоминаний
    }
  }

  /// Перепланирует напоминание по журналу. [enabled] == false — снимает.
  /// [title]/[body] — уже локализованные строки (даёт вызывающий экран).
  static Future<void> reschedule(
    List<SessionRecord> records, {
    required bool enabled,
    required String title,
    required String body,
    DateTime? now,
  }) async {
    if (!await _ensureInit()) return;
    try {
      await _plugin.cancel(_id);
      if (!enabled) return;
      final at = nextStreakReminderAt(records, now ?? DateTime.now());
      if (at == null) return;
      await _plugin.zonedSchedule(
        _id,
        title,
        body,
        tz.TZDateTime.local(at.year, at.month, at.day, at.hour, at.minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Streak reminder',
            channelDescription: 'Evening reminder to keep the streak',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        // Неточный будильник: минута-другая не важна, зато не нужно
        // разрешение SCHEDULE_EXACT_ALARM (Android 12+).
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      // Отказ платформы — приложение полностью работает без напоминаний.
    }
  }
}
