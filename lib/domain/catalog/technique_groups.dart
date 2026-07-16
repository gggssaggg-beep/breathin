import '../models/technique.dart';

/// Группы каталога на главном экране (У2, system review 2026-07-16).
/// «Избранное» — не группа, а динамическая секция сверху: избранная техника
/// ДУБЛИРУЕТСЯ туда и остаётся в своей группе (решение владельца —
/// техника всегда находится там, где её ищут).
enum TechniqueGroup { calm, energy, traditions }

/// Группа техники по id. Новая техника без группы уронит тест
/// «каждая техника каталога имеет группу» — страховка полноты.
TechniqueGroup groupOf(Technique t) {
  switch (t.id) {
    case 'box':
    case 'triangle':
    case 'four_seven_eight':
    case 'four_two_four':
    case 'two_eight':
    case 'two_ten':
    case 'sigh':
    case 'coherent':
    case 'diaphragmatic':
    case 'mindful':
      return TechniqueGroup.calm;
    case 'wim_hof':
    case 'bandha':
    case 'orbit':
    case 'vessel':
    case 'axis':
    case 'four_sixteen_eight':
      return TechniqueGroup.energy;
    case 'stretch':
    case 'elemental':
    case 'fikr':
    case 'nine_breaths':
    case 'nadi_shodhana':
    case 'sound_breath':
    case 'energy_wave':
      return TechniqueGroup.traditions;
    default:
      throw StateError('Техника без группы: ${t.id}');
  }
}
