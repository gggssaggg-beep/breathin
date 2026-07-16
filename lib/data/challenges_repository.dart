import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/invite_code.dart';
import '../domain/models/session_record.dart';
import '../domain/stats/challenge_progress.dart';
import '../services/auth/auth_service.dart';
import 'session_log_repository.dart';

/// Представление челленджа для UI: сам челлендж + участники с прогрессом.
class ChallengeView {
  final String id;
  final String code;
  final String title;
  final ChallengeMetric metric;
  final int target;
  final DateTime startsOn;
  final DateTime endsOn;
  final List<ChallengeParticipant> participants;

  const ChallengeView({
    required this.id,
    required this.code,
    required this.title,
    required this.metric,
    required this.target,
    required this.startsOn,
    required this.endsOn,
    required this.participants,
  });

  bool isActive(DateTime today) =>
      !today.isBefore(startsOn) &&
      !DateTime(today.year, today.month, today.day).isAfter(endsOn);
}

class ChallengeParticipant {
  final String userId;
  final String displayName;
  final int progress;
  final bool isMe;

  const ChallengeParticipant({
    required this.userId,
    required this.displayName,
    required this.progress,
    required this.isMe,
  });
}

/// Челленджи по коду-приглашению (схема — docs/supabase/schema.sql).
/// Все методы требуют входа; вызывающая сторона гейтит по AuthService.
class ChallengesRepository {
  final SessionLogRepository log;

  ChallengesRepository({SessionLogRepository? log})
      : log = log ?? SessionLogRepository();

  SupabaseClient get _client => Supabase.instance.client;
  String get _uid => _client.auth.currentUser!.id;

  static DateTime _date(String s) => DateTime.parse(s);
  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Мои челленджи (где я участник) с участниками и именами.
  Future<List<ChallengeView>> myChallenges() async {
    final my = await _client
        .from('challenge_participants')
        .select('challenge_id')
        .eq('user_id', _uid);
    final ids = [for (final r in my) r['challenge_id'] as String];
    if (ids.isEmpty) return const [];

    final challenges =
        await _client.from('challenges').select().inFilter('id', ids);
    final participants = await _client
        .from('challenge_participants')
        .select('challenge_id, user_id, progress')
        .inFilter('challenge_id', ids);
    final userIds = {for (final p in participants) p['user_id'] as String};
    final profiles = await _client
        .from('profiles')
        .select('id, display_name')
        .inFilter('id', userIds.toList());
    final names = {
      for (final p in profiles) p['id'] as String: p['display_name'] as String,
    };

    final views = <ChallengeView>[];
    for (final c in challenges) {
      final cid = c['id'] as String;
      final parts = [
        for (final p in participants.where((p) => p['challenge_id'] == cid))
          ChallengeParticipant(
            userId: p['user_id'] as String,
            displayName: names[p['user_id']] ?? '?',
            progress: (p['progress'] as num).toInt(),
            isMe: p['user_id'] == _uid,
          ),
      ]..sort((a, b) => b.progress.compareTo(a.progress));
      views.add(ChallengeView(
        id: cid,
        code: c['code'] as String,
        title: c['title'] as String,
        metric: ChallengeMetric.values.byName(c['metric'] as String),
        target: (c['target'] as num).toInt(),
        startsOn: _date(c['starts_on'] as String),
        endsOn: _date(c['ends_on'] as String),
        participants: parts,
      ));
    }
    // Свежесозданные — выше.
    views.sort((a, b) => b.startsOn.compareTo(a.startsOn));
    return views;
  }

  /// Создаёт челлендж (окно — от сегодня на [days] дней) и вступает в него.
  /// Возвращает код приглашения.
  Future<String> create({
    required String title,
    required ChallengeMetric metric,
    required int target,
    required int days,
  }) async {
    final today = DateTime.now();
    // Коллизия кода крайне маловероятна (31^6), но unique-индекс её поймает —
    // пробуем ещё раз с новым кодом.
    for (var attempt = 0; ; attempt++) {
      final code = generateInviteCode();
      try {
        final row = await _client
            .from('challenges')
            .insert({
              'code': code,
              'title': title,
              'metric': metric.name,
              'target': target,
              'starts_on': _iso(today),
              'ends_on': _iso(today.add(Duration(days: days - 1))),
              'creator': _uid,
            })
            .select('id')
            .single();
        await _client.from('challenge_participants').insert({
          'challenge_id': row['id'],
          'user_id': _uid,
        });
        await syncProgress();
        return code;
      } on PostgrestException {
        if (attempt >= 2) rethrow;
      }
    }
  }

  /// Вступает в челлендж по коду. Возвращает его название или null,
  /// если код не найден.
  Future<String?> joinByCode(String code) async {
    final row = await _client
        .from('challenges')
        .select('id, title')
        .eq('code', code.trim().toUpperCase())
        .maybeSingle();
    if (row == null) return null;
    await _client.from('challenge_participants').upsert({
      'challenge_id': row['id'],
      'user_id': _uid,
    });
    await syncProgress();
    return row['title'] as String;
  }

  /// Пересчитывает мой прогресс по всем моим челленджам из локальной
  /// истории и отправляет в облако. Вызывается при открытии экрана,
  /// после создания/вступления и после завершения сессии.
  Future<void> syncProgress() async {
    final views = await myChallenges();
    if (views.isEmpty) return;
    final records = await log.all();
    for (final v in views) {
      await _syncOne(v, records);
    }
  }

  /// Лёгкий вариант: только пересчёт и upsert прогресса, без возврата вью-моделей.
  /// Используется после каждой сессии (fire-and-forget через [syncProgressIfSignedIn]).
  Future<void> syncProgressOnly() async {
    await syncProgress();
  }

  /// Гейт для вызова из session_runner / wim_hof / timer_session: no-op, если
  /// Supabase не инициализирован или пользователь не вошёл. Любые ошибки глотает.
  static Future<void> syncProgressIfSignedIn() async {
    const auth = AuthService();
    if (!auth.isReady) return;
    if (auth.currentUser == null) return;
    try {
      await ChallengesRepository().syncProgressOnly();
    } catch (_) {
      // fire-and-forget: ошибки не прерывают сессионный поток
    }
  }

  /// Загружает мои челленджи И синхронизирует мой прогресс одним проходом:
  /// один fetch вместо двух (открытие экрана было 2× цепочкой запросов).
  /// Возвращает представления с уже обновлённым моим прогрессом.
  Future<List<ChallengeView>> loadAndSyncProgress() async {
    final views = await myChallenges();
    if (views.isEmpty) return views;
    final records = await log.all();
    final result = <ChallengeView>[];
    for (final v in views) {
      final progress = await _syncOne(v, records);
      // Пересобираем участников: мой (isMe) прогресс — свежепосчитанный.
      // Сортировку по progress desc сохраняем (участники const-конструируемые).
      final parts = [
        for (final p in v.participants)
          p.isMe
              ? ChallengeParticipant(
                  userId: p.userId,
                  displayName: p.displayName,
                  progress: progress,
                  isMe: true,
                )
              : p,
      ]..sort((a, b) => b.progress.compareTo(a.progress));
      result.add(ChallengeView(
        id: v.id,
        code: v.code,
        title: v.title,
        metric: v.metric,
        target: v.target,
        startsOn: v.startsOn,
        endsOn: v.endsOn,
        participants: parts,
      ));
    }
    return result;
  }

  /// Считает мой прогресс по одному челленджу из [records] и пишет в облако.
  /// Возвращает свежепосчитанное значение (общий хелпер для sync/load).
  Future<int> _syncOne(ChallengeView v, List<SessionRecord> records) async {
    final progress =
        challengeProgress(records, v.metric, v.startsOn, v.endsOn);
    await _client
        .from('challenge_participants')
        .update({
          'progress': progress,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('challenge_id', v.id)
        .eq('user_id', _uid);
    return progress;
  }
}
