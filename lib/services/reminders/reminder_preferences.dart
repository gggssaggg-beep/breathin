import 'package:shared_preferences/shared_preferences.dart';

/// Персист тумблера «вечернее напоминание о серии» (С1). Дефолт — ВКЛ
/// (решение владельца 2026-07-16): системное разрешение на уведомления всё
/// равно запрашивается отдельно, а выключить можно в настройках.
class ReminderPreferencesStore {
  static const _key = 'reminders.streak_evening.v1';

  Future<bool> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? true;
    } catch (_) {
      return false; // без prefs (тесты) напоминания не планируем
    }
  }

  Future<void> save(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, enabled);
  }
}
