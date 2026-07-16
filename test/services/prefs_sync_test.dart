import 'dart:convert';

import 'package:breathin/core/prefs_changes.dart';
import 'package:breathin/data/difficulty_store.dart';
import 'package:breathin/domain/difficulty/difficulty.dart';
import 'package:breathin/services/sync/prefs_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

String boltRaw(List<Map<String, dynamic>> results) =>
    jsonEncode({'schema': 1, 'results': results});

Map<String, dynamic> boltRes(String id, String takenAt, [int seconds = 20]) =>
    {'id': id, 'takenAt': takenAt, 'seconds': seconds};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('isSyncedPrefsKey / buildPrefsSnapshot', () {
    test('в снапшот входят настройки, но не журнал сессий и не онбординг', () {
      final all = <String, Object?>{
        'technique_settings.box': '{"variant":"4-8-8"}',
        'timer.settings.mindful': '{"minutes":10}',
        'wim_hof.settings': '{"breaths":30}',
        'favorites.v1': ['box', 'fikr'],
        'fikr.custom.in': 'вдох',
        'fikr.custom.ex': 'выдох',
        'difficulty.preset': 'breeze',
        'sound.set': 'harp',
        'app.locale': 'ru',
        'reminders.streak_evening.v1': true,
        'bolt_log.v1': boltRaw([boltRes('a', '2026-07-15T10:00:00')]),
        // Не синкуется:
        'session_log.v1': '{"schema":1,"sessions":[]}',
        'coach.seen.v1': '["home"]',
        'welcome.seen.v1': true,
        PrefsSyncService.markerKey: '2026-07-16T10:00:00Z',
      };
      final snapshot = buildPrefsSnapshot(all);
      expect(snapshot.keys, hasLength(11));
      expect(snapshot.containsKey('session_log.v1'), isFalse);
      expect(snapshot.containsKey('coach.seen.v1'), isFalse);
      expect(snapshot.containsKey('welcome.seen.v1'), isFalse);
      expect(snapshot.containsKey(PrefsSyncService.markerKey), isFalse);
      expect(snapshot['favorites.v1'], ['box', 'fikr']);
    });
  });

  group('decidePrefsSync', () {
    final older = DateTime.utc(2026, 7, 15, 10);
    final newer = DateTime.utc(2026, 7, 16, 10);

    test('облака нет → пуш локального', () {
      expect(
        decidePrefsSync(localChangedAt: older, remoteUpdatedAt: null),
        PrefsSyncAction.pushLocal,
      );
    });

    test('локальных правок не было (свежая установка) → облако побеждает', () {
      expect(
        decidePrefsSync(localChangedAt: null, remoteUpdatedAt: older),
        PrefsSyncAction.applyRemote,
      );
    });

    test('облако свежее → применить облако; локальное свежее → пуш', () {
      expect(
        decidePrefsSync(localChangedAt: older, remoteUpdatedAt: newer),
        PrefsSyncAction.applyRemote,
      );
      expect(
        decidePrefsSync(localChangedAt: newer, remoteUpdatedAt: older),
        PrefsSyncAction.pushLocal,
      );
    });

    test('времена равны → синк не нужен', () {
      expect(
        decidePrefsSync(localChangedAt: older, remoteUpdatedAt: older),
        PrefsSyncAction.none,
      );
    });
  });

  group('mergeBoltResults', () {
    test('union по id, порядок по takenAt (старые → новые)', () {
      final merged = mergeBoltResults(
        [
          boltRes('b', '2026-07-14T09:00:00'),
          boltRes('a', '2026-07-12T09:00:00'),
        ],
        [
          boltRes('a', '2026-07-12T09:00:00'),
          boltRes('c', '2026-07-16T09:00:00'),
        ],
      );
      expect(merged.map((r) => r['id']), ['a', 'b', 'c']);
    });

    test('битый JSON разворачивается в пустой список', () {
      expect(boltResultsOf('не json'), isEmpty);
      expect(boltResultsOf(null), isEmpty);
      expect(boltResultsOf('{"schema":1}'), isEmpty);
    });
  });

  group('applyPrefsSnapshot', () {
    test('замещает настройки, удаляет отсутствующие в облаке, чужое не трогает',
        () async {
      SharedPreferences.setMockInitialValues({
        'difficulty.preset': 'breeze',
        'technique_settings.box': '{"variant":"локальный"}',
        'technique_settings.fikr': '{"variant":"сброшенная"}',
        'session_log.v1': 'локальный журнал',
        'coach.seen.v1': 'локальный онбординг',
      });
      final prefs = await SharedPreferences.getInstance();
      await applyPrefsSnapshot(prefs, {
        'difficulty.preset': 'wave',
        'technique_settings.box': '{"variant":"облачный"}',
        'favorites.v1': ['box'],
        'reminders.streak_evening.v1': false,
      });
      expect(prefs.getString('difficulty.preset'), 'wave');
      expect(
        prefs.getString('technique_settings.box'),
        '{"variant":"облачный"}',
      );
      // Сброшенная на другом устройстве техника удаляется и здесь.
      expect(prefs.getString('technique_settings.fikr'), isNull);
      expect(prefs.getStringList('favorites.v1'), ['box']);
      expect(prefs.getBool('reminders.streak_evening.v1'), isFalse);
      // Несинкуемые ключи остаются как были.
      expect(prefs.getString('session_log.v1'), 'локальный журнал');
      expect(prefs.getString('coach.seen.v1'), 'локальный онбординг');
    });

    test('BOLT-журнал объединяется, а не замещается', () async {
      SharedPreferences.setMockInitialValues({
        'bolt_log.v1': boltRaw([boltRes('local', '2026-07-15T10:00:00')]),
      });
      final prefs = await SharedPreferences.getInstance();
      final boltGrew = await applyPrefsSnapshot(prefs, {
        'bolt_log.v1': boltRaw([boltRes('cloud', '2026-07-14T10:00:00')]),
      });
      final merged = boltResultsOf(prefs.getString('bolt_log.v1'));
      expect(merged.map((r) => r['id']), ['cloud', 'local']);
      // Локальная запись шире облака — нужен обратный пуш.
      expect(boltGrew, isTrue);
    });

    test('локальный BOLT не шире облачного → обратный пуш не нужен', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final boltGrew = await applyPrefsSnapshot(prefs, {
        'bolt_log.v1': boltRaw([boltRes('cloud', '2026-07-14T10:00:00')]),
      });
      expect(
        boltResultsOf(prefs.getString('bolt_log.v1')).map((r) => r['id']),
        ['cloud'],
      );
      expect(boltGrew, isFalse);
    });
  });

  group('PrefsChanges → PrefsSyncService', () {
    test('сторы дёргают шину после записи', () async {
      var notified = 0;
      PrefsChanges.onChanged = () => notified++;
      addTearDown(() => PrefsChanges.onChanged = null);
      await DifficultyStore().save(DifficultyPreset.wave);
      expect(notified, 1);
    });

    test('без входа onLocalChange/syncNow — тихий no-op', () async {
      // AuthService не инициализирован → currentUser == null → сети нет.
      PrefsSyncService.instance.onLocalChange();
      await PrefsSyncService.instance.syncNow();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(PrefsSyncService.markerKey), isNull);
    });
  });
}
