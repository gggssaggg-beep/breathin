import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breathin/data/wim_hof_settings_store.dart';
import 'package:breathin/domain/engine/wim_hof_machine.dart';
import 'package:breathin/domain/models/technique.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const d = WimHofDefaults();

  test('дефолт — классика каталога (30 дыханий × 3 раунда, темп 2.0)',
      () async {
    SharedPreferences.setMockInitialValues({});
    final c = await WimHofSettingsStore().load(d);
    expect(c.breaths, 30);
    expect(c.paceSec, 2.0);
    expect(c.rounds, 3);
    expect(c.recoveryHoldSec, 15);
  });

  test('save/load roundtrip', () async {
    SharedPreferences.setMockInitialValues({});
    final store = WimHofSettingsStore();
    await store.save(const WimHofConfig(breaths: 40, paceSec: 1.5, rounds: 5));
    final c = await store.load(d);
    expect(c.breaths, 40);
    expect(c.paceSec, 1.5);
    expect(c.rounds, 5);
  });

  test('значения вне диапазонов клэмпятся к безопасным', () async {
    SharedPreferences.setMockInitialValues({
      'wim_hof.settings': '{"breaths":500,"paceSec":0.1,"rounds":99}',
    });
    final c = await WimHofSettingsStore().load(d);
    expect(c.breaths, d.maxBreaths);
    expect(c.paceSec, d.minPaceSec);
    expect(c.rounds, d.maxRounds);
  });

  test('битый JSON — классика', () async {
    SharedPreferences.setMockInitialValues({'wim_hof.settings': '{oops'});
    final c = await WimHofSettingsStore().load(d);
    expect(c.breaths, d.breaths);
  });
}
