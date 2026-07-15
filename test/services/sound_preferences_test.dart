import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breathin/services/audio/sound_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('дефолт — «Поток»', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await SoundSetStore().load(), SoundSet.flow);
  });

  test('save/load сохраняет «Чаши»', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SoundSetStore();
    await store.save(SoundSet.bowls);
    expect(await store.load(), SoundSet.bowls);
  });

  test('устаревшие значения (nature/minimal) откатываются к дефолту',
      () async {
    SharedPreferences.setMockInitialValues({'sound.set': 'nature'});
    expect(await SoundSetStore().load(), SoundSet.flow);
    SharedPreferences.setMockInitialValues({'sound.set': 'minimal'});
    expect(await SoundSetStore().load(), SoundSet.flow);
  });
}
