import '../../domain/models/technique.dart';

/// Русские подписи фаз для экрана сессии. Вынесено отдельно, чтобы в партии
/// локализации (RU/EN) заменить на ARB без правки виджета.
String phaseLabelRu(PhaseKind phase) {
  switch (phase) {
    case PhaseKind.inhale:
      return 'Вдох';
    case PhaseKind.holdIn:
    case PhaseKind.holdOut:
      return 'Задержка';
    case PhaseKind.exhale:
      return 'Выдох';
  }
}
