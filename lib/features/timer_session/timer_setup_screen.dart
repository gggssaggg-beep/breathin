import 'package:flutter/material.dart';

import '../../data/timer_settings_store.dart';
import '../../domain/engine/timer_session.dart';
import '../../domain/models/technique.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../l10n/technique_texts.dart';
import '../../ui/hant/hant_backdrop.dart';
import 'timer_session_screen.dart';

/// Настройка таймер-сессии (ПЛАН §10, партия T2): длительность практики,
/// интервал подсказок смены ноздри (только у Нади Шодханы), подготовка,
/// каналы звука/вибро. Метронома нет — для свободного дыхания без счёта
/// он не имеет смысла (ПЛАН §1.5). Предупреждений-гейтов нет: все
/// таймер-техники — safety low.
class TimerSetupScreen extends StatefulWidget {
  final Technique technique;

  const TimerSetupScreen({super.key, required this.technique});

  @override
  State<TimerSetupScreen> createState() => _TimerSetupScreenState();
}

class _TimerSetupScreenState extends State<TimerSetupScreen> {
  final _store = TimerSettingsStore();
  TimerSettings? _settings;

  Technique get _t => widget.technique;

  @override
  void initState() {
    super.initState();
    _store.load(_t).then((s) {
      if (mounted) setState(() => _settings = s);
    });
  }

  void _update(TimerSettings s) {
    setState(() => _settings = s);
    // Fire-and-forget, как настройки других техник.
    _store.save(_t.id, s);
  }

  Future<void> _start() async {
    final s = _settings!;
    await _store.save(_t.id, s);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TimerSessionScreen(
          technique: _t,
          config: TimerSessionConfig(
            minutes: s.minutes,
            prepSeconds: s.prepSeconds,
            cueIntervalSec: s.cueIntervalSec,
          ),
          sound: s.sound,
          vibration: s.vibration,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = _settings;
    if (s == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.setupTitle)),
        body: const HantBackdrop(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final minMin = _t.minTimerMin!;
    final maxMin = _t.maxTimerMin!;
    final cue = _t.periodicCue;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.setupTitle, style: theme.textTheme.titleMedium),
            Text(
              l.techniqueName(_t),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      // В HANT под настройкой таймера — фон-«чертёж» (в классике HantBackdrop прозрачен).
      body: HantBackdrop(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
          _SliderTile(
            label: l.timerDurationLabel,
            value: l.minutesShort(s.minutes),
            slider: Slider(
              value: s.minutes.toDouble(),
              min: minMin.toDouble(),
              max: maxMin.toDouble(),
              divisions: maxMin > minMin ? maxMin - minMin : null,
              onChanged: (v) => _update(s.copyWith(minutes: v.round())),
            ),
          ),
          // Подсказки смены ноздри — только у техник с periodicCue
          // (Нади Шодхана); 0 = выкл.
          if (cue != null) ...[
            const SizedBox(height: 8),
            Text(
              l.timerCueLabel,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final v in cue.intervalOptionsSec)
                  ChoiceChip(
                    label: Text(v == 0 ? l.timerCueOff : l.secondsShort('$v')),
                    selected: s.cueIntervalSec == v,
                    onSelected: (_) => _update(s.copyWith(cueIntervalSec: v)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l.timerCueSoundHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          _SliderTile(
            label: l.prepLabel,
            value: l.secondsShort('${s.prepSeconds}'),
            slider: Slider(
              value: s.prepSeconds.toDouble(),
              min: 3,
              max: 5,
              divisions: 2,
              onChanged: (v) => _update(s.copyWith(prepSeconds: v.round())),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: Text(l.channelSound),
            value: s.sound,
            onChanged: (v) => _update(s.copyWith(sound: v)),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: Text(l.channelVibration),
            value: s.vibration,
            onChanged: (v) => _update(s.copyWith(vibration: v)),
            contentPadding: EdgeInsets.zero,
          ),
        ],
        ),
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

/// Строка «метка — значение — слайдер» (как в wim_hof_setup_screen.dart —
/// класс там приватный, поэтому продублирован).
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
