import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breathin/services/audio/sound_bank_loader.dart';
import 'package:breathin/services/audio/sound_preferences.dart';
import 'package:breathin/services/audio/timeline_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SoundSetStore', () {
    test('дефолт — «Чаши» (решение владельца 2026-07-15)', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await SoundSetStore().load(), SoundSet.bowls);
    });

    test('save/load сохраняет выбор «Минимал»', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SoundSetStore();
      await store.save(SoundSet.minimal);
      expect(await store.load(), SoundSet.minimal);
    });

    test('мусорное значение в prefs откатывается к дефолту', () async {
      SharedPreferences.setMockInitialValues({'sound.set': 'jazz'});
      expect(await SoundSetStore().load(), SoundSet.bowls);
    });
  });

  group('assetsForSet', () {
    test('каждый набор покрывает все ClipId (страховка полноты)', () {
      for (final set in SoundSet.values) {
        final map = assetsForSet(set);
        expect(map.keys.toSet(), ClipId.values.toSet(),
            reason: 'набор $set должен давать путь каждому ClipId');
      }
    });

    test('фазовые клипы идут из каталога своего набора, события — из common',
        () {
      final bowls = assetsForSet(SoundSet.bowls);
      expect(bowls[ClipId.inhale], contains('sets/bowls/'));
      expect(bowls[ClipId.gong], contains('common/'));
      final nature = assetsForSet(SoundSet.nature);
      expect(nature[ClipId.inhale], contains('sets/nature/'));
      final minimal = assetsForSet(SoundSet.minimal);
      expect(minimal[ClipId.inhale], contains('sets/minimal/'));
    });

    test('пути наборов не пересекаются по фазовым клипам', () {
      final nature = assetsForSet(SoundSet.nature);
      final minimal = assetsForSet(SoundSet.minimal);
      expect(nature[ClipId.inhale], isNot(minimal[ClipId.inhale]));
      expect(nature[ClipId.tick], isNot(minimal[ClipId.tick]));
    });
  });
}
