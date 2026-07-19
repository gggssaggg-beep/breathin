import 'package:flutter/material.dart';

import '../../data/custom_fikr_store.dart';
import '../../data/feedback_channels_store.dart';
import '../../data/technique_settings_repository.dart';
import '../../data/timer_settings_store.dart';
import '../../domain/catalog/fikr_phrases.dart';
import '../../domain/engine/session_plan_compiler.dart';
import '../../domain/engine/timer_session.dart';
import '../../domain/models/session_record.dart';
import '../../domain/models/technique.dart';
import '../../domain/models/technique_settings.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../l10n/technique_texts.dart';
import '../session/session_runner.dart';
import '../timer_session/timer_session_screen.dart';
import '../wim_hof/wim_hof_setup_screen.dart';

/// Тексты фразы фикра для сессии: своя фраза из стора, иначе — по id из
/// каталога (fallback к дефолтной, если своя не задана). Общая для setup и
/// быстрого старта (У1) — резолвится ДО push, чтобы view не зависел от
/// локализации внутри.
Future<({String inhale, String exhale})?> resolveFikrPhrase(
  AppLocalizations l,
  Technique t,
  TechniqueSettings s,
) async {
  if (t.id != 'fikr') return null;
  if (s.phraseId == customFikrPhraseId) {
    final custom = await CustomFikrPhraseStore().load();
    if (custom != null) return custom;
    final p = defaultFikrPhrase;
    return (inhale: l.fikrPhraseIn(p), exhale: l.fikrPhraseEx(p));
  }
  final p = fikrPhraseById(s.phraseId);
  return (inhale: l.fikrPhraseIn(p), exhale: l.fikrPhraseEx(p));
}

/// Быстрый старт (У1, system review 2026-07-16): экран сессии техники [t]
/// с последними сохранёнными настройками — минуя карточку и setup.
///
/// Показывается для последней ПРАКТИКОВАННОЙ техники, а старт сессии всегда
/// сохраняет настройки — поэтому обычно настройки уже на месте; если их нет
/// (стёртые данные) — честная классика техники.
///
/// Вим Хоф — исключение: safety-гейт (ТЗ §2.4) подтверждается при КАЖДОМ
/// запуске, поэтому быстрый старт ведёт на его setup, а не в сессию.
Future<Widget?> quickStartScreen(AppLocalizations l, Technique t) async {
  switch (t.type) {
    case TechniqueType.wimHof:
      return WimHofSetupScreen(technique: t);
    case TechniqueType.timer:
      final s = await TimerSettingsStore().load(t);
      return TimerSessionScreen(
        technique: t,
        config: TimerSessionConfig(
          minutes: s.minutes,
          prepSeconds: s.prepSeconds,
          cueIntervalSec: s.cueIntervalSec,
        ),
        sound: s.sound,
        vibration: s.vibration,
      );
    case TechniqueType.counted:
    case TechniqueType.scripted:
      final loaded = await TechniqueSettingsRepository().loadSaved(t) ??
          TechniqueSettings.classic(t);
      // Глобальные каналы сопровождения (фидбек владельца 2026-07-19 №2).
      final globalFeedback = await FeedbackChannelsStore().load();
      final s = loaded.copyWith(feedback: globalFeedback);
      final plan = t.type == TechniqueType.scripted
          ? const SessionPlanCompiler().compileScript(
              t.cycleScript!,
              prepSeconds: s.prepSeconds,
              metronome: s.feedback.metronome,
            )
          : const SessionPlanCompiler().compile(
              t,
              s.toSessionConfig(t),
              metronome: s.feedback.metronome,
            );
      final phraseTexts = await resolveFikrPhrase(l, t, s);
      return SessionRunner(
        plan: plan,
        technique: t,
        feedback: s.feedback,
        mediaTitle: l.techniqueName(t),
        variant: t.type == TechniqueType.scripted
            ? null
            : variantOf(s.toSessionConfig(t).phaseSeconds),
        phraseTexts: phraseTexts,
      );
  }
}
