import 'package:flutter/material.dart';

import '../../domain/models/technique.dart';

/// Маппер семантической иконки техники в [IconData] (Material Icons).
/// Выделен в отдельный файл, чтобы переиспользовать на главном экране
/// и на карточке техники.
IconData iconFor(TechniqueIcon icon) {
  switch (icon) {
    case TechniqueIcon.square:
      return Icons.crop_square_rounded;
    case TechniqueIcon.triangle:
      return Icons.change_history_rounded;
    case TechniqueIcon.moon:
      return Icons.nightlight_round;
    case TechniqueIcon.balance:
      return Icons.balance_rounded;
    case TechniqueIcon.wave:
      return Icons.waves_rounded;
    case TechniqueIcon.deepWave:
      return Icons.water_rounded;
    case TechniqueIcon.mountain:
      return Icons.terrain_rounded;
    case TechniqueIcon.heart:
      return Icons.favorite_rounded;
    case TechniqueIcon.snowflake:
      return Icons.ac_unit_rounded;
    case TechniqueIcon.belly:
      return Icons.self_improvement_rounded;
    case TechniqueIcon.nostrils:
      return Icons.air_rounded;
    case TechniqueIcon.hum:
      return Icons.graphic_eq_rounded;
  }
}
