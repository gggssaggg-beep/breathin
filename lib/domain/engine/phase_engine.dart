import '../models/technique.dart';
import 'session_plan.dart';

/// Стадия сессии в конкретный момент.
enum SessionStage { prep, breathing, finished }

/// Полное состояние сессии в момент времени — производная от позиции
/// воспроизведения (ПЛАН §3.3, п.4: `player.position` — единственные часы).
class SessionState {
  final SessionStage stage;
  final PhaseKind? phase; // null во время подготовки и по завершении
  final int cycleIndex; // 0-based; -1 во время подготовки
  final int totalCycles;
  final int phaseElapsedMs;
  final int phaseDurationMs;
  final int prepRemainingMs; // > 0 только на стадии prep
  final int sessionElapsedMs;
  final int sessionDurationMs;
  /// Порядковый номер фазы внутри текущего цикла (0-based).
  /// -1 во время подготовки и по завершении.
  final int phaseIndexInCycle;

  const SessionState({
    required this.stage,
    required this.phase,
    required this.cycleIndex,
    required this.totalCycles,
    required this.phaseElapsedMs,
    required this.phaseDurationMs,
    required this.prepRemainingMs,
    required this.sessionElapsedMs,
    required this.sessionDurationMs,
    this.phaseIndexInCycle = -1,
  });

  /// Прогресс текущей фазы 0..1 (для анимации фигуры дыхания).
  double get phaseProgress =>
      phaseDurationMs <= 0 ? 0 : (phaseElapsedMs / phaseDurationMs).clamp(0, 1);

  /// Целые секунды, оставшиеся до конца фазы (для крупного отсчёта на экране).
  int get phaseRemainingSec =>
      ((phaseDurationMs - phaseElapsedMs) / 1000).ceil().clamp(0, 1 << 30);

  bool get isFinished => stage == SessionStage.finished;
}

class _Segment {
  final int startMs;
  final int endMs;
  final PhaseKind phase;
  final int cycleIndex;
  /// Индекс фазы внутри цикла (0-based).
  final int phaseIndexInCycle;
  const _Segment(
      this.startMs, this.endMs, this.phase, this.cycleIndex, this.phaseIndexInCycle);
}

/// Диспетчер сессии: чистая проекция позиции воспроизведения в [SessionState]
/// и в события окна. Не владеет плеером и таймерами — их подаёт слой сервисов
/// (ПЛАН §3.3). Тестируется прогоном произвольных позиций.
class PhaseEngine {
  final SessionPlan plan;
  final List<_Segment> _segments;
  final int _firstPhaseStartMs;

  PhaseEngine(this.plan)
      : _segments = _buildSegments(plan),
        _firstPhaseStartMs = _firstStart(plan);

  static int _firstStart(SessionPlan plan) {
    final starts = plan.phaseStarts.toList();
    return starts.isEmpty ? 0 : starts.first.tMs;
  }

  static List<_Segment> _buildSegments(SessionPlan plan) {
    final starts = plan.phaseStarts.toList()
      ..sort((a, b) => a.tMs.compareTo(b.tMs));
    final segs = <_Segment>[];
    // Считаем phaseIndexInCycle: внутри каждого цикла — порядковый номер фазы.
    // Для этого считаем, сколько phaseStart-событий предшествует текущему
    // в том же цикле.
    final phasesPerCycle = <int, int>{}; // cycleIndex → счётчик
    for (var i = 0; i < starts.length; i++) {
      final end =
          i + 1 < starts.length ? starts[i + 1].tMs : plan.totalDurationMs;
      final ci = starts[i].cycleIndex!;
      final phaseIdx = phasesPerCycle[ci] ?? 0;
      phasesPerCycle[ci] = phaseIdx + 1;
      segs.add(_Segment(starts[i].tMs, end, starts[i].phase!, ci, phaseIdx));
    }
    return segs;
  }

  /// Состояние сессии в позиции [posMs] (клампится к [0, длительность]).
  SessionState stateAt(int posMs) {
    final pos = posMs < 0 ? 0 : posMs;
    final dur = plan.totalDurationMs;

    if (pos >= dur) {
      return SessionState(
        stage: SessionStage.finished,
        phase: null,
        cycleIndex: -1,
        totalCycles: plan.totalCycles,
        phaseElapsedMs: 0,
        phaseDurationMs: 0,
        prepRemainingMs: 0,
        sessionElapsedMs: dur,
        sessionDurationMs: dur,
        phaseIndexInCycle: -1,
      );
    }

    if (pos < _firstPhaseStartMs) {
      return SessionState(
        stage: SessionStage.prep,
        phase: null,
        cycleIndex: -1,
        totalCycles: plan.totalCycles,
        phaseElapsedMs: 0,
        phaseDurationMs: 0,
        prepRemainingMs: _firstPhaseStartMs - pos,
        sessionElapsedMs: pos,
        sessionDurationMs: dur,
        phaseIndexInCycle: -1,
      );
    }

    // Сегмент, содержащий позицию: последний с startMs <= pos.
    var idx = 0;
    for (var i = 0; i < _segments.length; i++) {
      if (_segments[i].startMs <= pos) {
        idx = i;
      } else {
        break;
      }
    }
    final seg = _segments[idx];
    return SessionState(
      stage: SessionStage.breathing,
      phase: seg.phase,
      cycleIndex: seg.cycleIndex,
      totalCycles: plan.totalCycles,
      phaseElapsedMs: pos - seg.startMs,
      phaseDurationMs: seg.endMs - seg.startMs,
      prepRemainingMs: 0,
      sessionElapsedMs: pos,
      sessionDurationMs: dur,
      phaseIndexInCycle: seg.phaseIndexInCycle,
    );
  }

  /// События, чей момент попал в окно (fromMs, toMs] — для диспетчеризации
  /// вибрации и визуальных подсказок look-ahead-циклом (ПЛАН §3.3, п.4).
  List<EngineEvent> eventsInWindow(int fromMs, int toMs) => plan.events
      .where((e) => e.tMs > fromMs && e.tMs <= toMs)
      .toList(growable: false);
}
