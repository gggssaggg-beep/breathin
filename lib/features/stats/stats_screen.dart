import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/session_log_repository.dart';
import '../../domain/catalog/techniques.dart';
import '../../domain/models/session_record.dart';
import '../../domain/models/technique.dart';
import '../../domain/stats/practice_stats.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../l10n/technique_texts.dart';
import '../../services/auth/auth_service.dart';
import '../../ui/hant/hant_backdrop.dart';
import '../../ui/icons/breathin_icon.dart';
import '../../ui/icons/breathin_icons.dart';
import '../../ui/widgets/section_header.dart';
import '../bolt/bolt_test_screen.dart';
import '../catalog/technique_icons.dart';

/// Экран «Практика» (ТЗ §5, П11): календарь месяца с отметками дней,
/// streak и суммы за месяц. Данные — локальная история сессий.
class StatsScreen extends StatefulWidget {
  final SessionLogRepository log;

  /// «Сегодня» для тестируемости; по умолчанию — текущая дата устройства.
  final DateTime? today;

  StatsScreen({super.key, SessionLogRepository? log, this.today})
      : log = log ?? SessionLogRepository();

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

const _kGuestHintKey = 'stats.guest_hint_dismissed.v1';

class _StatsScreenState extends State<StatsScreen> {
  List<SessionRecord>? _records;
  late DateTime _today;
  late int _year;
  late int _month;
  bool _guestHintDismissed = false;

  @override
  void initState() {
    super.initState();
    _today = widget.today ?? DateTime.now();
    _year = _today.year;
    _month = _today.month;
    widget.log.all().then((r) {
      if (mounted) setState(() => _records = r);
    });
    SharedPreferences.getInstance().then((prefs) {
      if (mounted) {
        setState(
          () => _guestHintDismissed = prefs.getBool(_kGuestHintKey) ?? false,
        );
      }
    });
  }

  void _dismissGuestHint() {
    setState(() => _guestHintDismissed = true);
    // fire-and-forget персист
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool(_kGuestHintKey, true),
    );
  }

  bool get _isGuest {
    const auth = AuthService();
    return !auth.isReady || auth.currentUser == null;
  }

  bool get _atCurrentMonth => _year == _today.year && _month == _today.month;

  void _shiftMonth(int delta) {
    setState(() {
      final m = DateTime(_year, _month + delta);
      _year = m.year;
      _month = m.month;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final records = _records;
    return Scaffold(
      appBar: AppBar(title: Text(l.statsTitle)),
      // В HANT под статистикой — фон-«чертёж» (в классике HantBackdrop прозрачен).
      body: HantBackdrop(
        child: records == null
            ? const Center(child: CircularProgressIndicator())
            : records.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const _BoltEntryCard(),
                      const SizedBox(height: 24),
                      _Empty(text: l.statsEmpty),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_isGuest &&
                          records.length >= 10 &&
                          !_guestHintDismissed) ...[
                        _GuestHintCard(onDismiss: _dismissGuestHint),
                        const SizedBox(height: 16),
                      ],
                      _SummaryRow(records: records, today: _today),
                      const SizedBox(height: 24),
                      _MonthHeader(
                        year: _year,
                        month: _month,
                        canGoNext: !_atCurrentMonth,
                        onPrev: () => _shiftMonth(-1),
                        onNext: () => _shiftMonth(1),
                      ),
                      const SizedBox(height: 12),
                      _MonthCalendar(
                        records: records,
                        year: _year,
                        month: _month,
                        today: _today,
                      ),
                      const SizedBox(height: 16),
                      _MonthTotals(records: records, year: _year, month: _month),
                      const SizedBox(height: 16),
                      const _BoltEntryCard(),
                      const SizedBox(height: 16),
                      _ByTechnique(records: records, year: _year, month: _month),
                    ],
                  ),
      ),
    );
  }
}

/// Закрываемая подсказка гостю о локальности истории (В1).
/// Показывается, когда записей ≥ 10 и карточка ещё не закрывалась.
class _GuestHintCard extends StatelessWidget {
  final VoidCallback onDismiss;
  const _GuestHintCard({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BreathinIcon(
              BreathinIcons.user,
              size: 22,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l.statsGuestHint,
                style: theme.textTheme.bodySmall,
              ),
            ),
            TextButton(
              onPressed: onDismiss,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(l.commonDismiss),
            ),
          ],
        ),
      ),
    );
  }
}

/// Карточка-вход в дыхательный тест BOLT (эпик персонализации §3).
class _BoltEntryCard extends StatelessWidget {
  const _BoltEntryCard();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BoltTestScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              BreathinIcon(
                BreathinIcons.chartBar,
                size: 28,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.boltTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    Text(
                      l.boltEntrySubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              BreathinIcon(
                BreathinIcons.chevronRight,
                size: 20,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BreathinIcon(
              BreathinIcons.calendar,
              size: 56,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Верхняя карточка: streak огоньком.
class _SummaryRow extends StatelessWidget {
  final List<SessionRecord> records;
  final DateTime today;
  const _SummaryRow({required this.records, required this.today});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final streak = PracticeStats.streakDays(records, today: today);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            BreathinIcon(
              BreathinIcons.flame,
              size: 40,
              color: streak > 0
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
            const SizedBox(width: 16),
            Text('$streak', style: theme.textTheme.displaySmall),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l.streakLabel(streak),
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final int year;
  final int month;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthHeader({
    required this.year,
    required this.month,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final title = DateFormat.yMMMM(locale).format(DateTime(year, month));
    final theme = Theme.of(context);
    return Row(
      children: [
        IconButton(
          onPressed: onPrev,
          icon: Transform.flip(
            flipX: true,
            child: const BreathinIcon(BreathinIcons.chevronRight, size: 20),
          ),
        ),
        Expanded(
          child: Text(
            title[0].toUpperCase() + title.substring(1),
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        ),
        IconButton(
          onPressed: canGoNext ? onNext : null,
          icon: BreathinIcon(
            BreathinIcons.chevronRight,
            size: 20,
            color: canGoNext ? null : theme.colorScheme.outlineVariant,
          ),
        ),
      ],
    );
  }
}

/// Сетка месяца: понедельник — первый день недели; практикованные дни —
/// заливка primary с интенсивностью по минутам, сегодня — контур.
class _MonthCalendar extends StatelessWidget {
  final List<SessionRecord> records;
  final int year;
  final int month;
  final DateTime today;

  const _MonthCalendar({
    required this.records,
    required this.year,
    required this.month,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final minutes = PracticeStats.minutesByDay(records, year, month);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // 1 = Пн … 7 = Вс (DateTime.weekday); сдвиг первой недели.
    final leading = DateTime(year, month, 1).weekday - 1;

    final symbols = DateFormat.E(locale).dateSymbols.STANDALONESHORTWEEKDAYS;
    // STANDALONESHORTWEEKDAYS начинается с воскресенья — переставляем на Пн.
    final weekdays = [for (var i = 1; i <= 7; i++) symbols[i % 7]];

    final cells = <Widget>[
      for (final w in weekdays)
        Center(
          child: Text(
            w,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      for (var i = 0; i < leading; i++) const SizedBox.shrink(),
      for (var day = 1; day <= daysInMonth; day++)
        _DayCell(
          day: day,
          minutes: minutes[day] ?? 0,
          isToday: year == today.year &&
              month == today.month &&
              day == today.day,
        ),
    ];

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      children: cells,
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final int minutes;
  final bool isToday;
  const _DayCell({
    required this.day,
    required this.minutes,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final practised = minutes > 0;
    // Интенсивность заливки растёт до ~20 минут в день.
    final alpha = practised ? 0.30 + 0.70 * (minutes / 20).clamp(0.0, 1.0) : 0.0;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: practised
            ? theme.colorScheme.primary.withValues(alpha: alpha)
            : null,
        border: isToday
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '$day',
        style: theme.textTheme.bodySmall?.copyWith(
          color: practised && alpha > 0.6
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface,
          fontWeight: practised ? FontWeight.w600 : null,
        ),
      ),
    );
  }
}

/// Разбивка месяца по техникам: иконка, название, сессии · минуты.
class _ByTechnique extends StatelessWidget {
  final List<SessionRecord> records;
  final int year;
  final int month;
  const _ByTechnique({
    required this.records,
    required this.year,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final rows = PracticeStats.byTechnique(records, year, month);
    if (rows.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: SectionHeader(l.byTechniqueLabel),
            ),
            for (final (id, agg) in rows) _row(context, id, agg),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String id,
    ({int sessions, int minutes}) agg,
  ) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // Записи старых версий каталога не должны ронять экран.
    Technique? t;
    try {
      t = techniqueById(id);
    } on ArgumentError {
      t = null;
    }
    // Варианты паттерна («4-8-8 ×3 · 4-16-8 ×1») — виден режим практики
    // и прогресс упрощённый → полный (влад. §15).
    final variants = PracticeStats.variantsFor(records, year, month, id);
    final variantsLine =
        variants.map((v) => '${v.$1} ×${v.$2}').join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (t != null)
            BreathinIcon(
              iconDataFor(t.icon),
              size: 22,
              color: theme.colorScheme.primary,
            )
          else
            const SizedBox(width: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t != null ? l.techniqueName(t) : id,
                  style: theme.textTheme.bodyLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                if (variants.isNotEmpty)
                  Text(
                    variantsLine,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            '${agg.sessions} ${l.monthSessionsLabel(agg.sessions)}'
            ' · ${l.minutesShort(agg.minutes)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Итоги месяца: минуты и число сессий.
class _MonthTotals extends StatelessWidget {
  final List<SessionRecord> records;
  final int year;
  final int month;
  const _MonthTotals({
    required this.records,
    required this.year,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final minutes = PracticeStats.minutesInMonth(records, year, month);
    final sessions = PracticeStats.sessionsInMonth(records, year, month);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            BreathinIcon(
              BreathinIcons.chartBar,
              size: 28,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Text('$minutes', style: theme.textTheme.headlineSmall),
            const SizedBox(width: 6),
            Text(l.monthMinutesLabel, style: theme.textTheme.bodyMedium),
            const Spacer(),
            Text('$sessions', style: theme.textTheme.headlineSmall),
            const SizedBox(width: 6),
            Text(
              l.monthSessionsLabel(sessions),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
