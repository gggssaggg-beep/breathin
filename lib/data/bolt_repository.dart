import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/prefs_changes.dart';
import '../domain/models/bolt_result.dart';

/// История результатов BOLT (append-only), формат-обёртка `{schema,results}`
/// на SharedPreferences — как [SessionLogRepository]. Читатели разворачивают
/// `results` (урок из CLAUDE.md: иначе коллекция «поднимается пустой»).
class BoltRepository {
  static const _key = 'bolt_log.v1';

  /// Глобальный хвост записи: read-modify-write с async-зазором, параллельный
  /// вызов терял бы записи (тот же приём, что в SessionLogRepository).
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

  /// Все результаты в порядке добавления (старые → новые).
  Future<List<BoltResult>> all() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return const [];
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final list = map['results'] as List? ?? const [];
      return list
          .map((e) => BoltResult.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> add(BoltResult result) => _enqueueWrite(() async {
        final prefs = await SharedPreferences.getInstance();
        final results = (await all()).map((r) => r.toJson()).toList()
          ..add(result.toJson());
        await prefs.setString(
          _key,
          jsonEncode({'schema': 1, 'results': results}),
        );
        PrefsChanges.notify();
      });
}
