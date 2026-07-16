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

  /// Опциональные колонки облака: variant («4-8-8», влад. §15) и retentions
  /// (задержки ВХ, system review Д1). Миграции из schema.sql применяет
  /// владелец — до этого при ошибке «нет колонки» перестаём слать/читать её
  /// до конца жизни процесса; со следующего запуска пробуем снова.
  static bool _cloudHasVariant = true;
  static bool _cloudHasRetentions = true;

  static bool _isMissingColumn(PostgrestException e) =>
      e.code == 'PGRST204' || // upsert: колонка не найдена в схеме
      e.code == '42703'; // select: undefined_column

  /// Помечает отсутствующую колонку по тексту ошибки PostgREST
  /// («Could not find the 'retentions' column …»). Возвращает true, если
  /// ошибка — про отсутствующую колонку (можно повторить без неё).
  static bool _markMissing(PostgrestException e) {
    if (!_isMissingColumn(e)) return false;
    final msg = e.message;
    var recognized = false;
    if (_cloudHasRetentions && msg.contains('retentions')) {
      _cloudHasRetentions = false;
      recognized = true;
    }
    if (_cloudHasVariant && msg.contains('variant')) {
      _cloudHasVariant = false;
      recognized = true;
    }
    // Имя не распознали — консервативно отключаем обе опциональные.
    if (!recognized) {
      _cloudHasVariant = false;
      _cloudHasRetentions = false;
    }
    return true;
  }

  static const _baseColumns =
      'id, technique_id, started_at, duration_sec, cycles, completed';

  String get _selectColumns => [
        _baseColumns,
        if (_cloudHasVariant) 'variant',
        if (_cloudHasRetentions) 'retentions',
      ].join(', ');

  Future<void> syncNow() async {
    final user = auth.currentUser;
    if (user == null) return;
    try {
      final client = Supabase.instance.client;
      final local = await log.all();

      // До трёх попыток: каждая неудача помечает отсутствующую колонку.
      List<Map<String, dynamic>>? rows;
      for (var attempt = 0; rows == null && attempt < 3; attempt++) {
        try {
          rows = await client.from('sessions').select(_selectColumns);
        } on PostgrestException catch (e) {
          if (!_markMissing(e)) rethrow;
        }
      }
      rows ??= await client.from('sessions').select(_baseColumns);

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
            retentionsSec: (row['retentions'] as List?)
                ?.map((e) => (e as num).toInt())
                .toList(),
          ),
      ];
      final remoteIds = remote.map((r) => r.id).toSet();

      final upload = computeUpload(local, remoteIds);
      if (upload.isNotEmpty) {
        List<Map<String, dynamic>> payload() => [
              for (final r in upload)
                {
                  'user_id': user.id,
                  'id': r.id,
                  'technique_id': r.techniqueId,
                  'started_at': r.startedAt.toUtc().toIso8601String(),
                  'duration_sec': r.durationSec,
                  'cycles': r.cyclesCompleted,
                  'completed': r.completed,
                  if (_cloudHasVariant && r.variant != null)
                    'variant': r.variant,
                  if (_cloudHasRetentions && r.retentionsSec != null)
                    'retentions': r.retentionsSec,
                },
            ];
        var uploaded = false;
        for (var attempt = 0; !uploaded && attempt < 3; attempt++) {
          try {
            await client.from('sessions').upsert(payload());
            uploaded = true;
          } on PostgrestException catch (e) {
            if (!_markMissing(e)) rethrow;
          }
        }
      }

      await log.mergeAll(remote);
    } catch (_) {
      // Офлайн/сбой сети — не мешаем работе, попробуем в следующий раз.
    }
  }
}
