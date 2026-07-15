import 'package:flutter/material.dart';

import '../../data/wim_hof_settings_store.dart';
import '../../domain/engine/wim_hof_machine.dart';
import '../../domain/models/technique.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../l10n/technique_texts.dart';
import 'wim_hof_session_screen.dart';

/// Настройка метода Вима Хофа (ПЛАН §3.4, этап 2): дыханий в раунде,
/// темп, раунды. «Начать» ведёт через полноэкранное предупреждение
/// (ТЗ §2.4: high-уровень подтверждается явно при каждом запуске).
class WimHofSetupScreen extends StatefulWidget {
  final Technique technique;

  const WimHofSetupScreen({super.key, required this.technique});

  @override
  State<WimHofSetupScreen> createState() => _WimHofSetupScreenState();
}

class _WimHofSetupScreenState extends State<WimHofSetupScreen> {
  final _store = WimHofSettingsStore();
  WimHofConfig? _config;

  WimHofDefaults get _d => widget.technique.wimHof!;

  @override
  void initState() {
    super.initState();
    _store.load(_d).then((c) {
      if (mounted) setState(() => _config = c);
    });
  }

  void _update(WimHofConfig c) {
    setState(() => _config = c);
    // Fire-and-forget, как настройки других техник.
    _store.save(c);
  }

  Future<void> _start() async {
    final c = _config!;
    await _store.save(c);
    if (!mounted) return;
    // Полноэкранный safety-гейт: сессия стартует только после явного
    // подтверждения (каждый запуск — так по ТЗ для high-уровня).
    final accepted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _WimHofWarningScreen(technique: widget.technique),
        fullscreenDialog: true,
      ),
    );
    if (accepted != true || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WimHofSessionScreen(
          technique: widget.technique,
          config: c,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = _config;
    if (c == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.setupTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.setupTitle, style: theme.textTheme.titleMedium),
            Text(
              l.techniqueName(widget.technique),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _SliderTile(
            label: l.whBreathsLabel,
            value: '${c.breaths}',
            slider: Slider(
              value: c.breaths.toDouble(),
              min: _d.minBreaths.toDouble(),
              max: _d.maxBreaths.toDouble(),
              divisions: _d.maxBreaths - _d.minBreaths,
              onChanged: (v) => _update(WimHofConfig(
                breaths: v.round(),
                paceSec: c.paceSec,
                rounds: c.rounds,
                recoveryHoldSec: c.recoveryHoldSec,
              )),
            ),
          ),
          _SliderTile(
            label: l.whPaceLabel,
            value: l.whPaceValue(c.paceSec.toStringAsFixed(1)),
            slider: Slider(
              value: c.paceSec,
              min: _d.minPaceSec,
              max: _d.maxPaceSec,
              divisions:
                  ((_d.maxPaceSec - _d.minPaceSec) / 0.1).round(),
              onChanged: (v) => _update(WimHofConfig(
                breaths: c.breaths,
                paceSec: (v * 10).round() / 10,
                rounds: c.rounds,
                recoveryHoldSec: c.recoveryHoldSec,
              )),
            ),
          ),
          _SliderTile(
            label: l.whRoundsLabel,
            value: '${c.rounds}',
            slider: Slider(
              value: c.rounds.toDouble(),
              min: _d.minRounds.toDouble(),
              max: _d.maxRounds.toDouble(),
              divisions: _d.maxRounds - _d.minRounds,
              onChanged: (v) => _update(WimHofConfig(
                breaths: c.breaths,
                paceSec: c.paceSec,
                rounds: v.round(),
                recoveryHoldSec: c.recoveryHoldSec,
              )),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _start,
              child: Text(l.startSession),
            ),
          ),
        ),
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final String label;
  final String value;
  final Slider slider;

  const _SliderTile({
    required this.label,
    required this.value,
    required this.slider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(value, style: theme.textTheme.bodyMedium),
          ],
        ),
        slider,
      ],
    );
  }
}

/// Полноэкранное предупреждение перед стартом ВХ (safety_intense из ТЗ §2.4).
/// pop(true) — пользователь явно принял риски.
class _WimHofWarningScreen extends StatelessWidget {
  final Technique technique;

  const _WimHofWarningScreen({required this.technique});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.whWarningTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    color: theme.colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l.safetyText(technique),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(l.whAcceptStart),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l.whBackAction),
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
