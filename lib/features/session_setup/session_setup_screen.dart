import 'package:flutter/material.dart';

import '../../data/technique_settings_repository.dart';
import '../../domain/engine/phase_scaling.dart';
import '../../domain/engine/session_plan_compiler.dart';
import '../../domain/models/feedback_channels.dart';
import '../../domain/models/session_config.dart';
import '../../domain/models/technique.dart';
import '../../domain/models/technique_settings.dart';
import '../../l10n/generated/app_localizations.dart';
import '../session/session_runner.dart';

/// Экран настройки сессии (ТЗ §6.4). Только для counted-техник.
///
/// Позволяет настроить режим окончания (циклы/таймер), длительности фаз,
/// параметры подготовки и каналы сопровождения. Настройки сохраняются
/// при нажатии «Начать сессию».
class SessionSetupScreen extends StatefulWidget {
  final Technique technique;

  const SessionSetupScreen({super.key, required this.technique});

  @override
  State<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends State<SessionSetupScreen> {
  final _repo = TechniqueSettingsRepository();

  /// Текущие настройки; null — идёт загрузка.
  TechniqueSettings? _settings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _repo.load(widget.technique);
    if (mounted) setState(() => _settings = s);
  }

  Technique get _t => widget.technique;

  /// Возвращает локализованное название фазы по [PhaseKind].
  String _phaseLabel(AppLocalizations l, PhaseKind kind) {
    switch (kind) {
      case PhaseKind.inhale:
        return l.phaseInhale;
      case PhaseKind.holdIn:
        return l.phaseHoldIn;
      case PhaseKind.exhale:
        return l.phaseExhale;
      case PhaseKind.holdOut:
        return l.phaseHoldOut;
    }
  }

  /// Запускает сессию: сохраняет настройки, компилирует план (метроном
  /// вшивается в таймлайн на этапе компиляции), открывает раннер.
  Future<void> _startSession() async {
    final s = _settings!;
    await _repo.save(s);
    if (!mounted) return;
    final plan = const SessionPlanCompiler().compile(
      _t,
      s.toSessionConfig(_t),
      metronome: s.feedback.metronome,
    );
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionRunner(
          plan: plan,
          technique: _t,
          feedback: s.feedback,
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
              _techniqueName(l, _t),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _settings = TechniqueSettings.classic(_t);
              });
            },
            child: Text(l.resetToClassic),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // --- Режим окончания ---
          _SectionHeader(title: _endModeLabel(l, s)),
          const SizedBox(height: 8),
          _buildEndModeSegment(l, s, theme),
          const SizedBox(height: 16),

          // --- Длительности фаз (не для tempoMultiplier) ---
          if (_t.scaling != ScalingMode.tempoMultiplier) ...[
            _SectionHeader(title: l.phasesSection),
            const SizedBox(height: 4),
            _buildPhasesSection(l, s, theme),
            const SizedBox(height: 8),
          ],

          // --- Темп (только tempoMultiplier) ---
          if (_t.scaling == ScalingMode.tempoMultiplier &&
              _t.tempoOptions != null) ...[
            _SectionHeader(title: l.tempoLabel),
            const SizedBox(height: 8),
            _buildTempoSection(l, s, theme),
            const SizedBox(height: 8),
          ],

          // --- Подготовка ---
          _SectionHeader(title: l.prepLabel),
          const SizedBox(height: 4),
          _buildPrepSection(l, s),
          const SizedBox(height: 8),

          // --- Сопровождение ---
          _SectionHeader(title: l.feedbackSection),
          _buildFeedbackSection(l, s),
          const SizedBox(height: 16),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _startSession,
              child: Text(l.startSession),
            ),
          ),
        ),
      ),
    );
  }

  // Вспомогательный заголовок секции режима окончания
  String _endModeLabel(AppLocalizations l, TechniqueSettings s) {
    if (s.endMode == EndMode.cycles) {
      return l.cyclesLabel;
    } else {
      return l.timerLabel;
    }
  }

  // ---------- Режим окончания ----------

  Widget _buildEndModeSegment(
    AppLocalizations l,
    TechniqueSettings s,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Переключатель циклы/таймер
        SegmentedButton<EndMode>(
          segments: [
            ButtonSegment(value: EndMode.cycles, label: Text(l.endModeCycles)),
            ButtonSegment(value: EndMode.timer, label: Text(l.endModeTimer)),
          ],
          selected: {s.endMode},
          onSelectionChanged: (v) {
            setState(() {
              _settings = s.copyWith(endMode: v.first);
            });
          },
        ),
        const SizedBox(height: 12),

        if (s.endMode == EndMode.cycles) ...[
          // Слайдер циклов 1..100
          Text('${s.cycles}', style: theme.textTheme.headlineSmall),
          Slider(
            value: s.cycles.toDouble(),
            min: 1,
            max: 100,
            divisions: 99,
            label: '${s.cycles}',
            onChanged: (v) {
              setState(() {
                _settings = s.copyWith(cycles: clampCycles(v.round()));
              });
            },
          ),
        ] else ...[
          ..._buildTimerSlider(s, theme),
        ],
      ],
    );
  }

  /// Слайдер таймера (вынесен, чтобы избежать объявления переменных в spread).
  List<Widget> _buildTimerSlider(TechniqueSettings s, ThemeData theme) {
    final minMin = _t.minTimerMin ?? 1;
    final maxMin = _t.maxTimerMin ?? 60;
    return [
      Text('${s.timerMinutes}', style: theme.textTheme.headlineSmall),
      Slider(
        value: s.timerMinutes.toDouble().clamp(
          minMin.toDouble(),
          maxMin.toDouble(),
        ),
        min: minMin.toDouble(),
        max: maxMin.toDouble(),
        divisions: maxMin - minMin > 0 ? maxMin - minMin : null,
        label: '${s.timerMinutes}',
        onChanged: (v) {
          setState(() {
            _settings = s.copyWith(
              timerMinutes: clampTimerMinutes(_t, v.round()),
            );
          });
        },
      ),
    ];
  }

  // ---------- Длительности фаз ----------

  Widget _buildPhasesSection(
    AppLocalizations l,
    TechniqueSettings s,
    ThemeData theme,
  ) {
    final scaling = _t.scaling;

    // 4-16-8: переключатель «Упрощённый режим»
    if (_t.simplifiedPhases != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: Text(l.simplifiedLabel),
            value: s.useSimplified,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) {
              setState(() {
                _settings = switchSimplified(_t, s, v);
              });
            },
          ),
          ..._buildPhaseSliders(l, s, theme, scaling ?? ScalingMode.perPhase),
        ],
      );
    }

    // ratioOptional: переключатель keepRatio
    if (scaling == ScalingMode.ratioOptional) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: Text(l.keepRatioLabel),
            value: s.keepRatio,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) {
              setState(() {
                _settings = s.copyWith(keepRatio: v);
              });
            },
          ),
          ..._buildPhaseSliders(l, s, theme, scaling!),
        ],
      );
    }

    // perPhase, ratioLock
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildPhaseSliders(
        l,
        s,
        theme,
        scaling ?? ScalingMode.perPhase,
      ),
    );
  }

  /// Строит список слайдеров/отображений фаз в зависимости от режима.
  ///
  /// В ratio-режиме (ratioLock или ratioOptional+keepRatio):
  /// — первая фаза: слайдер (база), вызов applyPhaseChange с index=0;
  /// — остальные фазы: только текст (пропорция).
  /// В perPhase-режиме: слайдер на каждую фазу.
  List<Widget> _buildPhaseSliders(
    AppLocalizations l,
    TechniqueSettings s,
    ThemeData theme,
    ScalingMode scaling,
  ) {
    final specs = activeSpecs(_t, s);
    final secs = s.phaseSeconds;

    final bool ratioMode = scaling == ScalingMode.ratioLock ||
        (scaling == ScalingMode.ratioOptional && s.keepRatio);

    final widgets = <Widget>[];

    for (var i = 0; i < specs.length; i++) {
      final spec = specs[i];
      final value = i < secs.length ? secs[i] : spec.defaultSec;
      final label = _phaseLabel(l, spec.kind);

      if (ratioMode && i > 0) {
        // Производные фазы в ratio-режиме — только текст
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: Text(label)),
                Text(
                  l.secondsShort(_formatSec(value)),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );
      } else {
        // Слайдер: либо единственный (ratio), либо один из нескольких (perPhase)
        final capturedIndex = i;
        widgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label),
                  Text(l.secondsShort(_formatSec(value))),
                ],
              ),
              Slider(
                value: value.clamp(spec.minSec, spec.maxSec),
                min: spec.minSec,
                max: spec.maxSec,
                divisions: ((spec.maxSec - spec.minSec) / sliderStepSec)
                    .round()
                    .clamp(1, 9999),
                label: _formatSec(value),
                onChanged: (v) {
                  setState(() {
                    _settings = s.copyWith(
                      phaseSeconds: applyPhaseChange(_t, s, capturedIndex, v),
                    );
                  });
                },
              ),
            ],
          ),
        );
      }
    }

    return widgets;
  }

  // ---------- Темп ----------

  Widget _buildTempoSection(
    AppLocalizations l,
    TechniqueSettings s,
    ThemeData theme,
  ) {
    final options = _t.tempoOptions!;
    return Wrap(
      spacing: 8,
      children: options.map((opt) {
        final selected = s.tempoMultiplier == opt;
        return ChoiceChip(
          label: Text('×${_formatSec(opt)}'),
          selected: selected,
          onSelected: (_) {
            setState(() {
              _settings = s.copyWith(tempoMultiplier: opt);
            });
          },
        );
      }).toList(),
    );
  }

  // ---------- Подготовка ----------

  Widget _buildPrepSection(AppLocalizations l, TechniqueSettings s) {
    return Slider(
      value: s.prepSeconds.toDouble(),
      min: 3,
      max: 5,
      divisions: 2,
      label: l.secondsShort('${s.prepSeconds}'),
      onChanged: (v) {
        setState(() {
          _settings = s.copyWith(prepSeconds: clampPrepSeconds(v.round()));
        });
      },
    );
  }

  // ---------- Сопровождение ----------

  Widget _buildFeedbackSection(AppLocalizations l, TechniqueSettings s) {
    final fb = s.feedback;
    void toggle(FeedbackChannels updated) {
      setState(() {
        _settings = s.copyWith(feedback: updated);
      });
    }

    return Column(
      children: [
        SwitchListTile(
          title: Text(l.channelVoice),
          value: fb.voice,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => toggle(fb.copyWith(voice: v)),
        ),
        SwitchListTile(
          title: Text(l.channelSound),
          value: fb.sound,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => toggle(fb.copyWith(sound: v)),
        ),
        SwitchListTile(
          title: Text(l.channelMetronome),
          value: fb.metronome,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => toggle(fb.copyWith(metronome: v)),
        ),
        SwitchListTile(
          title: Text(l.channelVibration),
          value: fb.vibration,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => toggle(fb.copyWith(vibration: v)),
        ),
        SwitchListTile(
          title: Text(l.channelVisual),
          value: fb.visual,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => toggle(fb.copyWith(visual: v)),
        ),
      ],
    );
  }

  /// Форматирует секунды: целое без дроби, дробное с одним знаком.
  static String _formatSec(double sec) {
    if (sec == sec.roundToDouble()) return sec.toInt().toString();
    return sec.toStringAsFixed(1);
  }

  /// Локализованное название техники через ARB-ключ (через switch по id,
  /// т.к. AppLocalizations не поддерживает динамические ключи).
  String _techniqueName(AppLocalizations l, Technique t) {
    // Используем уже существующую утилиту из technique_texts через l
    // Ключи вида tech_<id>_name; AppLocalizations хранит их как геттеры.
    // Самый надёжный способ — обратиться к уже реализованному методу.
    switch (t.id) {
      case 'box':
        return l.tech_box_name;
      case 'triangle':
        return l.tech_triangle_name;
      case 'four_seven_eight':
        return l.tech_four_seven_eight_name;
      case 'four_two_four':
        return l.tech_four_two_four_name;
      case 'two_eight':
        return l.tech_two_eight_name;
      case 'two_ten':
        return l.tech_two_ten_name;
      case 'four_sixteen_eight':
        return l.tech_four_sixteen_eight_name;
      case 'coherent':
        return l.tech_coherent_name;
      default:
        return t.id;
    }
  }
}

/// Заголовок секции настройки.
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
