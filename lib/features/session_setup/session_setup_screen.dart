import 'package:flutter/material.dart';

import '../../data/technique_settings_repository.dart';
import '../../features/onboarding/coach_mark.dart';
import '../../domain/catalog/fikr_phrases.dart';
import '../../domain/engine/phase_scaling.dart';
import '../../domain/engine/session_plan.dart';
import '../../domain/engine/session_plan_compiler.dart';
import '../../domain/models/feedback_channels.dart';
import '../../domain/models/session_config.dart';
import '../../domain/models/session_record.dart';
import '../../domain/models/technique.dart';
import '../../domain/models/technique_settings.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../l10n/technique_texts.dart';
import '../../ui/icons/breathin_icon.dart';
import '../../ui/icons/breathin_icons.dart';
import '../session/phase_labels.dart';
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

  @override
  void dispose() {
    // Настройки не должны теряться при выходе без запуска (корректировка
    // владельца №7). await в dispose нельзя — сохраняем fire-and-forget.
    if (_settings != null) _repo.save(_settings!);
    super.dispose();
  }

  Future<void> _load() async {
    final s = await _repo.load(widget.technique);
    if (mounted) setState(() => _settings = s);
  }

  Technique get _t => widget.technique;

  /// Запускает сессию: сохраняет настройки, компилирует план (метроном
  /// вшивается в таймлайн на этапе компиляции), открывает раннер.
  Future<void> _startSession() async {
    final s = _settings!;
    await _repo.save(s);
    if (!mounted) return;
    final l = AppLocalizations.of(context);

    final SessionPlan plan;
    final String? variant;
    if (_t.type == TechniqueType.scripted) {
      // Вытягивающее: фиксированный скрипт, без пользовательских длительностей.
      plan = const SessionPlanCompiler().compileScript(
        _t.cycleScript!,
        prepSeconds: s.prepSeconds,
        metronome: s.feedback.metronome,
      );
      variant = null;
    } else {
      final config = s.toSessionConfig(_t);
      plan = const SessionPlanCompiler().compile(
        _t,
        config,
        metronome: s.feedback.metronome,
      );
      // Фактический паттерн (упрощённый/полный/пользовательский) —
      // в историю практик (влад. §15).
      variant = variantOf(config.phaseSeconds);
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionRunner(
          plan: plan,
          technique: _t,
          feedback: s.feedback,
          mediaTitle: _techniqueName(l, _t),
          variant: variant,
          phrase: _t.id == 'fikr' ? fikrPhraseById(s.phraseId) : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = _settings;
    // Скриптовая техника (вытягивающее): паттерн фиксирован — без слайдеров
    // фаз/циклов и без «Сбросить к классике». Только подготовка и сопровождение.
    final isScripted = _t.type == TechniqueType.scripted;

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
          if (!isScripted)
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
          // --- Скриптовая техника: фиксированный рисунок дыхания ---
          if (isScripted) ...[
            _SectionHeader(title: l.stretchPatternTitle),
            const SizedBox(height: 8),
            Text(
              _t.id == 'elemental' ? l.elementalPatternDesc : l.stretchPatternDesc,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ] else ...[
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

            // --- Фразы фикра (№10): аффирмации / вазифы ---
            if (_t.id == 'fikr') ...[
              _SectionHeader(title: l.fikrPhrasesLabel),
              const SizedBox(height: 4),
              _buildFikrPhraseSection(l, s, theme),
              const SizedBox(height: 8),
            ],
          ],

          // --- Подготовка ---
          _SectionHeader(title: l.prepLabel),
          const SizedBox(height: 4),
          _buildPrepSection(l, s),
          const SizedBox(height: 8),

          // --- Сопровождение ---
          // Коучмарк над секцией: показывается один раз
          CoachMark(
            id: 'setup.feedback',
            message: l.coachSetupFeedback,
          ),
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
      final label = phaseLabel(l, spec.kind);

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
    // Значение видно справа от слайдера — иначе непонятно, что стоит 3 с.
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: s.prepSeconds.toDouble(),
            min: 3,
            max: 5,
            divisions: 2,
            label: l.secondsShort('${s.prepSeconds}'),
            onChanged: (v) {
              setState(() {
                _settings =
                    s.copyWith(prepSeconds: clampPrepSeconds(v.round()));
              });
            },
          ),
        ),
        const SizedBox(width: 4),
        Text(l.secondsShort('${s.prepSeconds}')),
      ],
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
        // Голосовой канал не реализован до партии П8 — тумблер disabled,
        // жёстко выключен, с подписью «скоро». Включим в П8.
        SwitchListTile(
          title: Text(l.channelVoice),
          value: false,
          contentPadding: EdgeInsets.zero,
          subtitle: Text(l.comingSoonBadge),
          onChanged: null,
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
        // Тумблера «Визуальный режим» нет: визуал всегда включён
        // (решение владельца, живой отзыв v0.3.0; поле в модели осталось
        // для совместимости сохранений).
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
  /// Локальный switch дублировал TechniqueTexts и молча отдавал сырой id
  /// для новых техник (фикр) — теперь единый источник из technique_texts.
  String _techniqueName(AppLocalizations l, Technique t) => l.techniqueName(t);

  /// Выбор пары фраз фикра: два подсписка (аффирмации, вазифы), отмеченная
  /// пара — галочка. Без Radio: его groupValue-API в новых Flutter уходит
  /// в RadioGroup, а selected+галочка читается не хуже.
  Widget _buildFikrPhraseSection(
      AppLocalizations l, TechniqueSettings s, ThemeData theme) {
    final selected = fikrPhraseById(s.phraseId).id;
    final children = <Widget>[];
    for (final set in FikrPhraseSet.values) {
      children.add(Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 2),
        child: Text(
          l.fikrSetLabel(set),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ));
      for (final p in fikrPhrases.where((p) => p.set == set)) {
        final isSelected = p.id == selected;
        children.add(ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          selected: isSelected,
          title: Text('${l.fikrPhraseIn(p)} · ${l.fikrPhraseEx(p)}'),
          trailing: isSelected
              ? BreathinIcon(
                  BreathinIcons.circleCheck,
                  size: 20,
                  color: theme.colorScheme.primary,
                )
              : null,
          onTap: () => setState(() => _settings = s.copyWith(phraseId: p.id)),
        ));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
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
