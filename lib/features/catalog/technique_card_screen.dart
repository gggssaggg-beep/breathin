import 'package:flutter/material.dart';

import '../../domain/models/technique.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../l10n/technique_texts.dart';
import '../../ui/icons/breathin_icon.dart';
import '../session_setup/session_setup_screen.dart';
import 'technique_icons.dart';
import 'technique_subtitle.dart';

/// Экран «Описание техники» (ТЗ §6.3).
///
/// Отображает крупную иконку, подпись-паттерн, три секции
/// (описание / польза / безопасность) и кнопку «Начать».
/// Для counted-техник кнопка активна и запускает [SessionRunner];
/// для timer, wimHof и stage2-техник — disabled с подписью comingSoonStage2.
class TechniqueCardScreen extends StatelessWidget {
  final Technique technique;

  const TechniqueCardScreen({super.key, required this.technique});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final t = technique;

    final bool canStart =
        t.type == TechniqueType.counted && !t.stage2 && t.phases != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.techniqueName(t)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Прокручиваемое тело
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                children: [
                  // Крупная иконка
                  Center(
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: BreathinIcon(
                        iconDataFor(t.icon),
                        size: 48,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Подпись-паттерн
                  Center(
                    child: Text(
                      techniqueSubtitle(l, t),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  // Бейдж «скоро» для stage2-техник
                  if (t.stage2) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Chip(
                        label: Text(l.comingSoonStage2),
                        labelStyle: theme.textTheme.labelSmall,
                        backgroundColor:
                            theme.colorScheme.secondaryContainer,
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 0),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Секция: Описание
                  _SectionHeader(title: l.sectionDescription),
                  const SizedBox(height: 8),
                  Text(
                    l.techniqueDescription(t),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),

                  // Секция: Польза
                  _SectionHeader(title: l.sectionBenefit),
                  const SizedBox(height: 8),
                  Text(
                    l.techniqueBenefit(t),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),

                  // Секция: Безопасность
                  _SectionHeader(title: l.sectionSafety),
                  const SizedBox(height: 8),
                  _SafetySection(technique: t),
                  const SizedBox(height: 20),

                  // Подсказка новичкам
                  if (t.recommendedMaxCyclesNovice != null) ...[
                    _NoviceHint(n: t.recommendedMaxCyclesNovice!),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),

            // Нижняя кнопка «Начать»
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: canStart ? () => _startSession(context) : null,
                      child: Text(l.startSession),
                    ),
                  ),
                  if (!canStart) ...[
                    const SizedBox(height: 8),
                    Text(
                      l.comingSoonStage2,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startSession(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionSetupScreen(technique: technique),
      ),
    );
  }
}

/// Заголовок секции.
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// Секция безопасности: для уровня high — выделяется Card с errorContainer.
class _SafetySection extends StatelessWidget {
  final Technique technique;
  const _SafetySection({required this.technique});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final text = l.safetyText(technique);

    if (technique.safetyLevel == SafetyLevel.high) {
      return Card(
        color: theme.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
        ),
      );
    }

    return Text(text, style: theme.textTheme.bodyMedium);
  }
}

/// Подсказка для новичков о максимальном числе циклов.
class _NoviceHint extends StatelessWidget {
  final int n;
  const _NoviceHint({required this.n});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Text(
      l.noviceCyclesHint(n),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
