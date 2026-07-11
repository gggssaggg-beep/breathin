import 'generated/app_localizations.dart';
import 'package:breathin/domain/models/technique.dart';

/// Extension на [AppLocalizations], преобразующий доменные ключи техник
/// (хранящиеся в [Technique]) в локализованные строки.
/// Ключи вида `tech_<id>_name/desc/benefit` и `safety_<level>` соответствуют
/// ARB-записям в lib/l10n/app_ru.arb и lib/l10n/app_en.arb.
extension TechniqueTexts on AppLocalizations {
  /// Локализованное название техники (ARB-ключ `tech_<id>_name`).
  String techniqueName(Technique t) {
    switch (t.id) {
      case 'box':
        return tech_box_name;
      case 'triangle':
        return tech_triangle_name;
      case 'four_seven_eight':
        return tech_four_seven_eight_name;
      case 'four_two_four':
        return tech_four_two_four_name;
      case 'two_eight':
        return tech_two_eight_name;
      case 'two_ten':
        return tech_two_ten_name;
      case 'four_sixteen_eight':
        return tech_four_sixteen_eight_name;
      case 'coherent':
        return tech_coherent_name;
      case 'diaphragmatic':
        return tech_diaphragmatic_name;
      case 'nadi_shodhana':
        return tech_nadi_shodhana_name;
      case 'sound_breath':
        return tech_sound_breath_name;
      case 'wim_hof':
        return tech_wim_hof_name;
      default:
        throw StateError('Неизвестный id техники: ${t.id}');
    }
  }

  /// Локализованное описание техники (ARB-ключ `tech_<id>_desc`).
  String techniqueDescription(Technique t) {
    switch (t.id) {
      case 'box':
        return tech_box_desc;
      case 'triangle':
        return tech_triangle_desc;
      case 'four_seven_eight':
        return tech_four_seven_eight_desc;
      case 'four_two_four':
        return tech_four_two_four_desc;
      case 'two_eight':
        return tech_two_eight_desc;
      case 'two_ten':
        return tech_two_ten_desc;
      case 'four_sixteen_eight':
        return tech_four_sixteen_eight_desc;
      case 'coherent':
        return tech_coherent_desc;
      case 'diaphragmatic':
        return tech_diaphragmatic_desc;
      case 'nadi_shodhana':
        return tech_nadi_shodhana_desc;
      case 'sound_breath':
        return tech_sound_breath_desc;
      case 'wim_hof':
        return tech_wim_hof_desc;
      default:
        throw StateError('Неизвестный id техники: ${t.id}');
    }
  }

  /// Локализованный текст о пользе техники (ARB-ключ `tech_<id>_benefit`).
  String techniqueBenefit(Technique t) {
    switch (t.id) {
      case 'box':
        return tech_box_benefit;
      case 'triangle':
        return tech_triangle_benefit;
      case 'four_seven_eight':
        return tech_four_seven_eight_benefit;
      case 'four_two_four':
        return tech_four_two_four_benefit;
      case 'two_eight':
        return tech_two_eight_benefit;
      case 'two_ten':
        return tech_two_ten_benefit;
      case 'four_sixteen_eight':
        return tech_four_sixteen_eight_benefit;
      case 'coherent':
        return tech_coherent_benefit;
      case 'diaphragmatic':
        return tech_diaphragmatic_benefit;
      case 'nadi_shodhana':
        return tech_nadi_shodhana_benefit;
      case 'sound_breath':
        return tech_sound_breath_benefit;
      case 'wim_hof':
        return tech_wim_hof_benefit;
      default:
        throw StateError('Неизвестный id техники: ${t.id}');
    }
  }

  /// Локализованный текст безопасности по уровню (ARB-ключ `safety_<key>`).
  /// Ключ берётся из [Technique.safetyKey] (одно из: safety_low,
  /// safety_holds_generic, safety_intense).
  String safetyText(Technique t) {
    switch (t.safetyKey) {
      case 'safety_low':
        return safety_low;
      case 'safety_holds_generic':
        return safety_holds_generic;
      case 'safety_intense':
        return safety_intense;
      default:
        throw StateError('Неизвестный safetyKey: ${t.safetyKey}');
    }
  }
}
