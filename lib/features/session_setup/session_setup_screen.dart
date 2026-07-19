import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/bolt_repository.dart';
import '../../data/custom_fikr_store.dart';
import '../../data/difficulty_store.dart';
import '../../data/feedback_channels_store.dart';
import '../../data/technique_settings_repository.dart';
import '../../features/onboarding/coach_mark.dart';
import '../../domain/bolt/bolt_interpretation.dart';
import '../../domain/catalog/fikr_phrases.dart';
import '../../domain/difficulty/difficulty.dart';
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
import '../../ui/hant/hant_backdrop.dart';
import '../../ui/icons/breathin_icon.dart';
import '../../ui/icons/breathin_icons.dart';
import '../../ui/widgets/section_header.dart';
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

  /// Базовые настройки под текущий глобальный пресет сложности — состояние
  /// кнопки «Сбросить» и дефолт для ни разу не настроенной техники (§4–5).
  TechniqueSettings? _baseline;

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
    // Базовые длительности под глобальный пресет сложности; для «Своего
    // дыхания» — по последнему BOLT (§4). Сохранённые вручную настройки
    // имеют приоритет над пресетом (пресет не перетирает выбор пользователя).
    final saved = await _repo.loadSaved(widget.technique);
    final preset = await DifficultyStore().load();
    BoltLevel? boltLevel;
    if (preset == DifficultyPreset.mine) {
      final results = await BoltRepository().all();
      if (results.isNotEmpty) {
        boltLevel = boltLevelFor(results.last.seconds);
      }
    }
    final baseline = _presetBaseline(preset, boltLevel);
    // Каналы сопровождения — глобальный выбор (фидбек владельца 2026-07-19 №2):
    // пер-техника настройки подменяются глобальным стором.
    final globalFeedback = await FeedbackChannelsStore().load();
    if (mounted) {
      setState(() {
        _baseline = baseline;
        _settings = (saved ?? baseline).copyWith(feedback: globalFeedback);
      });
    }
  }

  /// Классические настройки, домноженные на пресет сложности (только для
  /// counted-техник со свободными фазами; иначе — чистая классика).
  TechniqueSettings _presetBaseline(DifficultyPreset preset, BoltLevel? bolt) {
    final classic = TechniqueSettings.classic(_t);
    if (!presetAffects(_t)) return classic;
    final mult = difficultyMultiplier(preset, boltLevel: bolt);
    return classic.copyWith(phaseSeconds: presetPhaseSeconds(_t, mult));
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

    // Резолвим тексты фразы фикра заранее (до push), чтобы view видел
    // уже готовые строки и не зависел от локализации внутри.
    ({String inhale, String exhale})? phraseTexts;
    if (_t.id == 'fikr') {
      if (s.phraseId == customFikrPhraseId) {
        final custom = await CustomFikrPhraseStore().load();
        if (custom != null) {
          phraseTexts = custom;
        } else {
          // Своя фраза не задана — fallback к дефолтной ('calm').
          final p = defaultFikrPhrase;
          phraseTexts = (inhale: l.fikrPhraseIn(p), exhale: l.fikrPhraseEx(p));
        }
      } else {
        final p = fikrPhraseById(s.phraseId);
        phraseTexts = (inhale: l.fikrPhraseIn(p), exhale: l.fikrPhraseEx(p));
      }
    }
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionRunner(
          plan: plan,
          technique: _t,
          feedback: s.feedback,
          mediaTitle: _techniqueName(l, _t),
          variant: variant,
          phraseTexts: phraseTexts,
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
        body: const HantBackdrop(
          child: Center(child: CircularProgressIndicator()),
        ),
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
                // Сброс — к базовым настройкам под текущий пресет сложности
                // (не к «голой» классике, иначе пресет было бы не вернуть).
                setState(() {
                  _settings = _baseline ?? TechniqueSettings.classic(_t);
                });
              },
              child: Text(l.resetToClassic),
            ),
        ],
      ),
      // В HANT под настройкой сессии — фон-«чертёж» (в классике HantBackdrop прозрачен).
      body: HantBackdrop(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
          // --- Скриптовая техника: фиксированный рисунок дыхания ---
          if (isScripted) ...[
            SectionHeader(l.stretchPatternTitle),
            const SizedBox(height: 8),
            Text(
              _t.id == 'elemental' ? l.elementalPatternDesc : l.stretchPatternDesc,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ] else ...[
            // --- Режим окончания ---
            SectionHeader(_endModeLabel(l, s)),
            const SizedBox(height: 8),
            _buildEndModeSegment(l, s, theme),
            const SizedBox(height: 16),

            // --- Длительности фаз (не для tempoMultiplier) ---
            if (_t.scaling != ScalingMode.tempoMultiplier) ...[
              SectionHeader(l.phasesSection),
              const SizedBox(height: 4),
              _buildPhasesSection(l, s, theme),
              const SizedBox(height: 8),
            ],

            // --- Темп (только tempoMultiplier) ---
            if (_t.scaling == ScalingMode.tempoMultiplier &&
                _t.tempoOptions != null) ...[
              SectionHeader(l.tempoLabel),
              const SizedBox(height: 8),
              _buildTempoSection(l, s, theme),
              const SizedBox(height: 8),
            ],

            // --- Фразы фикра (№10): аффирмации / вазифы ---
            if (_t.id == 'fikr') ...[
              SectionHeader(l.fikrPhrasesLabel),
              const SizedBox(height: 4),
              _buildFikrPhraseSection(l, s, theme),
              const SizedBox(height: 8),
            ],
          ],

          // --- Подготовка ---
          SectionHeader(l.prepLabel),
          const SizedBox(height: 4),
          _buildPrepSection(l, s),
          const SizedBox(height: 8),

          // --- Сопровождение ---
          // Коучмарк над секцией: показывается один раз
          CoachMark(
            id: 'setup.feedback',
            message: l.coachSetupFeedback,
          ),
          SectionHeader(l.feedbackSection),
          _buildFeedbackSection(l, s),
          const SizedBox(height: 16),
        ],
        ),
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
      unawaited(FeedbackChannelsStore().save(updated));
    }

    return Column(
      children: [
        // Голос (П8, 2026-07-18): подсказки фаз словами — аддитивный слой
        // поверх выбранного звука; работает и при выключенном «Звуке».
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

  /// Выбор пары фраз фикра: плоский список аффирмаций + «своя фраза»,
  /// отмеченная пара — галочка.
  Widget _buildFikrPhraseSection(
      AppLocalizations l, TechniqueSettings s, ThemeData theme) {
    final selected = s.phraseId ?? defaultFikrPhrase.id;
    final children = <Widget>[];

    // Каталожные аффирмации
    for (final p in fikrPhrases) {
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

    // «Своя фраза» — открывает диалог ввода.
    children.add(_CustomPhraseTile(
      l: l,
      theme: theme,
      isSelected: selected == customFikrPhraseId,
      onSelect: (phraseId) =>
          setState(() => _settings = s.copyWith(phraseId: phraseId)),
    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

/// Плитка «Своя фраза» — хранит сохранённые тексты и открывает диалог ввода.
class _CustomPhraseTile extends StatefulWidget {
  final AppLocalizations l;
  final ThemeData theme;
  final bool isSelected;
  final void Function(String phraseId) onSelect;

  const _CustomPhraseTile({
    required this.l,
    required this.theme,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  State<_CustomPhraseTile> createState() => _CustomPhraseTileState();
}

class _CustomPhraseTileState extends State<_CustomPhraseTile> {
  ({String inhale, String exhale})? _saved;

  @override
  void initState() {
    super.initState();
    CustomFikrPhraseStore().load().then((v) {
      if (mounted) setState(() => _saved = v);
    });
  }

  Future<void> _showDialog() async {
    final inCtrl = TextEditingController(text: _saved?.inhale ?? '');
    final exCtrl = TextEditingController(text: _saved?.exhale ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: inCtrl,
              decoration:
                  InputDecoration(labelText: widget.l.fikrCustomInLabel),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: exCtrl,
              decoration:
                  InputDecoration(labelText: widget.l.fikrCustomExLabel),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(widget.l.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(widget.l.commonSave),
          ),
        ],
      ),
    );
    if (result != true) return;
    final trimIn = inCtrl.text.trim();
    final trimEx = exCtrl.text.trim();
    // Пустые обе строки — не выбираем custom.
    if (trimIn.isEmpty && trimEx.isEmpty) return;
    await CustomFikrPhraseStore().save(trimIn, trimEx);
    if (mounted) {
      setState(() => _saved = (inhale: trimIn, exhale: trimEx));
      widget.onSelect(customFikrPhraseId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = _saved;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      selected: widget.isSelected,
      title: Text(widget.l.fikrCustomLabel),
      subtitle: saved != null
          ? Text('${saved.inhale} · ${saved.exhale}')
          : Text(widget.l.fikrCustomHint),
      trailing: widget.isSelected
          ? BreathinIcon(
              BreathinIcons.circleCheck,
              size: 20,
              color: widget.theme.colorScheme.primary,
            )
          : null,
      onTap: _showDialog,
    );
  }
}

