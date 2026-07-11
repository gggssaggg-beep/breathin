import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breathin/data/technique_settings_repository.dart';
import 'package:breathin/domain/catalog/techniques.dart';
import 'package:breathin/domain/models/technique_settings.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final repo = TechniqueSettingsRepository();
  final t = boxBreathing;

  test('load без сохранённых данных возвращает классику', () async {
    final s = await repo.load(t);
    final classic = TechniqueSettings.classic(t);
    expect(s.techniqueId, classic.techniqueId);
    expect(s.cycles, classic.cycles);
    expect(s.phaseSeconds, classic.phaseSeconds);
  });

  test('save → load возвращает те же настройки (roundtrip)', () async {
    final original = TechniqueSettings.classic(t).copyWith(cycles: 42);
    await repo.save(original);
    final loaded = await repo.load(t);
    expect(loaded.cycles, 42);
    expect(loaded.phaseSeconds, original.phaseSeconds);
    expect(loaded.techniqueId, original.techniqueId);
  });

  test('битый JSON в ключе → load возвращает классику', () async {
    SharedPreferences.setMockInitialValues({
      'technique_settings.box': 'NOT_VALID_JSON{{{',
    });
    final s = await repo.load(t);
    final classic = TechniqueSettings.classic(t);
    expect(s.cycles, classic.cycles);
    expect(s.phaseSeconds, classic.phaseSeconds);
  });

  test('reset удаляет ключ — следующий load даёт классику', () async {
    final modified = TechniqueSettings.classic(t).copyWith(cycles: 77);
    await repo.save(modified);

    // Убеждаемся, что сохранилось
    final loaded = await repo.load(t);
    expect(loaded.cycles, 77);

    // Сбрасываем
    await repo.reset(t.id);

    // Теперь должна вернуться классика
    final afterReset = await repo.load(t);
    expect(afterReset.cycles, TechniqueSettings.classic(t).cycles);
  });
}
