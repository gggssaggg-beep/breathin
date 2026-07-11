import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../domain/engine/phase_engine.dart';
import '../../domain/engine/session_plan.dart';
import '../../domain/models/technique.dart';
import 'breathing_painter.dart';
import 'session_view.dart';

/// Визуальный прогон сессии: гонит [PhaseEngine] от Stopwatch через [Ticker]
/// и отображает [SessionView].
///
/// ВАЖНО: это НЕ финальный движок тайминга. Здесь часы — Stopwatch/Ticker,
/// что даёт лишь визуальную демонстрацию. В бою источник времени — позиция
/// аудио-таймлайна (ПЛАН §3.3): Stopwatch заменяется на player.position, а в
/// _onTick подключается диспетчеризация вибрации/звука через eventsInWindow.
class SessionRunner extends StatefulWidget {
  final SessionPlan plan;
  final VisualShape shape;
  const SessionRunner({
    super.key,
    required this.plan,
    this.shape = VisualShape.circle,
  });

  @override
  State<SessionRunner> createState() => _SessionRunnerState();
}

class _SessionRunnerState extends State<SessionRunner>
    with SingleTickerProviderStateMixin {
  late final PhaseEngine _engine;
  late final Ticker _ticker;
  final Stopwatch _clock = Stopwatch();
  int _lastMs = 0;
  late SessionState _state;
  Object? _signature;

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
    final sig = visualSignature(s, widget.shape);
    if (sig != _signature) {
      _signature = sig;
      if (mounted) setState(() => _state = s);
    }
    if (s.isFinished) {
      _ticker.stop();
      _clock.stop();
    }
  }

  void _pauseStop() {
    _ticker.stop();
    _clock.stop();
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SessionView(state: _state, shape: widget.shape, onPauseStop: _pauseStop);
}
