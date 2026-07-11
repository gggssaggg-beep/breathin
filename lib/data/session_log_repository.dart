import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/session_record.dart';

/// Локальная история практик на SharedPreferences (append-only журнал).
///
/// Формат хранения — обёртка со схемой: `{"schema":1,"records":[...]}`;
/// читатели ОБЯЗАНЫ разворачивать `records` (урок из глобального CLAUDE.md —
/// иначе коллекция «поднимается пустой»). Объём: даже годы ежедневной
/// практики — единицы тысяч записей, для prefs приемлемо; при появлении
/// облачного синка/сложных запросов мигрируем в drift (ПЛАН §4.1, П11).
class SessionLogRepository {
  static const _key = 'session_log.v1';

  Future<List<SessionRecord>> all() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return const [];
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final list = map['records'] as List? ?? const [];
      return list
          .map((e) => SessionRecord.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } catch (_) {
      // Битый JSON не должен ронять статистику — начинаем с пустой истории.
      return const [];
    }
  }

  Future<void> add(SessionRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final records = (await all()).map((r) => r.toJson()).toList()
      ..add(record.toJson());
    await prefs.setString(
      _key,
      jsonEncode({'schema': 1, 'records': records}),
    );
  }
}
