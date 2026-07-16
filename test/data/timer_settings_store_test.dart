import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breathin/data/timer_settings_store.dart';
import 'package:breathin/domain/catalog/techniques.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('дефолты Нади Шодханы: 5 мин, prep 3, подсказки 15 c, каналы вкл',
      () async {
    SharedPreferences.setMockInitialValues({});
    final s = await TimerSettingsStore().load(nadiShodhana);
    expect(s.minutes, 5);
    expect(s.prepSeconds, 3);
    expect(s.cueIntervalSec, 15);
    expect(s.sound, isTrue);
    expect(s.vibration, isTrue);
  });

  test('дефолты оси: 7 мин, без подсказок (cueIntervalSec 0)', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await TimerSettingsStore().load(axisBreath);
    expect(s.minutes, 7);
    expect(s.prepSeconds, 3);
    expect(s.cueIntervalSec, 0);
  });

  test('save/load roundtrip', () async {
    SharedPreferences.setMockInitialValues({});
    final store = TimerSettingsStore();
    await store.save(
      nadiShodhana.id,
      const TimerSettings(
        minutes: 12,
        prepSeconds: 5,
        cueIntervalSec: 30,
        sound: false,
        vibration: false,
      ),
    );
    final s = await store.load(nadiShodhana);
    expect(s.minutes, 12);
    expect(s.prepSeconds, 5);
    expect(s.cueIntervalSec, 30);
    expect(s.sound, isFalse);
    expect(s.vibration, isFalse);
  });

  test('минуты вне диапазона клэмпятся: 999 → 30 у Нади Шодханы', () async {
    SharedPreferences.setMockInitialValues({
      'timer.settings.nadi_shodhana':
          '{"minutes":999,"prepSeconds":3,"cueIntervalSec":15,'
              '"sound":true,"vibration":true}',
    });
    final s = await TimerSettingsStore().load(nadiShodhana);
    expect(s.minutes, 30);
  });

  test('минуты вне диапазона клэмпятся: 2 → 5 у оси (min 5)', () async {
    SharedPreferences.setMockInitialValues({
      'timer.settings.axis':
          '{"minutes":2,"prepSeconds":3,"cueIntervalSec":0,'
              '"sound":true,"vibration":true}',
    });
    final s = await TimerSettingsStore().load(axisBreath);
    expect(s.minutes, 5);
  });

  test('интервал подсказок не из списка техники → дефолт (7 → 15)', () async {
    SharedPreferences.setMockInitialValues({
      'timer.settings.nadi_shodhana':
          '{"minutes":5,"prepSeconds":3,"cueIntervalSec":7,'
              '"sound":true,"vibration":true}',
    });
    final s = await TimerSettingsStore().load(nadiShodhana);
    expect(s.cueIntervalSec, 15);
  });

  test('битый JSON — дефолты', () async {
    SharedPreferences.setMockInitialValues({
      'timer.settings.nadi_shodhana': '{oops',
    });
    final s = await TimerSettingsStore().load(nadiShodhana);
    expect(s.minutes, 5);
    expect(s.cueIntervalSec, 15);
    expect(s.sound, isTrue);
  });
}
