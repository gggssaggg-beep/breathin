import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/favorites_store.dart';
import '../../data/session_log_repository.dart';
import '../../domain/catalog/technique_groups.dart';
import '../../domain/catalog/techniques.dart';
import '../../domain/models/session_record.dart';
import '../../domain/models/technique.dart';
import '../../domain/stats/practice_stats.dart';
import '../../features/onboarding/coach_mark.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../l10n/technique_texts.dart';
import '../../services/reminders/reminder_preferences.dart';
import '../../services/reminders/streak_reminder.dart';
import '../../ui/hant/hant_backdrop.dart';
import '../../ui/icons/breathin_icon.dart';
import '../../ui/icons/breathin_icons.dart';
import '../../ui/widgets/icon_badge.dart';
import '../../ui/widgets/list_action_card.dart';
import '../catalog/technique_card_screen.dart';
import '../catalog/technique_icons.dart';
import '../catalog/technique_subtitle.dart';
import '../challenges/challenges_screen.dart';
import '../session_setup/session_launcher.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';

/// Главный экран: каталог техник по группам (ТЗ §6.2; У1/У2 2026-07-16).
///
/// Сверху — стрик-баннер, карточка быстрого старта «Быстрый старт» (последняя
/// ЗАВЕРШЁННАЯ техника, запуск с сохранёнными настройками в один тап;
/// прерванные практики карточку не задают — фидбек владельца 2026-07-18) и
/// коучмарк. Ниже — секции: «Избранное» (избранная техника дублируется и
/// остаётся в своей группе — решение владельца), «Спокойствие и сон»,
/// «Энергия и трансформация», «Традиции».
class HomeScreen extends StatefulWidget {
  final SessionLogRepository log;

  /// «Сегодня» для тестируемости; по умолчанию — текущая дата устройства.
  final DateTime? today;

  HomeScreen({super.key, SessionLogRepository? log, this.today})
      : log = log ?? SessionLogRepository();

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SessionRecord>? _records;
  Set<String> _favorites = {};

  @override
  void initState() {
    super.initState();
    _reload();
    _reloadFavorites();
  }

  void _reload() {
    widget.log.all().then((r) {
      if (!mounted) return;
      setState(() => _records = r);
      _rescheduleReminder(r);
    });
  }

  /// Перепланирует вечернее напоминание о серии (С1) при каждом выходе на
  /// главный: самообновляющаяся схема без фоновых задач. Выключенный
  /// тумблер — no-op (снятие в настройках делает сам тумблер).
  Future<void> _rescheduleReminder(List<SessionRecord> records) async {
    try {
      if (!await ReminderPreferencesStore().load() || !mounted) return;
      final l = AppLocalizations.of(context);
      final streak =
          PracticeStats.streakDays(records, today: widget.today);
      await StreakReminder.reschedule(
        records,
        enabled: true,
        title: l.streakReminderTitle,
        body: l.streakReminderBody(streak),
      );
    } catch (_) {
      // Платформа без плагина/prefs (тесты) — без напоминаний.
    }
  }

  void _reloadFavorites() {
    FavoritesStore().load().then((favs) {
      if (mounted) setState(() => _favorites = favs);
    });
  }

  Future<void> _toggleFavorite(String id) async {
    await FavoritesStore().toggle(id);
    _reloadFavorites();
  }

  /// Пуш экрана с перезагрузкой стрика по возвращении: после сессии финиш
  /// делает popUntil(isFirst) — Future возвращается сюда, серия обновляется
  /// без ручного обновления главного экрана.
  void _openThenReload(Widget page) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => page))
        .then((_) {
      if (mounted) _reload();
    });
  }

  /// Запуск последней практики в один тап (У1): экран сессии с сохранёнными
  /// настройками, минуя карточку и setup.
  Future<void> _quickStart(Technique t) async {
    final l = AppLocalizations.of(context);
    final screen = await quickStartScreen(l, t);
    if (screen == null || !mounted) return;
    _openThenReload(screen);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final records = _records;
    final streak = records == null
        ? 0
        : PracticeStats.streakDays(records, today: widget.today);
    // Последняя ЗАВЕРШЁННАЯ техника — для карточки быстрого старта;
    // прерванные практики (completed=false) карточку не задают
    // (фидбек владельца 2026-07-18). Техника могла уйти из каталога —
    // тогда карточку тоже не показываем.
    Technique? lastTechnique;
    if (records != null && records.isNotEmpty) {
      String? id;
      for (int i = records.length - 1; i >= 0; i--) {
        if (records[i].completed) {
          id = records[i].techniqueId;
          break;
        }
      }
      if (id != null) {
        for (final t in catalog) {
          if (t.id == id) {
            lastTechnique = t;
            break;
          }
        }
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: [
          IconButton(
            icon: const BreathinIcon(BreathinIcons.trophy),
            tooltip: l.challengesTooltip,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ChallengesScreen()),
            ),
          ),
          IconButton(
            icon: const BreathinIcon(BreathinIcons.calendar),
            tooltip: l.statsTooltip,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => StatsScreen(today: widget.today)),
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
      // В HANT под каталогом — фон-«чертёж» (в классике прозрачен).
      body: HantBackdrop(child: Builder(builder: (context) {
        // Секции: «Избранное» (дубли, порядок каталога) + три группы.
        final favList =
            catalog.where((t) => _favorites.contains(t.id)).toList();
        final sections = <(String, List<Technique>)>[
          if (favList.isNotEmpty) (l.groupFavorites, favList),
          for (final (title, group) in [
            (l.groupCalm, TechniqueGroup.calm),
            (l.groupEnergy, TechniqueGroup.energy),
            (l.groupTraditions, TechniqueGroup.traditions),
          ])
            (title, catalog.where((t) => groupOf(t) == group).toList()),
        ];
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Стрик-баннер — только при активной серии; тап ведёт
                    // в «Практику» с календарём.
                    if (streak > 0) ...[
                      _StreakBanner(
                        streak: streak,
                        onTap: () => _openThenReload(
                            StatsScreen(today: widget.today)),
                      ),
                      const SizedBox(height: 10),
                    ],
                    // Быстрый старт (У1): последняя техника в один тап.
                    if (lastTechnique != null)
                      _QuickStartCard(
                        technique: lastTechnique,
                        subtitle: techniqueSubtitle(l, lastTechnique),
                        onTap: () => _quickStart(lastTechnique!),
                      ),
                    // Коучмарк: показывается один раз при первом запуске.
                    CoachMark(id: 'home.pick', message: l.coachHomePick),
                  ],
                ),
              ),
            ),
            for (final (title, list) in sections) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.0,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final t = list[index];
                      return _TechniqueGridCard(
                        technique: t,
                        subtitle: techniqueSubtitle(l, t),
                        isFavorite: _favorites.contains(t.id),
                        onToggleFavorite: () => _toggleFavorite(t.id),
                        onTap: () => _openThenReload(
                            TechniqueCardScreen(technique: t)),
                      );
                    },
                    childCount: list.length,
                  ),
                ),
              ),
            ],
            const SliverPadding(padding: EdgeInsets.only(bottom: 12)),
          ],
        );
      })),
    );
  }
}

/// Карточка быстрого старта (У1): «Быстрый старт» + последняя ЗАВЕРШЁННАЯ
/// техника и её паттерн; прерванные практики карточку не задают
/// (фидбек владельца 2026-07-18). Тап запускает сессию с сохранёнными
/// настройками в один тап.
class _QuickStartCard extends StatelessWidget {
  final Technique technique;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickStartCard({
    required this.technique,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListActionCard(
      key: const ValueKey('quick_start'),
      leading: IconBadge(BreathinIcons.playerPlay, radius: 22, primary: true),
      label: l.quickStartTitle,
      title: '${l.techniqueName(technique)} · $subtitle',
      onTap: onTap,
    );
  }
}

/// Компактный «дуолинго»-баннер серии: огонёк, число дней и подпись.
/// Виден только при активной серии; тап ведёт в «Практику».
class _StreakBanner extends StatelessWidget {
  final int streak;
  final VoidCallback onTap;

  const _StreakBanner({required this.streak, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              BreathinIcon(
                BreathinIcons.flame,
                size: 32,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                '$streak',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.streakLabel(streak),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              BreathinIcon(
                BreathinIcons.chevronRight,
                size: 20,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Карточка техники для сетки главного экрана.
class _TechniqueGridCard extends StatelessWidget {
  final Technique technique;
  final String subtitle;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTap;

  const _TechniqueGridCard({
    required this.technique,
    required this.subtitle,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final t = technique;
    final isDimmed = t.stage2;

    // Слоты фиксированной высоты (аудит-фидбек 2026-07-17 «кружки и надписи
    // вразнобой»): кружок, название и подпись у ВСЕХ карточек на одной
    // высоте, независимо от того, на сколько строк переносится название.
    // Высоты слотов текста растут вместе с системным шрифтом.
    final scaler = MediaQuery.textScalerOf(context);
    final titleSlot =
        scaler.scale((theme.textTheme.titleSmall?.fontSize ?? 14) * 1.45) * 2;
    final subtitleSlot =
        scaler.scale((theme.textTheme.bodySmall?.fontSize ?? 12) * 1.5);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // InkWell растянут на ВСЮ карточку (hover раньше подсвечивал
          // только контент — отзыв с ноутбука 2026-07-17).
          InkWell(
            onTap: onTap,
            child: SizedBox.expand(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  children: [
                    // Слот иконки: забирает свободное место; при нехватке
                    // высоты (крупный шрифт) сжимается ИКОНКА, не текст —
                    // одинаково во всех ячейках, выравнивание сохраняется.
                    Flexible(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: IconBadge(
                            iconDataFor(t.icon),
                            radius: 28,
                            dimmed: isDimmed,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Слот названия: всегда высота двух строк.
                    SizedBox(
                      height: titleSlot,
                      child: Center(
                        child: Text(
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
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Слот подписи-паттерна.
                    SizedBox(
                      height: subtitleSlot,
                      child: Center(
                        child: Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Солнышко бодрящих — в левом углу, зеркально звезде: название
          // остаётся чистым и центрированным (влад. §10 + фидбек 2026-07-17).
          if (t.energizing)
            Positioned(
              top: 10,
              left: 10,
              child: BreathinIcon(
                BreathinIcons.sun,
                size: 16,
                color: AppTheme.accentSunColor(context),
              ),
            ),
          // Звезда избранного: тап по ней НЕ открывает карточку.
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: BreathinIcon(
                BreathinIcons.star,
                size: 20,
                color: isFavorite
                    ? AppTheme.accentSunColor(context)
                    : theme.colorScheme.outlineVariant,
              ),
              tooltip: l.favoriteTooltip,
              onPressed: onToggleFavorite,
            ),
          ),
        ],
      ),
    );
  }
}
