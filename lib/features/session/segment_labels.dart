import 'package:flutter/material.dart';

import '../../domain/models/technique.dart';
import '../../l10n/generated/app_localizations.dart';
import 'phase_labels.dart';

/// Локализованное название элемента по id сегмента.
String segmentLabel(AppLocalizations l, String id) {
  switch (id) {
    case 'earth':
      return l.segEarth;
    case 'water':
      return l.segWater;
    case 'fire':
      return l.segFire;
    case 'air':
      return l.segAir;
    case 'ether':
      return l.segEther;
    default:
      return id;
  }
}

/// Локализованная подпись фазы с учётом маршрута дыхания сегмента.
/// Для inhale/exhale с заданным маршрутом — «Вдох носом» / «Выдох ртом» и т.п.
/// Null-маршрут (эфир) — тихое дыхание без уточнения. Прочие фазы — стандартный
/// [phaseLabel].
String routedPhaseLabel(AppLocalizations l, BreathSegment seg, PhaseKind phase) {
  switch (phase) {
    case PhaseKind.inhale:
      if (seg.inhale == null) return l.segSilentBreath;
      return seg.inhale == BreathRoute.nose ? l.segInhaleNose : l.segInhaleMouth;
    case PhaseKind.exhale:
      if (seg.exhale == null) return l.segSilentBreath;
      return seg.exhale == BreathRoute.nose ? l.segExhaleNose : l.segExhaleMouth;
    default:
      return phaseLabel(l, phase);
  }
}

/// Цвет элемента по id сегмента (стихии).
Color elementColor(String id) {
  switch (id) {
    case 'earth':
      return const Color(0xFFC9A227);
    case 'water':
      return const Color(0xFF2E9E6B);
    case 'fire':
      return const Color(0xFFD64541);
    case 'air':
      return const Color(0xFF3F7FBF);
    case 'ether':
      return const Color(0xFF9C6BD6);
    default:
      return const Color(0xFF3F7FBF);
  }
}
