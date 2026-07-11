import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../data/session_log_repository.dart';
import '../../domain/engine/phase_engine.dart';
import '../../domain/engine/session_plan.dart';
import '../../domain/models/session_record.dart';
import '../../domain/models/technique.dart';
import 'breathing_painter.dart';
import 'session_view.dart';

/// Визуальный прогон сессии: гонит [PhaseEngine] от Stopwatch через [Ticker]
/// и отображает [SessionView]. По завершении (или прерыванию с ≥1 полным
/// циклом) пишет [SessionRecord] в локальную историю (ТЗ §5, П11).
///
/// ВАЖНО: это НЕ финальный движок тайминга. Здесь часы — Stopwatch/Ticker,
/// что даёт лишь визуальную демонстрацию. В бою источник времени — позиция
/// аудио-таймлайна (ПЛАН §3.3): Stopwatch заменяется на player.position, а в
/// _onTick подключается диспетчеризация вибрации/звука через eventsInWindow.
class SessionRunner extends StatefulWidget {
  final SessionPlan plan;
  final Technique technique;
  final SessionLogRepository? log;

  const SessionRunner({
    super.key,
    required this.plan,
    required this.technique,
    this.log,
  });

  @override
  State<SessionRunner> createState() => _SessionRunnerState();
}

class _SessionRunnerState extends State<SessionRunner>
    with SingleTickerProviderStateMixin {
  late final PhaseEngine _engine;
  late final Ticker _ticker;
  final Stopwatch _clock = Stopwatch();
  final DateTime _startedAt = DateTime.now();
  int _lastMs = 0;
  late SessionState _state;
  Object? _signature;
  bool _recorded = false;

  // Порог диспетчеризации: включаем реальную рассылку событий на устройстве.
  static const bool _dispatchFeedback = false;

  @override
  void initState() {
    super.initState();
    _engine = PhaseEngine(widget.plan);
    _state = _engine.stateAt(0);
    _ticker = createTicker(_onTick);
    _clock.start();
    _ticker.start();
  }

  void _onTick(Duration _) {
    final pos = _clock.elapsedMilliseconds;
    // В бою здесь идёт диспетчеризация вибро/звука по окну событий; часы при
    // этом — позиция аудио-таймлайна, а не Stopwatch (ПЛАН §3.3).
    if (_dispatchFeedback) {
      for (final _ in _engine.eventsInWindow(_lastMs, pos)) {
        // dispatch(event) — партия аудио-обвязки на устройстве
      }
    }
    _lastMs = pos;
    final s = _engine.stateAt(pos);
    // Энергосбережение: перестраиваем экран только когда меняется видимое
    // (у круга на задержках и на подготовке — ~1 кадр/с вместо 60).
    final sig = visualSignature(s, widget.technique.visual);
    if (sig != _signature) {
      _signature = sig;
      if (mounted) setState(() => _state = s);
    }
    if (s.isFinished) {
      _ticker.stop();
      _clock.stop();
      _record(completed: true, cycles: widget.plan.totalCycles);
    }
  }

  /// Пишет запись истории один раз за жизнь экрана.
  /// Прерванная сессия сохраняется, только если завершён хотя бы один цикл
  /// (иначе это шум — случайные заходы/выходы).
  void _record({required bool completed, required int cycles}) {
    if (_recorded) return;
    if (!completed && cycles < 1) return;
    _recorded = true;
    final record = SessionRecord(
      id: '${_startedAt.millisecondsSinceEpoch}-${identityHashCode(this)}',
      techniqueId: widget.technique.id,
      startedAt: _startedAt,
      durationSec: completed
          ? widget.plan.totalDurationMs ~/ 1000
          : _clock.elapsedMilliseconds ~/ 1000,
      cyclesCompleted: cycles,
      completed: completed,
    );
    // fire-and-forget: экран не ждёт диска.
    (widget.log ?? SessionLogRepository()).add(record);
  }

  void _pauseStop() {
    _ticker.stop();
    _clock.stop();
    if (!_state.isFinished) {
      // cycleIndex — текущий (0-based) ⇒ полных завершённых циклов ровно он.
      _record(completed: false, cycles: _state.cycleIndex.clamp(0, 1 << 30));
    }
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SessionView(
        state: _state,
        shape: widget.technique.visual,
        onPauseStop: _pauseStop,
      );
}
