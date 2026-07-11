import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vibration/vibration.dart';

import '../../data/session_log_repository.dart';
import '../../domain/engine/phase_engine.dart';
import '../../domain/engine/session_plan.dart';
import '../../domain/models/feedback_channels.dart';
import '../../domain/models/session_record.dart';
import '../../domain/models/technique.dart';
import '../../services/audio/audio_bootstrap.dart';
import '../../services/audio/session_audio_builder.dart';
import '../../services/audio/sound_bank_loader.dart';
import '../../services/haptics/vibration_pattern.dart';
import 'breathing_painter.dart';
import 'session_view.dart';

/// Прогон сессии. Два режима часов (ПЛАН §3.3):
///
/// * **Аудио-режим** (звук и/или метроном включены, аудио-подсистема
///   доступна): сессия рендерится в единый WAV и играет через
///   audio_service/just_audio — часы движка = позиция плеера, дрейф фаз
///   нулевой по построению, звук живёт при выключенном экране.
/// * **Визуальный режим** (аудио-каналы выключены или платформа без
///   плагинов — тесты): Ticker + Stopwatch, точность достаточна для
///   визуала.
///
/// Вибрация в обоих режимах диспетчеризуется по окну событий от текущих
/// часов (допуск ±100 мс не различим тактильно — ПЛАН §3.3 п.4).
/// По завершении (или прерыванию с ≥1 полным циклом) пишется
/// [SessionRecord] (ТЗ §5, П11).
class SessionRunner extends StatefulWidget {
  final SessionPlan plan;
  final Technique technique;
  final FeedbackChannels feedback;
  final SessionLogRepository? log;

  const SessionRunner({
    super.key,
    required this.plan,
    required this.technique,
    this.feedback = const FeedbackChannels(),
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

  /// Аудио-режим активен (плеер загружен и запущен).
  bool _audioMode = false;
  bool _canVibrate = false;

  @override
  void initState() {
    super.initState();
    _engine = PhaseEngine(widget.plan);
    _state = _engine.stateAt(0);
    _ticker = createTicker(_onTick);
    _start();
  }

  Future<void> _start() async {
    if (widget.feedback.vibration) {
      try {
        _canVibrate = await Vibration.hasVibrator();
      } catch (_) {
        _canVibrate = false; // тесты/платформа без плагина
      }
    }

    final handler = sessionAudioHandler;
    if (handler != null &&
        (widget.feedback.sound || widget.feedback.metronome)) {
      try {
        final bank = await loadMinimalSoundBank();
        final wav = buildSessionWav(widget.plan, bank, widget.feedback);
        if (wav != null) {
          final dir = await getTemporaryDirectory();
          final file = File(
              '${dir.path}/session_${_startedAt.millisecondsSinceEpoch}.wav');
          await file.writeAsBytes(wav, flush: true);
          await handler.loadSessionFile(
            file.path,
            title: 'Дыхательная сессия',
            duration: Duration(milliseconds: widget.plan.totalDurationMs),
          );
          await handler.play();
          _audioMode = true;
        }
      } catch (_) {
        _audioMode = false; // не поднялось аудио — честный визуал-режим
      }
    }

    if (!mounted) return;
    if (!_audioMode) _clock.start();
    _ticker.start();
  }

  /// Позиция сессии: аудио-режим — позиция плеера (мастер-часы),
  /// иначе Stopwatch.
  int _positionMs() => _audioMode
      ? sessionAudioHandler!.player.position.inMilliseconds
      : _clock.elapsedMilliseconds;

  void _onTick(Duration _) {
    final pos = _positionMs();

    // Вибро-канал: события, чей t попал в окно с прошлого тика.
    if (_canVibrate && pos > _lastMs) {
      for (final e in _engine.eventsInWindow(_lastMs, pos)) {
        final pattern = switch (e.type) {
          EngineEventType.phaseStart => VibrationPattern.forPhase(e.phase!),
          EngineEventType.prepCountdown => VibrationPattern.prepTick,
          EngineEventType.gong => VibrationPattern.sessionEnd,
          _ => null,
        };
        if (pattern != null) {
          Vibration.vibrate(pattern: pattern).ignore();
        }
      }
    }
    _lastMs = pos;

    final s = _engine.stateAt(pos);
    // Энергосбережение: перестраиваем экран только когда меняется видимое.
    final sig = visualSignature(s, widget.technique.visual);
    if (sig != _signature) {
      _signature = sig;
      if (mounted) setState(() => _state = s);
    }
    if (s.isFinished) {
      _stopClocks();
      _record(completed: true, cycles: widget.plan.totalCycles);
    }
  }

  void _stopClocks() {
    _ticker.stop();
    _clock.stop();
    if (_audioMode) {
      _audioMode = false;
      sessionAudioHandler?.stop().ignore();
    }
  }

  /// Пишет запись истории один раз за жизнь экрана. Прерванная сессия
  /// сохраняется, только если завершён хотя бы один цикл.
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
          : _lastMs ~/ 1000,
      cyclesCompleted: cycles,
      completed: completed,
    );
    // fire-and-forget: экран не ждёт диска.
    (widget.log ?? SessionLogRepository()).add(record);
  }

  void _pauseStop() {
    final wasFinished = _state.isFinished;
    _stopClocks();
    if (!wasFinished) {
      // cycleIndex — текущий (0-based) ⇒ полных завершённых циклов ровно он.
      _record(completed: false, cycles: _state.cycleIndex.clamp(0, 1 << 30));
    }
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    if (_audioMode) sessionAudioHandler?.stop().ignore();
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
