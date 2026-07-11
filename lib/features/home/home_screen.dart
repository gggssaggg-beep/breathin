import 'package:flutter/material.dart';

import '../../domain/catalog/techniques.dart';
import '../../domain/models/technique.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../l10n/technique_texts.dart';
import '../../ui/icons/breathin_icon.dart';
import '../../ui/icons/breathin_icons.dart';
import '../catalog/technique_card_screen.dart';
import '../catalog/technique_icons.dart';
import '../catalog/technique_subtitle.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';

/// Главный экран: сетка техник (ТЗ §6.2).
///
/// Отображает все 12 техник из [catalog] в GridView 2 колонки.
/// Для stage2-техник (Вим Хоф) — визуальная пометка «скоро» и приглушённый вид,
/// но карточка тапабельна и ведёт на [TechniqueCardScreen].
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: [
          IconButton(
            icon: const BreathinIcon(BreathinIcons.calendar),
            tooltip: l.statsTooltip,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => StatsScreen()),
            ),
          ),
          IconButton(
            icon: const BreathinIcon(BreathinIcons.settings),
            tooltip: l.settingsTooltip,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.0,
        ),
        itemCount: catalog.length,
        itemBuilder: (context, index) {
          final t = catalog[index];
          return _TechniqueGridCard(
            technique: t,
            subtitle: techniqueSubtitle(l, t),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TechniqueCardScreen(technique: t),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Карточка техники для сетки главного экрана.
class _TechniqueGridCard extends StatelessWidget {
  final Technique technique;
  final String subtitle;
  final VoidCallback onTap;

  const _TechniqueGridCard({
    required this.technique,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final t = technique;
    final isDimmed = t.stage2;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Иконка
              CircleAvatar(
                radius: 28,
                backgroundColor: isDimmed
                    ? theme.colorScheme.surfaceContainerHighest
                    : theme.colorScheme.primaryContainer,
                child: BreathinIcon(
                  iconDataFor(t.icon),
                  color: isDimmed
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onPrimaryContainer,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              // Название
              Text(
                l.techniqueName(t),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isDimmed
                      ? theme.colorScheme.onSurfaceVariant
                      : null,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Подпись-паттерн
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Бейдж «скоро» для stage2
              if (t.stage2) ...[
                const SizedBox(height: 6),
                Chip(
                  label: Text(
                    l.comingSoonBadge,
                    style: theme.textTheme.labelSmall,
                  ),
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  side: BorderSide.none,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
