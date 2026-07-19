import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breathin/domain/models/technique.dart';
import 'package:breathin/features/session/segment_labels.dart';
import 'package:breathin/l10n/generated/app_localizations.dart';

/// Резолвит AppLocalizations без дерева виджетов — для чистых строковых
/// проверок подписей сегментов (локаль по умолчанию — en).
Future<AppLocalizations> _en() => AppLocalizations.delegate.load(
      const Locale('en'),
    );

void main() {
  const nineLeft = BreathSegment(
    id: 'nine_left',
    cycles: 3,
    inhale: BreathRoute.nose,
    exhale: BreathRoute.nose,
  );
  const nineRight = BreathSegment(
    id: 'nine_right',
    cycles: 3,
    inhale: BreathRoute.nose,
    exhale: BreathRoute.nose,
  );
  const nineBoth = BreathSegment(
    id: 'nine_both',
    cycles: 3,
    inhale: BreathRoute.nose,
    exhale: BreathRoute.nose,
  );
  const earth = BreathSegment(
    id: 'earth',
    cycles: 5,
    inhale: BreathRoute.nose,
    exhale: BreathRoute.nose,
  );

  test('девять очищающих: подпись фазы называет сторону ноздри, не «носом»',
      () async {
    final l = await _en();
    // nine_left = вдох левой, выдох правой (совпадает с меткой сегмента).
    expect(routedPhaseLabel(l, nineLeft, PhaseKind.inhale), 'Inhale · left nostril');
    expect(
        routedPhaseLabel(l, nineLeft, PhaseKind.exhale), 'Exhale · right nostril');
    // nine_right = вдох правой, выдох левой.
    expect(
        routedPhaseLabel(l, nineRight, PhaseKind.inhale), 'Inhale · right nostril');
    expect(
        routedPhaseLabel(l, nineRight, PhaseKind.exhale), 'Exhale · left nostril');
    // Ни одна фаза девяти не подписана обобщённым «через нос» — иначе
    // противоречие с меткой стороны (влад. 2026-07-19).
    expect(routedPhaseLabel(l, nineLeft, PhaseKind.inhale),
        isNot(contains('nose')));
  });

  test('обе ноздри и стихии — обычная подпись по маршруту', () async {
    final l = await _en();
    expect(routedPhaseLabel(l, nineBoth, PhaseKind.inhale), 'Inhale through the nose');
    expect(routedPhaseLabel(l, earth, PhaseKind.exhale), 'Exhale through the nose');
  });
}
