import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/technique.dart';
import '../domain/models/technique_settings.dart';

/// Персист настроек сессии per-техника на SharedPreferences.
///
/// Почему SharedPreferences, а не drift:
/// настройки — простой per-id JSON-документ (один ключ на технику) без
/// реляционных запросов и агрегации. drift придёт в П11 для хранения
/// истории сессий и статистики (см. ПЛАН §4.1); тащить его зависимость
/// ради одного плоского документа — избыточно.
class TechniqueSettingsRepository {
  static String _key(String id) => 'technique_settings.$id';

  /// Загружает настройки для техники [t].
  ///
  /// При отсутствии ключа или любой ошибке парсинга возвращает
  /// [TechniqueSettings.classic].
  Future<TechniqueSettings> load(Technique t) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(t.id));
      if (raw == null) return TechniqueSettings.classic(t);
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return TechniqueSettings.fromJson(t, map);
    } catch (_) {
      return TechniqueSettings.classic(t);
    }
  }

  /// Возвращает сохранённые настройки или null, если техника ещё ни разу не
  /// настраивалась. В отличие от [load], НЕ подменяет отсутствие классикой —
  /// нужно вызывающему, чтобы отличить «нет записи» (применить глобальный
  /// пресет сложности) от «пользователь сохранил классику».
  Future<TechniqueSettings?> loadSaved(Technique t) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(t.id));
      if (raw == null) return null;
      return TechniqueSettings.fromJson(t, jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Сохраняет настройки [s] по ключу техники.
  Future<void> save(TechniqueSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(s.techniqueId), jsonEncode(s.toJson()));
  }

  /// Удаляет сохранённые настройки для техники с идентификатором [techniqueId].
  Future<void> reset(String techniqueId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(techniqueId));
  }
}
