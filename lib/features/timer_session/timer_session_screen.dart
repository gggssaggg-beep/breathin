import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart' show AudioPlayer, ProcessingState;
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../data/challenges_repository.dart';
import '../../data/session_log_repository.dart';
import '../../domain/engine/timer_session.dart';
import '../../domain/models/session_record.dart';
import '../../domain/models/technique.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../l10n/technique_texts.dart';
import '../../services/audio/audio_bootstrap.dart';
import '../../services/audio/sound_bank_loader.dart';
import '../../services/audio/timeline_renderer.dart';
import '../../services/haptics/vibration_pattern.dart';
import '../../services/sync/session_sync_service.dart';
import '../../ui/hant/hant_backdrop.dart';
import '../../ui/widgets/session_finish.dart';
import '../session/tap_pause_hint.dart';

/// Экран таймер-сессии: свободное дыхание заданной длительности (ПЛАН §10).
///
/// Аудио-якорь — фоновый трек-луп через audio_service-handler (foreground-
/// сервис = жизнь при погасшем экране, пауза/стоп с локскрина); подсказки
/// смены ноздри и гонг — one-shot'ы по часам машины. Пре-рендеренного WAV
/// нет: получасовая почти-тишина не стоит 158 МБ, а точность подсказок —
/// секунды, не миллисекунды.
///
/// Часы — [Timer.periodic] с dt по `timer.tick` (число ДОЛЖНЫХ срабатываний):
/// задержанные/пропущенные тики Android досчитываются следующим колбэком, а
/// fake-async тестов двигает их pump'ом. Ticker не годится: без кадров
/// (погасший экран) он молчит; Stopwatch не двигается в fake-async.
///
/// Фигура НЕ дирижирует дыханием: свободный ритм — значит спокойное медленное
/// свечение (AnimationController, период ~8 с), крупно — оставшееся время.
class TimerSessionScreen extends StatefulWidget {
  final Technique technique;
  final TimerSessionConfig config;
  final bool sound;
  final bool vibration;
  final SessionLogRepository? log;

  const TimerSessionScreen({
    super.key,
    required this.technique,
    required this.config,
    required this.sound,
    required this.vibration,
    this.log,
  });

  @override
  State<TimerSessionScreen> createState() => _TimerSessionScreenState();
}

class _TimerSessionScreenState extends State<TimerSessionScreen>
    with SingleTickerProviderStateMixin {
  static const _tick = Duration(milliseconds: 200);

  late final TimerSessionMachine _machine = TimerSessionMachine(widget.config);
  Timer? _timer;
  int _lastTick = 0;

  /// Медленное свечение фигуры (декорация, не часы). Инициализация — в
  /// initState ЯВНО: ленивый late с побочным repeat() создавал бы контроллер
  /// при первом касании в dispose (смерть экрана на prep) — тикер стартует
  /// прямо в dispose и роняет teardown.
  late final AnimationController _glow;

  Object? _signature;
  int _lastCueIndex = -1;
  bool _paused = false;
  bool _closing = false;
  bool _recorded = false;
  bool _canVibrate = false;

  /// Луп загружен в общий handler: стоп обязан его глушить безусловно (Ж1).
  bool _loopLoaded = false;
  StreamSubscription<ProcessingState>? _playerSub;

  AudioPlayer? _cueLeftPlayer;
  AudioPlayer? _cueRightPlayer;
  AudioPlayer? _gongPlayer;

  late final DateTime _startedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    try {
      WakelockPlus.enable().ignore();
    } catch (_) {}
    _initAudio();
    _timer = Timer.periodic(_tick, _onTimer);
  }

  Future<void> _initAudio() async {
    if (widget.vibration) {
      try {
        _canVibrate = await Vibration.hasVibrator();
      } catch (_) {}
    }
    if (!widget.sound) return;

    // Гонг — всегда (финиш должен прозвучать даже если луп не поднялся);
    // подсказки ноздрей — ноты живой арфы: ниже (D4) = левая, выше (C5) =
    // правая. Консистентно со звуком приложения, без новых ассетов.
    try {
      final gong = AudioPlayer();
      await gong.setAsset(soundAssetPaths[ClipId.gong]!);
      if (!mounted) {
        gong.dispose();
        return;
      }
      _gongPlayer = gong;
    } catch (_) {}
    if (widget.config.cueIntervalSec > 0) {
      try {
        final scale = harpScalePaths();
        final left = AudioPlayer();
        await left.setAsset(scale[1]); // D4
        final right = AudioPlayer();
        await right.setAsset(scale[5]); // C5
        if (!mounted) {
          left.dispose();
          right.dispose();
          return;
        }
        _cueLeftPlayer = left;
        _cueRightPlayer = right;
      } catch (_) {}
    }

    // Фоновый луп — якорь foreground-сервиса. Сбой (тесты, платформа без
    // плагина) не валит сессию: часы и так наши, останется чистый визуал.
    final handler = sessionAudioHandler;
    if (handler == null) return;
    try {
      await handler.loadLoopingAsset(
        backgroundLoopAsset,
        title: mounted
            ? AppLocalizations.of(context).techniqueName(widget.technique)
            : '',
        sessionDuration: Duration(
          milliseconds:
              widget.config.prepSeconds * 1000 + widget.config.practiceMs,
        ),
      );
      if (!mounted) {
        handler.stop().ignore();
        return;
      }
      // idle = «Стоп» на локскрине (наш собственный stop отсекает _closing).
      _playerSub =
          handler.player.processingStateStream.listen(_onProcessingState);
      _loopLoaded = true;
      // play() у just_audio завершается только при паузе/стопе — НЕ ждём (Ж1).
      unawaited(handler.play().catchError((_) {}));
    } catch (_) {}
  }

  void _onProcessingState(ProcessingState ps) {
    if (!mounted || _closing || _machine.isFinished) return;
    if (ps == ProcessingState.idle) _stop();
  }

  void _onTimer(Timer t) {
    if (_closing || _machine.isFinished) return;

    // Пауза с локскрина/уведомления — отражаем в UI; play оттуда же — резюм.
    if (_loopLoaded) {
      final playing = sessionAudioHandler?.player.playing ?? false;
      if (!playing && !_paused) {
        _paused = true;
        _glow.stop();
      } else if (playing && _paused) {
        _paused = false;
        _glow.repeat(reverse: true);
      }
    }

    if (_paused) {
      // Время паузы «съедается» без продвижения машины: после резюма
      // накопленные тики (в т.ч. от замороженного процесса) не прыгают.
      _lastTick = t.tick;
    } else {
      final dt = (t.tick - _lastTick) * _tick.inMilliseconds;
      _lastTick = t.tick;
      _machine.advance(dt);
      _onCues();
    }

    final sig = Object.hash(
      _machine.stage,
      _machine.prepRemainingSec,
      _machine.practiceRemainingSec,
      _machine.cueIndex,
      _paused,
    );
    if (sig != _signature) {
      _signature = sig;
      if (mounted) setState(() {});
    }
    if (_machine.isFinished) {
      _timer?.cancel();
      _finish();
    }
  }

  /// Подсказки, созревшие с прошлого тика: играем только ПОСЛЕДНЮЮ (после
  /// долгой заморозки промежуточные устарели — важна текущая ноздря).
  void _onCues() {
    final idx = _machine.cueIndex;
    if (idx == _lastCueIndex) return;
    _lastCueIndex = idx;
    final cue = _machine.currentCue;
    if (cue == null) return;
    switch (cue) {
      case TimerCue.left:
        _oneShot(_cueLeftPlayer);
        _vibrate(VibrationPattern.cueLeft);
      case TimerCue.right:
        _oneShot(_cueRightPlayer);
        _vibrate(VibrationPattern.cueRight);
    }
  }

  void _oneShot(AudioPlayer? p) {
    if (p == null) return;
    try {
      p.seek(Duration.zero);
      p.play().catchError((_) {});
    } catch (_) {}
  }

  void _vibrate(List<int> pattern) {
    if (!_canVibrate) return;
    try {
      Vibration.vibrate(pattern: pattern).ignore();
    } catch (_) {}
  }

  void _finish() {
    _glow.stop(); // финиш-экран статичен — не жжём кадры
    // Луп замолкает (foreground-сервис гаснет), гонг — отдельный плеер,
    // дозвучит поверх финиш-экрана.
    if (_loopLoaded) {
      _loopLoaded = false;
      sessionAudioHandler?.stop().ignore();
    }
    _oneShot(_gongPlayer);
    _vibrate(VibrationPattern.sessionEnd);
    _record(completed: true);
  }

  void _togglePause() {
    if (_machine.isFinished || _closing) return;
    final handler = sessionAudioHandler;
    if (!_paused) {
      if (_loopLoaded && handler != null) handler.pause().ignore();
      _glow.stop();
      setState(() => _paused = true);
    } else {
      if (_loopLoaded && handler != null) {
        unawaited(handler.play().catchError((_) {}));
      }
      _glow.repeat(reverse: true);
      setState(() => _paused = false);
    }
  }

  void _record({required bool completed}) {
    if (_recorded) return;
    // Прерывание раньше минуты практики историю не засоряет.
    if (!completed && _machine.practiceElapsedMs < 60000) return;
    _recorded = true;
    final record = SessionRecord(
      id: '${_startedAt.millisecondsSinceEpoch}-${identityHashCode(this)}',
      techniqueId: widget.technique.id,
      startedAt: _startedAt,
      durationSec: _machine.totalElapsedMs ~/ 1000,
      cyclesCompleted: 0,
      completed: completed,
    );
    // fire-and-forget: экран не ждёт ни диска, ни сети (синк без сети — no-op).
    final log = widget.log ?? SessionLogRepository();
    unawaited(
      log
          .add(record)
          .then((_) => SessionSyncService().syncNow())
          .then((_) => ChallengesRepository.syncProgressIfSignedIn()),
    );
  }

  void _stop() {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    _glow.stop();
    if (_loopLoaded) {
      _loopLoaded = false;
      sessionAudioHandler?.stop().ignore();
    }
    _record(completed: false);
    if (mounted) Navigator.of(context).maybePop();
  }

  void _closeFinished() {
    if (_closing) return;
    _closing = true;
    // Финиш закрывается на каталог (влад. отзыв №2 — не на настройку).
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _playerSub?.cancel();
    if (_loopLoaded) sessionAudioHandler?.stop().ignore();
    _loopLoaded = false;
    _cueLeftPlayer?.dispose();
    _cueRightPlayer?.dispose();
    _gongPlayer?.dispose();
    _glow.dispose();
    try {
      WakelockPlus.disable().ignore();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = _machine;
    return Scaffold(
      // В HANT под таймер-сессией — фон-«чертёж» (в классике HantBackdrop прозрачен).
      body: HantBackdrop(
        child: SafeArea(
          child: switch (m.stage) {
            TimerStage.prep => _PrepView(l: l, seconds: m.prepRemainingSec),
            TimerStage.practice => _PracticeView(
                l: l,
                technique: widget.technique,
                machine: m,
                glow: _glow,
                paused: _paused,
                onPauseResume: _togglePause,
                onStop: _stop,
              ),
            TimerStage.finished => SessionFinish(
                title: l.sessionDone,
                tapHint: l.sessionDoneTapHint,
                onClose: _closeFinished,
              ),
          },
        ),
      ),
    );
  }
}

// ─── Стадии ───────────────────────────────────────────────────────────────

class _PrepView extends StatelessWidget {
  final AppLocalizations l;
  final int seconds;

  const _PrepView({required this.l, required this.seconds});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l.prepGetReady,
              style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Text(
            '$seconds',
            style: theme.textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeView extends StatelessWidget {
  final AppLocalizations l;
  final Technique technique;
  final TimerSessionMachine machine;
  final Animation<double> glow;
  final bool paused;
  final VoidCallback onPauseResume;
  final VoidCallback onStop;

  const _PracticeView({
    required this.l,
    required this.technique,
    required this.machine,
    required this.glow,
    required this.paused,
    required this.onPauseResume,
    required this.onStop,
  });

  String get _remaining {
    final s = machine.practiceRemainingSec;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cue = machine.currentCue;
    // Пауза — тапом по любому месту экрана (влад. 2026-07-16); «Стоп»
    // перехватывает свой тап сам. Подсказки — поверх, без сдвига макета.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPauseResume,
      child: Stack(
        children: [
          Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(l.techniqueName(technique), style: theme.textTheme.titleMedium),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Свечение НЕ задаёт ритм дыхания (свободный ритм — ПЛАН
                  // §10): малая амплитуда, период ~8 с — фигура «живая»,
                  // но не дирижирует.
                  AnimatedBuilder(
                    animation: glow,
                    builder: (context, child) {
                      final f = Curves.easeInOut.transform(glow.value);
                      return Container(
                        width: 200 + 16 * f,
                        height: 200 + 16 * f,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.75 + 0.25 * f),
                        ),
                        child: child,
                      );
                    },
                    child: Center(
                      child: Text(
                        _remaining,
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (cue != null)
                    Text(
                      cue == TimerCue.left
                          ? l.timerLeftNostril
                          : l.timerRightNostril,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: onStop,
              child: Text(l.stopAction),
            ),
          ),
        ],
      ),
          ),
          Positioned(
            top: 56,
            left: 0,
            right: 0,
            child: Center(
              child: paused
                  ? SessionHintPill(text: l.pausedTapHint)
                  : const TapPauseHint(),
            ),
          ),
        ],
      ),
    );
  }
}

