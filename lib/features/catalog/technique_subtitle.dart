import '../../domain/models/technique.dart';
import '../../l10n/generated/app_localizations.dart';

/// Формирует короткую подпись-паттерн для карточки и сетки главного экрана.
///
/// * counted → паттерн фаз через дефис + « · » + [AppLocalizations.cyclesShort].
///   Секунды форматируются без локале-зависимостей: целые — без «.0»,
///   дробные — как есть (5.5 → «5.5»).
/// * timer   → [AppLocalizations.minutesShort].
/// * wimHof  → [AppLocalizations.roundsShort].
String techniqueSubtitle(AppLocalizations l, Technique t) {
  switch (t.type) {
    case TechniqueType.counted:
      final phases = t.defaultPhases;
      if (phases == null || phases.isEmpty) return '';
      final pattern = phases.map((p) => _formatSec(p.defaultSec)).join('-');
      return '$pattern · ${l.cyclesShort(t.defaultCycles)}';

    case TechniqueType.timer:
      return l.minutesShort(t.defaultTimerMin ?? 5);

    case TechniqueType.wimHof:
      final rounds = t.wimHof?.rounds ?? 3;
      return l.roundsShort(rounds);

    case TechniqueType.scripted:
      // Вытягивающее: вдох фиксирован, выдох растёт и убывает — «4 · 4→28→4».
      final script = t.cycleScript;
      if (script == null || script.isEmpty) return '';
      final inhale = script.first
          .firstWhere((p) => p.kind == PhaseKind.inhale,
              orElse: () => script.first.first)
          .defaultSec;
      var lo = double.infinity;
      var hi = double.negativeInfinity;
      for (final cycle in script) {
        for (final p in cycle) {
          if (p.kind != PhaseKind.exhale) continue;
          if (p.defaultSec < lo) lo = p.defaultSec;
          if (p.defaultSec > hi) hi = p.defaultSec;
        }
      }
      if (hi < lo) return _formatSec(inhale);
      return '${_formatSec(inhale)} · '
          '${_formatSec(lo)}→${_formatSec(hi)}→${_formatSec(lo)}';
  }
}

/// Форматирует секунды без локале-зависимостей.
/// 4.0 → «4», 5.5 → «5.5».
String _formatSec(double sec) {
  if (sec == sec.truncateToDouble()) {
    return sec.toInt().toString();
  }
  return sec.toString();
}
