import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breathin/services/onboarding/coach_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CoachStore', () {
    test('loadSeen без данных возвращает пустое множество', () async {
      final store = CoachStore();
      final seen = await store.loadSeen();
      expect(seen, isEmpty);
    });

    test('markSeen → loadSeen: roundtrip сохраняет id', () async {
      final store = CoachStore();
      await store.markSeen('home.pick');
      await store.markSeen('card.start');
      final seen = await store.loadSeen();
      expect(seen, containsAll(['home.pick', 'card.start']));
      expect(seen.length, 2);
    });

    test('markSeen дважды не дублирует id', () async {
      final store = CoachStore();
      await store.markSeen('home.pick');
      await store.markSeen('home.pick');
      final seen = await store.loadSeen();
      expect(seen.length, 1);
    });

    test('welcomeSeen по умолчанию false', () async {
      final store = CoachStore();
      expect(await store.welcomeSeen(), isFalse);
    });

    test('markWelcomeSeen → welcomeSeen возвращает true', () async {
      final store = CoachStore();
      await store.markWelcomeSeen();
      expect(await store.welcomeSeen(), isTrue);
    });

    test('reset очищает оба ключа', () async {
      final store = CoachStore();
      await store.markSeen('home.pick');
      await store.markWelcomeSeen();

      // Убеждаемся, что данные сохранены
      expect(await store.loadSeen(), isNotEmpty);
      expect(await store.welcomeSeen(), isTrue);

      // Сбрасываем
      await store.reset();

      // После сброса — пусто
      expect(await store.loadSeen(), isEmpty);
      expect(await store.welcomeSeen(), isFalse);
    });

    test('битый JSON в ключе coach_seen → loadSeen возвращает пустое множество',
        () async {
      SharedPreferences.setMockInitialValues({
        'onboarding.coach_seen_v1': 'NOT_VALID_JSON{{{',
      });
      final store = CoachStore();
      final seen = await store.loadSeen();
      expect(seen, isEmpty);
    });
  });
}
