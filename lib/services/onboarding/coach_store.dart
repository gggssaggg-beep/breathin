import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Персист состояния обучалок: какие подсказки уже закрыл пользователь
/// и видел ли он приветственный экран. Хранится в SharedPreferences.
///
/// Образец: [TechniqueSettingsRepository] — те же принципы: ошибки
/// парсинга трактуем как «данных нет», возвращаем безопасное пустое значение.
class CoachStore {
  static const _seenKey = 'onboarding.coach_seen_v1';
  static const _welcomeKey = 'onboarding.welcome_seen_v1';

  /// Загружает набор id закрытых подсказок.
  /// При отсутствии ключа или ошибке парсинга возвращает пустое множество.
  Future<Set<String>> loadSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_seenKey);
      if (raw == null) return {};
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e as String).toSet();
    } catch (_) {
      return {};
    }
  }

  /// Добавляет [id] в набор закрытых подсказок и сохраняет.
  Future<void> markSeen(String id) async {
    try {
      final current = await loadSeen();
      current.add(id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_seenKey, jsonEncode(current.toList()));
    } catch (_) {}
  }

  /// Возвращает true, если пользователь уже видел приветственный экран.
  Future<bool> welcomeSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_welcomeKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Отмечает приветственный экран как просмотренный.
  Future<void> markWelcomeSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_welcomeKey, true);
    } catch (_) {}
  }

  /// Сбрасывает оба ключа — подсказки и приветствие покажутся заново.
  Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_seenKey);
      await prefs.remove(_welcomeKey);
    } catch (_) {}
  }
}
