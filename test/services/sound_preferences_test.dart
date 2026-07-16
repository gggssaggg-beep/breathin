import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breathin/services/audio/sound_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('дефолт — «Арфа»', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await SoundSetStore().load(), SoundSet.harp);
  });

  test('save/load сохраняет «Чаши»', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SoundSetStore();
    await store.save(SoundSet.bowls);
    expect(await store.load(), SoundSet.bowls);
  });

  test('устаревшие значения (flow/nature/minimal) откатываются к дефолту',
      () async {
    for (final legacy in ['flow', 'nature', 'minimal', 'jazz']) {
      SharedPreferences.setMockInitialValues({'sound.set': legacy});
      expect(await SoundSetStore().load(), SoundSet.harp, reason: legacy);
    }
  });
}
