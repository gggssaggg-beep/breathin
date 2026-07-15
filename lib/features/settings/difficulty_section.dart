import 'package:flutter/material.dart';

import '../../domain/difficulty/difficulty.dart';
import '../../l10n/generated/app_localizations.dart';

/// Локализованное имя пресета сложности.
String difficultyPresetName(AppLocalizations l, DifficultyPreset p) {
  switch (p) {
    case DifficultyPreset.calm:
      return l.difficultyCalm;
    case DifficultyPreset.breeze:
      return l.difficultyBreeze;
    case DifficultyPreset.wave:
      return l.difficultyWave;
    case DifficultyPreset.tide:
      return l.difficultyTide;
    case DifficultyPreset.mine:
      return l.difficultyMine;
  }
}

/// Секция настроек «Сложность» (эпик §4–5): чипы пресетов Штиль·Бриз·Волна·
/// Прибой + «Своё дыхание». Презентационный виджет — состояние подаёт экран.
class DifficultySection extends StatelessWidget {
  final DifficultyPreset preset;

  /// Есть ли хотя бы один результат BOLT (для подсказки у «Своего дыхания»).
  final bool hasBoltResult;
  final ValueChanged<DifficultyPreset> onChanged;

  const DifficultySection({
    super.key,
    required this.preset,
    required this.hasBoltResult,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final showMineHint = preset == DifficultyPreset.mine && !hasBoltResult;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final p in DifficultyPreset.values)
              ChoiceChip(
                label: Text(difficultyPresetName(l, p)),
                selected: preset == p,
                onSelected: (_) => onChanged(p),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          showMineHint ? l.difficultyMineNoTest : l.difficultyNote,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
