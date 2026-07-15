import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breathin/domain/catalog/techniques.dart';
import 'package:breathin/l10n/generated/app_localizations.dart';
import 'package:breathin/l10n/technique_texts.dart';

void main() {
  /// Вспомогательная функция: синхронно получает экземпляр [AppLocalizations]
  /// для нужной локали через публичный [lookupAppLocalizations].
  AppLocalizations l10n(String languageCode) =>
      lookupAppLocalizations(Locale(languageCode));

  group('TechniqueTexts — каталог', () {
    for (final locale in ['ru', 'en']) {
      group('locale: $locale', () {
        late AppLocalizations loc;

        setUp(() => loc = l10n(locale));

        test('techniqueName непустой для всех техник каталога', () {
          for (final t in catalog) {
            expect(
              loc.techniqueName(t),
              isNotEmpty,
              reason: 'id=${t.id}, locale=$locale',
            );
          }
        });

        test('techniqueDescription непустой для всех техник каталога', () {
          for (final t in catalog) {
            expect(
              loc.techniqueDescription(t),
              isNotEmpty,
              reason: 'id=${t.id}, locale=$locale',
            );
          }
        });

        test('techniqueBenefit непустой для всех техник каталога', () {
          for (final t in catalog) {
            expect(
              loc.techniqueBenefit(t),
              isNotEmpty,
              reason: 'id=${t.id}, locale=$locale',
            );
          }
        });

        test('safetyText не бросает исключение для всех техник каталога', () {
          for (final t in catalog) {
            expect(
              () => loc.safetyText(t),
              returnsNormally,
              reason: 'id=${t.id}, safetyKey=${t.safetyKey}, locale=$locale',
            );
            expect(
              loc.safetyText(t),
              isNotEmpty,
              reason: 'id=${t.id}, locale=$locale',
            );
          }
        });
      });
    }
  });

  group('TechniqueTexts — конкретные RU-названия', () {
    late AppLocalizations loc;

    setUp(() => loc = l10n('ru'));

    test('box: «Квадратное дыхание»', () {
      expect(loc.techniqueName(boxBreathing), 'Квадратное дыхание');
    });

    test('wim_hof: «Метод Вима Хофа»', () {
      expect(loc.techniqueName(wimHof), 'Метод Вима Хофа');
    });
  });
}
