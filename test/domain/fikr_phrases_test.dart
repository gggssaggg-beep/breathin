import 'package:flutter_test/flutter_test.dart';

import 'package:breathin/domain/catalog/fikr_phrases.dart';
import 'package:breathin/domain/catalog/techniques.dart';
import 'package:breathin/domain/models/technique.dart';
import 'package:breathin/l10n/generated/app_localizations.dart';
import 'package:breathin/l10n/technique_texts.dart';

void main() {
  group('Каталог фраз фикра (№10)', () {
    test('6 пар: 3 аффирмации + 3 вазифы', () {
      expect(fikrPhrases, hasLength(6));
      expect(
        fikrPhrases.where((p) => p.set == FikrPhraseSet.affirmations),
        hasLength(3),
      );
      expect(
        fikrPhrases.where((p) => p.set == FikrPhraseSet.wazifa),
        hasLength(3),
      );
    });

    test('дефолт — нейтральная аффирмация (светская подача по умолчанию)', () {
      expect(defaultFikrPhrase.set, FikrPhraseSet.affirmations);
      expect(fikrPhrases.first.id, defaultFikrPhrase.id);
    });

    test('fikrPhraseById: null и мусор из старых сохранений → дефолт', () {
      expect(fikrPhraseById(null).id, defaultFikrPhrase.id);
      expect(fikrPhraseById('unknown').id, defaultFikrPhrase.id);
      expect(fikrPhraseById('shafee').id, 'shafee');
    });

    test('каждая пара локализована непустыми строками (ru и en)', () {
      for (final locale in AppLocalizations.supportedLocales) {
        final l = lookupAppLocalizations(locale);
        for (final p in fikrPhrases) {
          expect(l.fikrPhraseIn(p), isNotEmpty,
              reason: 'fikr_${p.id}_in @ $locale');
          expect(l.fikrPhraseEx(p), isNotEmpty,
              reason: 'fikr_${p.id}_ex @ $locale');
        }
        expect(l.fikrSetLabel(FikrPhraseSet.affirmations), isNotEmpty);
        expect(l.fikrSetLabel(FikrPhraseSet.wazifa), isNotEmpty);
      }
    });
  });

  group('Техника «Фикр» в каталоге', () {
    test('counted вдох 4 / выдох 6, без задержек, safety low', () {
      final t = techniqueById('fikr');
      expect(t.type, TechniqueType.counted);
      final phases = t.phases!;
      expect(phases, hasLength(2));
      expect(phases[0].kind, PhaseKind.inhale);
      expect(phases[0].defaultSec, 4.0);
      expect(phases[1].kind, PhaseKind.exhale);
      expect(phases[1].defaultSec, 6.0);
      expect(t.safetyLevel, SafetyLevel.low);
      expect(t.defaultCycles, 30);
    });

    test('имя/описание/польза локализованы (ru и en)', () {
      final t = techniqueById('fikr');
      for (final locale in AppLocalizations.supportedLocales) {
        final l = lookupAppLocalizations(locale);
        expect(l.techniqueName(t), isNotEmpty);
        expect(l.techniqueDescription(t), isNotEmpty);
        expect(l.techniqueBenefit(t), isNotEmpty);
      }
    });
  });
}
