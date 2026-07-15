import '../../domain/models/technique.dart';
import '../../ui/icons/breathin_icons.dart';

/// Маппер семантической иконки техники в [BreathinIconData]
/// (собственный набор в стиле Tabler, MIT — см. lib/ui/icons/).
/// Выделен в отдельный файл, чтобы переиспользовать на главном экране
/// и на карточке техники.
BreathinIconData iconDataFor(TechniqueIcon icon) {
  switch (icon) {
    case TechniqueIcon.square:
      return BreathinIcons.square;
    case TechniqueIcon.triangle:
      return BreathinIcons.triangle;
    case TechniqueIcon.moon:
      return BreathinIcons.moon;
    case TechniqueIcon.balance:
      return BreathinIcons.scale;
    case TechniqueIcon.wave:
      return BreathinIcons.waveSine;
    case TechniqueIcon.deepWave:
      return BreathinIcons.ripple;
    case TechniqueIcon.mountain:
      return BreathinIcons.mountain;
    case TechniqueIcon.heart:
      return BreathinIcons.heartbeat;
    case TechniqueIcon.snowflake:
      return BreathinIcons.snowflake;
    case TechniqueIcon.belly:
      return BreathinIcons.lungs;
    case TechniqueIcon.nostrils:
      return BreathinIcons.wind;
    case TechniqueIcon.hum:
      return BreathinIcons.volume2;
    case TechniqueIcon.stretch:
      return BreathinIcons.stretch;
    case TechniqueIcon.elements:
      return BreathinIcons.circles;
    case TechniqueIcon.quote:
      return BreathinIcons.quote;
    case TechniqueIcon.vessel:
      return BreathinIcons.flask;
    case TechniqueIcon.axis:
      return BreathinIcons.arrowsVertical;
    case TechniqueIcon.sparkles:
      return BreathinIcons.sparkles;
    case TechniqueIcon.sigh:
      return BreathinIcons.trendingDown;
  }
}
