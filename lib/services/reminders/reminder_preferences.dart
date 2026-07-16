import 'package:shared_preferences/shared_preferences.dart';

/// Персист тумблера «вечернее напоминание о серии» (С1). Дефолт — ВЫКЛ:
/// уведомления без явного согласия — дурной тон; включается в настройках.
class ReminderPreferencesStore {
  static const _key = 'reminders.streak_evening.v1';

  Future<bool> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> save(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, enabled);
  }
}
