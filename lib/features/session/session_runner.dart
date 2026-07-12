import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:just_audio/just_audio.dart' show ProcessingState;
import 'package:path_provider/path_provider.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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
import '../../services/sync/session_sync_service.dart';
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
///   визуала. Wakelock не даёт экрану погаснуть (ПЛАН §6.5).
///
/// Пауза (ПЛАН §3.3 п.5): player.pause() замораживает единственные часы —
/// все каналы встают согласованно; резюм — seek к началу текущей фазы
/// (фаза целиком, не с полуслова). Вибрация в обоих режимах
/// диспетчеризуется по окну событий от текущих часов (допуск ±100 мс не
/// различим тактильно — ПЛАН §3.3 п.4). По завершении (или прерыванию с
/// ≥1 полным циклом) пишется [SessionRecord] (ТЗ §5, П11).
class SessionRunner extends StatefulWidget {
  final SessionPlan plan;
  final Technique technique;
  final FeedbackChannels feedback;
  final SessionLogRepository? log;

  /// Название в медиа-уведомлении/локскрине — имя техники (ревью М8).
  final String? mediaTitle;

  const SessionRunner({
    super.key,
    required this.plan,
    required this.technique,
    this.feedback = const FeedbackChannels(),
    this.log,
    this.mediaTitle,
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

  /// Нижняя граница окна вибро-событий; -1, чтобы событие t=0 (первый бип
  /// подготовки) попало в первое окно (ревью М1).
  int _lastMs = -1;

  /// Смещение визуальных часов: Stopwatch не умеет seek, поэтому позиция =
  /// база + elapsed; резюм после паузы переставляет базу на начало фазы.
  int _visualBaseMs = 0;

  /// WAV текущей сессии: фиксированное имя + удаление в dispose —
  /// кэш не растёт с каждой сессией (ревью К3).
  File? _sessionWav;

  late SessionState _state;
  Object? _signature;
  bool _recorded = false;
  bool _paused = false;

  /// Экран закрывается (кнопка «Стоп», локскрин-стоп) — защита от двойного
  /// pop: наш же handler.stop() приводит плеер в idle.
  bool _closing = false;

  /// Аудио-режим активен (плеер загружен и запущен).
  bool _audioMode = false;
  bool _canVibrate = false;
  StreamSubscription<ProcessingState>? _playerSub;

  @override
  void initState() {
    super.initState();
    _engine = PhaseEngine(widget.plan);
    _state = _engine.stateAt(0);
    _ticker = createTicker(_onTick);
    // Экран сессии не гаснет (ПЛАН §6.5, ревью С3): в аудио-режиме жизнь при
    // погасшем экране даёт foreground-сервис, wakelock нужен визуал-режиму.
    try {
      WakelockPlus.enable().ignore();
    } catch (_) {
      // Платформа без плагина (тесты).
    }
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
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/session_current.wav');
        final written = await writeSessionWavFile(
          widget.plan,
          bank,
          widget.feedback,
          file,
        );
        if (written) {
          _sessionWav = file;
          await handler.loadSessionFile(
            file.path,
            title: widget.mediaTitle ?? 'Дыхательная сессия',
            duration: Duration(milliseconds: widget.plan.totalDurationMs),
          );
          await handler.play();
          _audioMode = true;
          // Жизненный цикл плеера: completed — гонг дозвучал (гасим
          // сервис), idle — «Стоп» с локскрина (ревью С1, М3).
          _playerSub = handler.player.processingStateStream
              .listen(_onProcessingState);
        }
      } catch (_) {
        _audioMode = false; // не поднялось аудио — честный визуал-режим
      }
    }

    if (!mounted) return;
    if (!_audioMode) _clock.start();
    _ticker.start();
  }

  void _onProcessingState(ProcessingState ps) {
    if (!mounted) return;
    if (ps == ProcessingState.completed) {
      // Хвост гонга дозвучал до конца файла — теперь можно гасить
      // foreground-сервис (уведомление уходит). Экран остаётся: финиш
      // закрывается тапом по галочке (влад. §14).
      _audioMode = false;
      sessionAudioHandler?.stop().ignore();
    } else if (ps == ProcessingState.idle) {
      // «Стоп» на локскрине/уведомлении (ревью М3): закрываем экран так же,
      // как кнопкой. _closing отсекает idle от нашего собственного stop().
      if (_closing || _state.isFinished) return;
      _stop();
    }
  }

  /// Позиция сессии: аудио-режим — позиция плеера (мастер-часы),
  /// иначе смещённый Stopwatch.
  int _positionMs() => _audioMode
      ? sessionAudioHandler!.player.position.inMilliseconds
      : _visualBaseMs + _clock.elapsedMilliseconds;

  void _onTick(Duration _) {
    final pos = _positionMs();

    // Прерывание (звонок, пауза с локскрина): плеер встал сам — отражаем в
    // UI; и наоборот, play с уведомления снимает паузу (система продолжает
    // с места остановки, без seek к началу фазы).
    if (_audioMode && !_state.isFinished) {
      final playing = sessionAudioHandler!.player.playing;
      if (!playing && !_paused) {
        setState(() => _paused = true);
      } else if (playing && _paused) {
        setState(() => _paused = false);
      }
    }

    // Вибро-канал: события, чей t попал в окно с прошлого тика. Окно шире
    // 2 с — тикер молчал (возврат из фона в визуальном режиме): пропускаем,
    // чтобы не выстрелить залпом все накопившиеся паттерны (ревью М2).
    if (_canVibrate && pos > _lastMs && pos - _lastMs <= 2000) {
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
      // Тикер и часы стоп; плеер НЕ трогаем — хвост гонга дозвучит, сервис
      // погасит _onProcessingState по completed (ревью С1).
      _ticker.stop();
      _clock.stop();
      _record(completed: true, cycles: widget.plan.totalCycles);
    }
  }

  Future<void> _togglePause() async {
    if (_state.isFinished || _closing) return;
    final handler = sessionAudioHandler;
    if (!_paused) {
      if (_audioMode && handler != null) {
        await handler.pause();
      } else {
        _clock.stop();
      }
      if (mounted) setState(() => _paused = true);
    } else {
      // Резюм с начала текущей фазы (ПЛАН §3.3 п.5): фаза целиком, не с
      // полуслова. Вибро прошедших событий не переигрываем (_lastMs = цель);
      // звуковой сигнал фазы повторится из файла — это и есть подсказка.
      final target =
          (_positionMs() - _state.phaseElapsedMs).clamp(0, 1 << 62);
      _lastMs = target;
      if (_audioMode && handler != null) {
        await handler.seek(Duration(milliseconds: target));
        await handler.play();
      } else {
        _visualBaseMs = target;
        _clock
          ..reset()
          ..start();
      }
      if (mounted) setState(() => _paused = false);
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
    // fire-and-forget: экран не ждёт ни диска, ни сети. Синк подхватывает
    // свежую запись сразу (ревью С8); без входа/сети он тихий no-op.
    final repo = widget.log ?? SessionLogRepository();
    unawaited(repo.add(record).then((_) => SessionSyncService().syncNow()));
  }

  /// «Стоп» кнопкой или с локскрина; на финише — тап по галочке.
  void _stop() {
    if (_closing) return;
    _closing = true;
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
    _playerSub?.cancel();
    if (_audioMode) sessionAudioHandler?.stop().ignore();
    // Файл сессии больше не нужен (плеер остановлен строкой выше).
    _sessionWav?.delete().then((_) {}, onError: (_) {});
    _sessionWav = null;
    try {
      WakelockPlus.disable().ignore();
    } catch (_) {}
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SessionView(
        state: _state,
        shape: widget.technique.visual,
        paused: _paused,
        onPauseResume: _togglePause,
        onStop: _stop,
      );
}
