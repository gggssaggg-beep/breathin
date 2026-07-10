import '../models/technique.dart';

/// Тип события на таймлайне сессии. В срезе №1 — минимальный набор; голосовые
/// подсказки, тики метронома и вибро-события добавляются в следующих партиях
/// (см. ПЛАН §3.3).
enum EngineEventType {
  prepCountdown, // бип обратного отсчёта «3…2…1»
  phaseStart,    // начало фазы цикла
  gong,          // гонг завершения
  sessionEnd,    // логический конец сессии
}

/// Событие на абсолютной временной оси сессии (мс от старта).
///
/// Компилятор располагает события с точностью до миллисекунды; рендерер затем
/// кладёт их на конкретные сэмплы (см. ПЛАН §3.3, п.2).
class EngineEvent {
  final int tMs;
  final EngineEventType type;
  final PhaseKind? phase;    // для phaseStart
  final int? cycleIndex;     // 0-based, для phaseStart
  final int? countdownValue; // для prepCountdown (3, 2, 1)

  const EngineEvent({
    required this.tMs,
    required this.type,
    this.phase,
    this.cycleIndex,
    this.countdownValue,
  });

  @override
  String toString() {
    final extra = [
      if (phase != null) '$phase',
      if (cycleIndex != null) 'cycle $cycleIndex',
      if (countdownValue != null) 'n=$countdownValue',
    ].join(', ');
    return 'EngineEvent($tMs ms, $type${extra.isEmpty ? '' : ', $extra'})';
  }
}

/// Детерминированный план сессии: упорядоченные по времени события, итоговое
/// число циклов и полная длительность (см. ПЛАН §3.3).
class SessionPlan {
  final List<EngineEvent> events;
  final int totalCycles;
  final int totalDurationMs;

  const SessionPlan({
    required this.events,
    required this.totalCycles,
    required this.totalDurationMs,
  });

  Iterable<EngineEvent> get phaseStarts =>
      events.where((e) => e.type == EngineEventType.phaseStart);
}
