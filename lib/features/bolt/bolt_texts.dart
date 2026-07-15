import '../../domain/bolt/bolt_interpretation.dart';
import '../../l10n/generated/app_localizations.dart';

/// Локализованные название и описание уровня BOLT (ARB-ключи boltLevel*).
/// Отдельный extension — как TechniqueTexts: доменный слой хранит только enum.
extension BoltTexts on AppLocalizations {
  String boltLevelName(BoltLevel level) {
    switch (level) {
      case BoltLevel.low:
        return boltLevelLow;
      case BoltLevel.medium:
        return boltLevelMedium;
      case BoltLevel.high:
        return boltLevelHigh;
      case BoltLevel.veryHigh:
        return boltLevelVeryHigh;
    }
  }

  String boltLevelDescription(BoltLevel level) {
    switch (level) {
      case BoltLevel.low:
        return boltLevelLowDesc;
      case BoltLevel.medium:
        return boltLevelMediumDesc;
      case BoltLevel.high:
        return boltLevelHighDesc;
      case BoltLevel.veryHigh:
        return boltLevelVeryHighDesc;
    }
  }
}
