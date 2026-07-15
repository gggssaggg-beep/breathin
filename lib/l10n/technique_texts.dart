import 'generated/app_localizations.dart';
import 'package:breathin/domain/catalog/fikr_phrases.dart';
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
      case 'stretch':
        return tech_stretch_name;
      case 'elemental':
        return tech_elemental_name;
      case 'fikr':
        return tech_fikr_name;
      case 'wim_hof':
        return tech_wim_hof_name;
      case 'vessel':
        return tech_vessel_name;
      case 'axis':
        return tech_axis_name;
      case 'nine_breaths':
        return tech_nine_breaths_name;
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
      case 'stretch':
        return tech_stretch_desc;
      case 'elemental':
        return tech_elemental_desc;
      case 'fikr':
        return tech_fikr_desc;
      case 'wim_hof':
        return tech_wim_hof_desc;
      case 'vessel':
        return tech_vessel_desc;
      case 'axis':
        return tech_axis_desc;
      case 'nine_breaths':
        return tech_nine_breaths_desc;
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
      case 'stretch':
        return tech_stretch_benefit;
      case 'elemental':
        return tech_elemental_benefit;
      case 'fikr':
        return tech_fikr_benefit;
      case 'wim_hof':
        return tech_wim_hof_benefit;
      case 'vessel':
        return tech_vessel_benefit;
      case 'axis':
        return tech_axis_benefit;
      case 'nine_breaths':
        return tech_nine_breaths_benefit;
      default:
        throw StateError('Неизвестный id техники: ${t.id}');
    }
  }

  /// Фраза фикра на вдохе (ARB-ключ `fikr_<id>_in`).
  String fikrPhraseIn(FikrPhrase p) {
    switch (p.id) {
      case 'calm':
        return fikr_calm_in;
      case 'presence':
        return fikr_presence_in;
      case 'light':
        return fikr_light_in;
      case 'first_light':
        return fikr_first_light_in;
      case 'heart_waves':
        return fikr_heart_waves_in;
      case 'wave_ocean':
        return fikr_wave_ocean_in;
      case 'shore':
        return fikr_shore_in;
      case 'gift':
        return fikr_gift_in;
      case 'stillness':
        return fikr_stillness_in;
      case 'sky_mind':
        return fikr_sky_mind_in;
      case 'ishq':
        return fikr_ishq_in;
      case 'shafee':
        return fikr_shafee_in;
      case 'allah':
        return fikr_allah_in;
      default:
        throw StateError('Неизвестная фраза фикра: ${p.id}');
    }
  }

  /// Фраза фикра на выдохе (ARB-ключ `fikr_<id>_ex`).
  String fikrPhraseEx(FikrPhrase p) {
    switch (p.id) {
      case 'calm':
        return fikr_calm_ex;
      case 'presence':
        return fikr_presence_ex;
      case 'light':
        return fikr_light_ex;
      case 'first_light':
        return fikr_first_light_ex;
      case 'heart_waves':
        return fikr_heart_waves_ex;
      case 'wave_ocean':
        return fikr_wave_ocean_ex;
      case 'shore':
        return fikr_shore_ex;
      case 'gift':
        return fikr_gift_ex;
      case 'stillness':
        return fikr_stillness_ex;
      case 'sky_mind':
        return fikr_sky_mind_ex;
      case 'ishq':
        return fikr_ishq_ex;
      case 'shafee':
        return fikr_shafee_ex;
      case 'allah':
        return fikr_allah_ex;
      default:
        throw StateError('Неизвестная фраза фикра: ${p.id}');
    }
  }

  /// Название набора фраз фикра.
  String fikrSetLabel(FikrPhraseSet set) {
    switch (set) {
      case FikrPhraseSet.affirmations:
        return fikrSetAffirmations;
      case FikrPhraseSet.wazifa:
        return fikrSetWazifa;
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
