import '../../domain/models/technique.dart';
import '../../l10n/generated/app_localizations.dart';

/// Локализованная подпись фазы для экранов сессии и настройки
/// (в RU обе задержки — «Задержка»: контекст ясен по порядку фаз).
String phaseLabel(AppLocalizations l, PhaseKind phase) {
  switch (phase) {
    case PhaseKind.inhale:
      return l.phaseInhale;
    case PhaseKind.holdIn:
      return l.phaseHoldIn;
    case PhaseKind.holdOut:
      return l.phaseHoldOut;
    case PhaseKind.exhale:
      return l.phaseExhale;
  }
}
