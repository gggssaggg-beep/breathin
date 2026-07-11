import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/session_log_repository.dart';
import '../../domain/models/session_record.dart';
import '../auth/auth_service.dart';

/// Записи, которых ещё нет в облаке (чистая функция — тестируется напрямую).
List<SessionRecord> computeUpload(
  List<SessionRecord> local,
  Set<String> remoteIds,
) =>
    local.where((r) => !remoteIds.contains(r.id)).toList(growable: false);

/// Двусторонний синк локальной истории практик с public.sessions.
///
/// Смысл — «без потери данных»: переустановка/новое устройство → вход →
/// история вернулась; upsert по (user_id, id) делает синк идемпотентным,
/// конфликтов нет по построению (записи append-only и создаются одним
/// устройством). Время хранится в UTC (timestamptz), локально — пояс
/// устройства.
///
/// Без входа ([AuthService.currentUser] == null) и при любой сетевой
/// ошибке — тихий no-op: синк повторится при следующем запуске.
class SessionSyncService {
  final AuthService auth;
  final SessionLogRepository log;

  SessionSyncService({
    this.auth = const AuthService(),
    SessionLogRepository? log,
  }) : log = log ?? SessionLogRepository();

  Future<void> syncNow() async {
    final user = auth.currentUser;
    if (user == null) return;
    try {
      final client = Supabase.instance.client;
      final local = await log.all();
      final rows = await client
          .from('sessions')
          .select('id, technique_id, started_at, duration_sec, cycles, '
              'completed');

      final remote = [
        for (final row in rows)
          SessionRecord(
            id: row['id'] as String,
            techniqueId: row['technique_id'] as String,
            startedAt:
                DateTime.parse(row['started_at'] as String).toLocal(),
            durationSec: (row['duration_sec'] as num).toInt(),
            cyclesCompleted: (row['cycles'] as num).toInt(),
            completed: row['completed'] as bool? ?? true,
          ),
      ];
      final remoteIds = remote.map((r) => r.id).toSet();

      final upload = computeUpload(local, remoteIds);
      if (upload.isNotEmpty) {
        await client.from('sessions').upsert([
          for (final r in upload)
            {
              'user_id': user.id,
              'id': r.id,
              'technique_id': r.techniqueId,
              'started_at': r.startedAt.toUtc().toIso8601String(),
              'duration_sec': r.durationSec,
              'cycles': r.cyclesCompleted,
              'completed': r.completed,
            },
        ]);
      }

      await log.mergeAll(remote);
    } catch (_) {
      // Офлайн/сбой сети — не мешаем работе, попробуем в следующий раз.
    }
  }
}
