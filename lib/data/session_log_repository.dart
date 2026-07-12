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

  /// Очередь записи: add/mergeAll — read-modify-write с async-зазором;
  /// параллельный вызов (финиш сессии во время стартового синка) терял бы
  /// записи (ревью М12). Хвост цепочки — глобальный: инстансы репозитория
  /// создаются на месте, а хранилище одно.
  ///
  /// null == очередь пуста: операция идёт напрямую, без прицепки к чужому
  /// Future. Это принципиально для тестов: завершённый хвост из FakeAsync-
  /// зоны предыдущего testWidgets диспетчеризует слушателей в СВОЕЙ зоне,
  /// которая больше не качается, — `.then` на нём завис бы навсегда.
  static Future<void>? _writeTail;

  Future<T> _enqueueWrite<T>(Future<T> Function() op) {
    final prev = _writeTail;
    final run = prev == null ? op() : prev.then((_) => op());
    final tail = run.then((_) {}, onError: (_) {});
    _writeTail = tail;
    tail.whenComplete(() {
      if (identical(_writeTail, tail)) _writeTail = null;
    });
    return run;
  }

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

  Future<void> add(SessionRecord record) => _enqueueWrite(() async {
        final prefs = await SharedPreferences.getInstance();
        final records = (await all()).map((r) => r.toJson()).toList()
          ..add(record.toJson());
        await prefs.setString(
          _key,
          jsonEncode({'schema': 1, 'records': records}),
        );
      });

  /// Вливает записи из облака: дедупликация по id, локальные не трогаются.
  /// Возвращает число реально добавленных.
  Future<int> mergeAll(Iterable<SessionRecord> incoming) =>
      _enqueueWrite(() async {
        final existing = await all();
        final knownIds = existing.map((r) => r.id).toSet();
        final fresh = incoming
            .where((r) => !knownIds.contains(r.id))
            .toList(growable: false);
        if (fresh.isEmpty) return 0;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _key,
          jsonEncode({
            'schema': 1,
            'records': [
              for (final r in existing) r.toJson(),
              for (final r in fresh) r.toJson(),
            ],
          }),
        );
        return fresh.length;
      });
}
