import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/bolt_repository.dart';
import '../../domain/bolt/bolt_interpretation.dart';
import '../../domain/models/bolt_result.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../ui/icons/breathin_icon.dart';
import '../../ui/icons/breathin_icons.dart';
import 'bolt_chart.dart';
import 'bolt_texts.dart';

/// Экран дыхательного теста BOLT (эпик персонализации §3). Три стадии:
/// вступление с методикой и дисклеймером → задержка (секундомер, стоп по
/// тапу при первом позыве) → результат с интерпретацией и сохранением.
///
/// Научная рамка и честные формулировки — docs/research/BOLT_scientific_reference.md.
class BoltTestScreen extends StatefulWidget {
  final BoltRepository? repo;

  const BoltTestScreen({super.key, this.repo});

  @override
  State<BoltTestScreen> createState() => _BoltTestScreenState();
}

enum _Stage { intro, holding, result }

class _BoltTestScreenState extends State<BoltTestScreen> {
  late final BoltRepository _repo = widget.repo ?? BoltRepository();

  _Stage _stage = _Stage.intro;
  List<BoltResult>? _history;

  // Отсчёт ведём аккумулятором тиков, а не Stopwatch: Stopwatch читает
  // реальные часы, которые виджет-тест (fake-async) не двигает — тик-таймер
  // же управляется pump(). Шаг 100 мс над десятками секунд теста достаточно
  // точен, а Timer.periodic планирует следующий тик от момента срабатывания
  // (не теряет счёт).
  static const _tick = Duration(milliseconds: 100);
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  int _seconds = 0; // финальный результат стадии result
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _repo.all().then((r) {
      if (mounted) setState(() => _history = r);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startHold() {
    _elapsed = Duration.zero;
    _ticker = Timer.periodic(_tick, (_) {
      if (mounted) setState(() => _elapsed += _tick);
    });
    setState(() => _stage = _Stage.holding);
  }

  void _stopHold() {
    _ticker?.cancel();
    setState(() {
      _seconds = _elapsed.inSeconds;
      _saved = false;
      _stage = _Stage.result;
    });
  }

  Future<void> _save() async {
    final result = BoltResult(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      takenAt: DateTime.now(),
      seconds: _seconds,
    );
    await _repo.add(result);
    final fresh = await _repo.all();
    if (!mounted) return;
    setState(() {
      _history = fresh;
      _saved = true;
    });
  }

  void _retry() => setState(() => _stage = _Stage.intro);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: _stage == _Stage.holding
          ? null
          : AppBar(title: Text(l.boltTitle)),
      body: SafeArea(
        child: switch (_stage) {
          _Stage.intro => _IntroView(history: _history, onStart: _startHold),
          _Stage.holding => _HoldingView(
              elapsed: _elapsed,
              onStop: _stopHold,
            ),
          _Stage.result => _ResultView(
              seconds: _seconds,
              saved: _saved,
              onSave: _save,
              onRetry: _retry,
            ),
        },
      ),
    );
  }
}

// ─── Вступление ───────────────────────────────────────────────────────────

class _IntroView extends StatelessWidget {
  final List<BoltResult>? history;
  final VoidCallback onStart;

  const _IntroView({required this.history, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hist = history ?? const [];
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (hist.isNotEmpty) ...[
                _Section(title: l.boltHistoryTitle),
                _LatestCard(results: hist),
                const SizedBox(height: 8),
                BoltChart(results: hist),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l.boltProgressHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              _Section(title: l.boltIntroHeading),
              Text(l.boltIntro, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 20),
              _Section(title: l.boltMethodHeading),
              Text(l.boltMethod, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 20),
              // Дисклеймер: честная рамка «не медицина» (научный справочник).
              Card(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BreathinIcon(BreathinIcons.circleCheck,
                          size: 20, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l.boltDisclaimer,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onStart,
              child: Text(l.boltStartAction),
            ),
          ),
        ),
      ],
    );
  }
}

class _LatestCard extends StatelessWidget {
  final List<BoltResult> results;
  const _LatestCard({required this.results});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final last = results.last;
    final level = boltLevelFor(last.seconds);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Text('${last.seconds}', style: theme.textTheme.displaySmall),
            const SizedBox(width: 8),
            Text('с', style: theme.textTheme.titleMedium),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.boltLatestLabel, style: theme.textTheme.bodySmall),
                  Text(
                    l.boltLevelName(level),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Задержка (секундомер) ──────────────────────────────────────────────────

class _HoldingView extends StatelessWidget {
  final Duration elapsed;
  final VoidCallback onStop;

  const _HoldingView({required this.elapsed, required this.onStop});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // Весь экран — тап-зона: остановить можно откуда угодно.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onStop,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l.boltHoldInstruction,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Text(
              '${elapsed.inSeconds}',
              style: theme.textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              l.boltFirstUrgeHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: onStop,
                child: Text(l.boltStopAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Результат ──────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  final int seconds;
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onRetry;

  const _ResultView({
    required this.seconds,
    required this.saved,
    required this.onSave,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final level = boltLevelFor(seconds);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 16),
              Center(
                child: Text(l.boltResultHeading,
                    style: theme.textTheme.titleMedium),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  l.boltSecondsValue(seconds),
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(l.boltLevelName(level),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                )),
                          ),
                          Text(
                            l.boltRangeLabel(boltRangeText(level)),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(l.boltLevelDescription(level),
                          style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.boltDisclaimer,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: onRetry,
                  child: Text(l.boltRetryAction),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: saved ? null : onSave,
                  child: Text(saved ? l.sessionDone : l.boltSaveAction),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Мелочи ──────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  const _Section({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
