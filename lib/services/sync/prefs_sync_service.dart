import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_service.dart';
import '../locale/locale_store.dart';

/// Синк настроек с облаком (public.user_prefs, одобрено владелицей
/// 2026-07-16): весь документ настроек — один jsonb, конфликт решает
/// last-write-wins по updated_at. Ниже — чистая часть (тестируется
/// напрямую), сервис — в конце файла.

/// Точные prefs-ключи, входящие в облачный снапшот настроек.
/// НЕ входят: журнал сессий (своя таблица sessions), онбординг/коуч-метки,
/// настройки обновлений и флаги разрешений — они прибиты к устройству.
const prefsSyncExactKeys = <String>{
  'wim_hof.settings',
  'favorites.v1',
  'fikr.custom.in',
  'fikr.custom.ex',
  'difficulty.preset',
  'sound.set',
  'app.locale',
  'reminders.streak_evening.v1',
  'bolt_log.v1',
};

/// Префиксы per-техника ключей (настройки сессии и таймера) — новые техники
/// попадают в снапшот автоматически, без правки списка.
const prefsSyncPrefixes = <String>['technique_settings.', 'timer.settings.'];

/// BOLT-журнал — единственный append-only ключ снапшота: при применении
/// облака объединяется по id, а не замещается (история с двух устройств
/// не должна затирать друг друга).
const _boltKey = 'bolt_log.v1';

bool isSyncedPrefsKey(String key) =>
    prefsSyncExactKeys.contains(key) || prefsSyncPrefixes.any(key.startsWith);

/// Снимок синкуемых настроек из полного дампа prefs.
Map<String, Object?> buildPrefsSnapshot(Map<String, Object?> all) => {
      for (final e in all.entries)
        if (isSyncedPrefsKey(e.key)) e.key: e.value,
    };

/// Разворачивает BOLT-журнал (обёртка `{schema,results}`) в список записей.
/// Битый/отсутствующий JSON → пустой список (журнал не важнее синка).
List<Map<String, dynamic>> boltResultsOf(String? raw) {
  if (raw == null) return const [];
  try {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final list = map['results'] as List? ?? const [];
    return [for (final e in list) (e as Map).cast<String, dynamic>()];
  } catch (_) {
    return const [];
  }
}

/// Объединение BOLT-журналов: union по id, порядок — по takenAt
/// (старые → новые, как хранит BoltRepository).
List<Map<String, dynamic>> mergeBoltResults(
  List<Map<String, dynamic>> a,
  List<Map<String, dynamic>> b,
) {
  final byId = <String, Map<String, dynamic>>{};
  for (final r in [...a, ...b]) {
    final id = r['id'];
    if (id is String) byId[id] = r;
  }
  DateTime takenAt(Map<String, dynamic> r) =>
      DateTime.tryParse(r['takenAt'] as String? ?? '') ??
      DateTime.fromMillisecondsSinceEpoch(0);
  return byId.values.toList()
    ..sort((x, y) => takenAt(x).compareTo(takenAt(y)));
}

/// Решение LWW по паре времён. null localChangedAt = на этом устройстве
/// настройки не менялись (свежая установка) → облако побеждает.
enum PrefsSyncAction { applyRemote, pushLocal, none }

PrefsSyncAction decidePrefsSync({
  DateTime? localChangedAt,
  DateTime? remoteUpdatedAt,
}) {
  if (remoteUpdatedAt == null) return PrefsSyncAction.pushLocal;
  if (localChangedAt == null) return PrefsSyncAction.applyRemote;
  if (remoteUpdatedAt.isAfter(localChangedAt)) return PrefsSyncAction.applyRemote;
  if (localChangedAt.isAfter(remoteUpdatedAt)) return PrefsSyncAction.pushLocal;
  return PrefsSyncAction.none;
}

/// Применяет облачный снапшот к локальным prefs: синкуемые ключи замещаются
/// (в т.ч. удаляются отсутствующие в облаке — так доезжает reset техники),
/// BOLT-журнал объединяется. Возвращает true, если локальный BOLT содержал
/// записи сверх облачных — тогда объединённый документ надо допушить.
Future<bool> applyPrefsSnapshot(
  SharedPreferences prefs,
  Map<String, Object?> remote,
) async {
  final localBolt = boltResultsOf(prefs.getString(_boltKey));
  final remoteBolt = boltResultsOf(remote[_boltKey] as String?);
  final mergedBolt = mergeBoltResults(remoteBolt, localBolt);

  for (final key in prefs.getKeys().where(isSyncedPrefsKey).toList()) {
    if (key != _boltKey && !remote.containsKey(key)) await prefs.remove(key);
  }
  for (final e in remote.entries) {
    if (!isSyncedPrefsKey(e.key) || e.key == _boltKey) continue;
    final v = e.value;
    switch (v) {
      case final String s:
        await prefs.setString(e.key, s);
      case final bool b:
        await prefs.setBool(e.key, b);
      case final int i:
        await prefs.setInt(e.key, i);
      case final double d:
        await prefs.setDouble(e.key, d);
      case final List l:
        await prefs.setStringList(e.key, l.cast<String>());
      default:
        await prefs.remove(e.key);
    }
  }
  if (mergedBolt.isNotEmpty) {
    await prefs.setString(
      _boltKey,
      jsonEncode({'schema': 1, 'results': mergedBolt}),
    );
  }
  final remoteIds = {for (final r in remoteBolt) r['id']};
  return localBolt.any((r) => !remoteIds.contains(r['id']));
}

/// Синк настроек с public.user_prefs (см. docs/supabase/schema.sql —
/// миграцию применяет владелец в SQL Editor).
///
/// Триггеры: изменение любого стора настроек (через PrefsChanges → дебаунс-
/// пуш) и вход/старт с сессией (pull + решение LWW). Без входа и при любой
/// сетевой ошибке — тихий no-op, как у [SessionSyncService]. Отсутствие
/// таблицы в облаке отключает синк до конца жизни процесса.
class PrefsSyncService {
  /// Момент последнего локального изменения настроек (ISO-8601 UTC).
  /// Ставится при изменении ДО попытки пуша: упавший пуш не должен дать
  /// облаку затереть более свежую локальную правку. Не синкуется.
  static const markerKey = 'prefs_sync.updated_at';

  final AuthService auth;

  PrefsSyncService({this.auth = const AuthService()});

  static PrefsSyncService instance = PrefsSyncService();

  static bool _cloudHasTable = true;

  static bool _isMissingTable(PostgrestException e) =>
      e.code == 'PGRST205' || e.code == '42P01';

  Timer? _debounce;

  /// Хук для PrefsChanges: настройки изменились локально. Гость не пушит —
  /// его правки при входе проиграют облаку (маркер не трогаем).
  void onLocalChange() {
    if (auth.currentUser == null) return;
    unawaited(_touchMarker());
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () => unawaited(push()));
  }

  /// Выход из аккаунта: маркер сбрасывается, чтобы правки под прежним
  /// аккаунтом не перезаписали облако следующего.
  Future<void> onSignedOut() async {
    _debounce?.cancel();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(markerKey);
    } catch (_) {}
  }

  Future<void> _touchMarker() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        markerKey,
        DateTime.now().toUtc().toIso8601String(),
      );
    } catch (_) {}
  }

  /// Пуш локального снапшота в облако. Пустой снапшот не пушим: свежая
  /// установка не должна создавать (и тем более затирать) документ.
  Future<void> push() async {
    final user = auth.currentUser;
    if (user == null || !_cloudHasTable) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final snapshot = buildPrefsSnapshot(
        {for (final k in prefs.getKeys()) k: prefs.get(k)},
      );
      if (snapshot.isEmpty) return;
      var marker = prefs.getString(markerKey);
      if (marker == null) {
        marker = DateTime.now().toUtc().toIso8601String();
        await prefs.setString(markerKey, marker);
      }
      await Supabase.instance.client.from('user_prefs').upsert({
        'user_id': user.id,
        'prefs': snapshot,
        'updated_at': marker,
      });
    } on PostgrestException catch (e) {
      if (_isMissingTable(e)) _cloudHasTable = false;
    } catch (_) {
      // Офлайн/сбой сети — не мешаем работе, попробуем в следующий раз.
    }
  }

  /// Pull при входе/старте: забрать облачный документ и решить LWW.
  Future<void> syncNow() async {
    final user = auth.currentUser;
    if (user == null || !_cloudHasTable) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final row = await Supabase.instance.client
          .from('user_prefs')
          .select('prefs, updated_at')
          .eq('user_id', user.id)
          .maybeSingle();
      final remote =
          (row?['prefs'] as Map?)?.cast<String, Object?>() ?? const {};
      if (remote.isEmpty) {
        // В облаке пусто (нет строки или пустой документ) — локальное вверх.
        await push();
        return;
      }
      final remoteTs =
          DateTime.parse(row!['updated_at'] as String).toUtc();
      final markerRaw = prefs.getString(markerKey);
      final marker =
          markerRaw == null ? null : DateTime.tryParse(markerRaw)?.toUtc();
      switch (decidePrefsSync(
        localChangedAt: marker,
        remoteUpdatedAt: remoteTs,
      )) {
        case PrefsSyncAction.applyRemote:
          final boltGrew = await applyPrefsSnapshot(prefs, remote);
          await prefs.setString(markerKey, remoteTs.toIso8601String());
          // Язык может смениться приехавшими настройками — обновляем кадр.
          localeNotifier.value = localeFor(await LocaleStore().load());
          if (boltGrew) {
            // Объединённый BOLT-журнал шире облачного — допушиваем.
            await _touchMarker();
            await push();
          }
        case PrefsSyncAction.pushLocal:
          await push();
        case PrefsSyncAction.none:
          break;
      }
    } on PostgrestException catch (e) {
      if (_isMissingTable(e)) _cloudHasTable = false;
    } catch (_) {
      // Офлайн/сбой сети — не мешаем работе, попробуем в следующий раз.
    }
  }
}
