import 'package:breathin/app/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breathin/data/favorites_store.dart';

void main() {
  group('FavoritesStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('toggle добавляет id', () async {
      final store = FavoritesStore();
      await store.toggle('box');
      expect(await store.load(), contains('box'));
    });

    test('toggle убирает id при повторном нажатии', () async {
      final store = FavoritesStore();
      await store.toggle('box');
      await store.toggle('box');
      expect(await store.load(), isNot(contains('box')));
    });

    test('roundtrip: toggle/load переживает повторный load', () async {
      final store = FavoritesStore();
      await store.toggle('wim_hof');
      await store.toggle('box');
      final loaded = await store.load();
      expect(loaded, containsAll(['wim_hof', 'box']));
      expect(loaded, hasLength(2));
    });
  });

  group('Главный экран: избранные первыми', () {
    testWidgets('wim_hof в prefs → карточка Вима Хофа выше Box Breathing',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'favorites.v1': ['wim_hof'],
      });

      await tester.pumpWidget(
        const BreathinApp(checkUpdates: false, showOnboarding: false),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Находим тексты обоих названий в дереве
      final wimHofFinder = find.text('Wim Hof Method');
      final boxFinder = find.text('Box Breathing');

      expect(wimHofFinder, findsOneWidget);
      expect(boxFinder, findsOneWidget);

      // Вим Хоф должен быть выше Box (меньший Y — раньше в сетке)
      final wimHofY = tester.getTopLeft(wimHofFinder).dy;
      final boxY = tester.getTopLeft(boxFinder).dy;
      expect(wimHofY, lessThanOrEqualTo(boxY));
    });
  });
}
