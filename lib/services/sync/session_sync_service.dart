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

  /// Колонка sessions.variant может отсутствовать в облаке (миграция из
  /// schema.sql применяется владельцем при появлении PAT): при ошибке
  /// «нет колонки» откатываемся на старую форму до конца жизни процесса,
  /// со следующего запуска пробуем снова.
  static bool _cloudHasVariant = true;

  static bool _isMissingVariantColumn(PostgrestException e) =>
      e.code == 'PGRST204' || // upsert: колонка не найдена в схеме
      e.code == '42703'; // select: undefined_column

  Future<void> syncNow() async {
    final user = auth.currentUser;
    if (user == null) return;
    try {
      final client = Supabase.instance.client;
      final local = await log.all();

      const baseColumns =
          'id, technique_id, started_at, duration_sec, cycles, completed';
      List<Map<String, dynamic>> rows;
      if (_cloudHasVariant) {
        try {
          rows = await client
              .from('sessions')
              .select('$baseColumns, variant');
        } on PostgrestException catch (e) {
          if (!_isMissingVariantColumn(e)) rethrow;
          _cloudHasVariant = false;
          rows = await client.from('sessions').select(baseColumns);
        }
      } else {
        rows = await client.from('sessions').select(baseColumns);
      }

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
            variant: row['variant'] as String?,
          ),
      ];
      final remoteIds = remote.map((r) => r.id).toSet();

      final upload = computeUpload(local, remoteIds);
      if (upload.isNotEmpty) {
        List<Map<String, dynamic>> payload({required bool withVariant}) => [
              for (final r in upload)
                {
                  'user_id': user.id,
                  'id': r.id,
                  'technique_id': r.techniqueId,
                  'started_at': r.startedAt.toUtc().toIso8601String(),
                  'duration_sec': r.durationSec,
                  'cycles': r.cyclesCompleted,
                  'completed': r.completed,
                  if (withVariant && r.variant != null) 'variant': r.variant,
                },
            ];
        if (_cloudHasVariant) {
          try {
            await client
                .from('sessions')
                .upsert(payload(withVariant: true));
          } on PostgrestException catch (e) {
            if (!_isMissingVariantColumn(e)) rethrow;
            _cloudHasVariant = false;
            await client
                .from('sessions')
                .upsert(payload(withVariant: false));
          }
        } else {
          await client.from('sessions').upsert(payload(withVariant: false));
        }
      }

      await log.mergeAll(remote);
    } catch (_) {
      // Офлайн/сбой сети — не мешаем работе, попробуем в следующий раз.
    }
  }
}
