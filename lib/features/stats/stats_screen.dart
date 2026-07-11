import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/session_log_repository.dart';
import '../../domain/models/session_record.dart';
import '../../domain/stats/practice_stats.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../ui/icons/breathin_icon.dart';
import '../../ui/icons/breathin_icons.dart';

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

class _StatsScreenState extends State<StatsScreen> {
  List<SessionRecord>? _records;
  late DateTime _today;
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _today = widget.today ?? DateTime.now();
    _year = _today.year;
    _month = _today.month;
    widget.log.all().then((r) {
      if (mounted) setState(() => _records = r);
    });
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
      body: records == null
          ? const Center(child: CircularProgressIndicator())
          : records.isEmpty
              ? _Empty(text: l.statsEmpty)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
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
                  ],
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
