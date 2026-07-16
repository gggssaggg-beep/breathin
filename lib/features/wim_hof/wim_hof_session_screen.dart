import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../app/theme.dart';

import '../../data/challenges_repository.dart';
import '../../data/session_log_repository.dart';
import '../../domain/engine/wim_hof_machine.dart';
import '../../domain/models/session_record.dart';
import '../../domain/models/technique.dart';
import '../../domain/stats/wim_hof_stats.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/audio/sound_bank_loader.dart';
import '../../services/audio/timeline_renderer.dart';
import '../../services/sync/session_sync_service.dart';
import '../../ui/hant/hant_backdrop.dart';
import '../../ui/icons/breathin_icon.dart';
import '../../ui/icons/breathin_icons.dart';
import '../../ui/widgets/session_finish.dart';

/// Экран сессии Вима Хофа (ПЛАН §3.4): машина раундов [WimHofMachine].
///
/// В отличие от counted-сессий здесь НЕТ пре-рендеренного таймлайна:
/// задержка недетерминирована (тап «хочу вдохнуть»), а экран у ВХ всегда
/// включён — точность one-shot клипов (десятки мс) достаточна. Звуки —
/// вдох/выдох выбранного набора через пару предзагруженных плееров,
/// гонг — на финише; всё аудио опционально (без плагина — тишина).
class WimHofSessionScreen extends StatefulWidget {
  final Technique technique;
  final WimHofConfig config;
  final SessionLogRepository? log;

  const WimHofSessionScreen({
    super.key,
    required this.technique,
    required this.config,
    this.log,
  });

  @override
  State<WimHofSessionScreen> createState() => _WimHofSessionScreenState();
}

class _WimHofSessionScreenState extends State<WimHofSessionScreen>
    with SingleTickerProviderStateMixin {
  late final WimHofMachine _machine = WimHofMachine(widget.config);
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;

  // Подпись видимого кадра — перестраиваем экран только при изменении
  // (приём visualSignature из SessionRunner; тикер идёт 60 Гц).
  Object? _signature;

  // Прошлый (stage, round, breathIndex) — для звука/вибро на границах.
  WimHofStage? _prevStage;
  int _prevBreath = -1;

  AudioPlayer? _inhalePlayer;
  AudioPlayer? _exhalePlayer;
  AudioPlayer? _gongPlayer;
  bool _canVibrate = false;
  bool _recorded = false;
  late final DateTime _startedAt = DateTime.now();

  // Рекорды ДО этой сессии (журнал на старте) — для строки сравнения на финише
  // (ПЛАН П19 §2.4). Загружаются один раз; null пока не прочитан журнал.
  int? _prevBestEver;
  int? _prevBestToday;

  @override
  void initState() {
    super.initState();
    try {
      WakelockPlus.enable().ignore();
    } catch (_) {}
    _loadRecords();
    _initAudio();
    _ticker = createTicker(_onTick)..start();
  }

  Future<void> _loadRecords() async {
    try {
      final history = await (widget.log ?? SessionLogRepository()).all();
      if (!mounted) return;
      setState(() {
        _prevBestEver = WimHofStats.bestEver(history);
        _prevBestToday = WimHofStats.bestOnDay(history, _startedAt);
      });
    } catch (_) {}
  }

  Future<void> _initAudio() async {
    try {
      _canVibrate = await Vibration.hasVibrator();
    } catch (_) {}
    try {
      final inhale = AudioPlayer();
      await inhale.setAsset(soundAssetPaths[ClipId.inhale]!);
      final exhale = AudioPlayer();
      await exhale.setAsset(soundAssetPaths[ClipId.exhale]!);
      final gong = AudioPlayer();
      await gong.setAsset(soundAssetPaths[ClipId.gong]!);
      if (!mounted) {
        inhale.dispose();
        exhale.dispose();
        gong.dispose();
        return;
      }
      _inhalePlayer = inhale;
      _exhalePlayer = exhale;
      _gongPlayer = gong;
    } catch (_) {
      // Платформа без плагина (тесты) или сбой декодера — сессия без звука.
    }
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastTick).inMilliseconds;
    _lastTick = elapsed;
    _machine.advance(dt);
    _onBoundaries();
    // Квант: сек задержки/отсчётов, номер дыхания, 1/128 пульса круга.
    final sig = Object.hash(
      _machine.stage,
      _machine.round,
      _machine.breathIndex,
      (_machine.breathProgress * 128).floor(),
      _machine.retentionMs ~/ 1000,
      _machine.prepRemainingSec,
      _machine.recoveryRemainingSec,
    );
    if (sig != _signature) {
      _signature = sig;
      if (mounted) setState(() {});
    }
    if (_machine.isFinished) {
      _ticker.stop();
      _finish();
    }
  }

  /// Звук/вибро на границах: новое дыхание — клип вдоха в начале и выдоха
  /// с середины темпа; смены стадий — вибро-акцент.
  void _onBoundaries() {
    final stage = _machine.stage;
    if (stage == WimHofStage.breathing) {
      final breath = _machine.breathIndex;
      if (breath != _prevBreath || _prevStage != stage) {
        _prevBreath = breath;
        _oneShot(_inhalePlayer);
        _vibrate(30);
      } else if (_machine.breathProgress >= 0.45 &&
          _exhalePlayer != null &&
          _exhalePlayer!.playerState.processingState ==
              ProcessingState.ready &&
          !_exhalePlayer!.playing &&
          _inhalePlayer?.playing != true) {
        // Выдох — один раз на дыхание: когда вдох-клип дозвучал и позиция
        // выдох-плеера в начале (seek(0) делает _oneShot).
        _oneShot(_exhalePlayer);
      }
    }
    if (stage != _prevStage) {
      if (stage == WimHofStage.retention || stage == WimHofStage.recovery) {
        _vibrate(120); // акцент смены стадии — заметен с закрытыми глазами
      }
      _prevStage = stage;
      if (stage != WimHofStage.breathing) _prevBreath = -1;
    }
  }

  void _oneShot(AudioPlayer? p) {
    if (p == null) return;
    try {
      p.seek(Duration.zero);
      p.play().catchError((_) {});
    } catch (_) {}
  }

  void _vibrate(int ms) {
    if (!_canVibrate) return;
    try {
      Vibration.vibrate(duration: ms);
    } catch (_) {}
  }

  void _finish() {
    _oneShot(_gongPlayer);
    _record(completed: true);
  }

  void _stop() {
    _ticker.stop();
    _record(completed: false);
    if (mounted) Navigator.of(context).pop();
  }

  void _record({required bool completed}) {
    if (_recorded) return;
    final rounds = _machine.retentionsSec.length;
    // Прерывание до первой завершённой задержки историю не засоряет.
    if (!completed && rounds < 1) return;
    _recorded = true;
    final record = SessionRecord(
      id: '${_startedAt.millisecondsSinceEpoch}-${identityHashCode(this)}',
      techniqueId: widget.technique.id,
      startedAt: _startedAt,
      durationSec: _machine.totalElapsedMs ~/ 1000,
      cyclesCompleted: rounds,
      completed: completed,
      variant: '${widget.config.breaths}×${widget.config.rounds}',
      retentionsSec: _machine.retentionsSec,
    );
    // fire-and-forget, как в SessionRunner: экран не ждёт ни диска, ни сети;
    // синк без входа/сети — тихий no-op.
    final log = widget.log ?? SessionLogRepository();
    log
        .add(record)
        .then((_) => SessionSyncService().syncNow())
        .then((_) => ChallengesRepository.syncProgressIfSignedIn())
        .catchError((_) {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    try {
      WakelockPlus.disable().ignore();
    } catch (_) {}
    _inhalePlayer?.dispose();
    _exhalePlayer?.dispose();
    _gongPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final m = _machine;
    return Scaffold(
      // В HANT под сессией Вима Хофа — фон-«чертёж» (в классике HantBackdrop прозрачен).
      body: HantBackdrop(
        child: SafeArea(
          child: switch (m.stage) {
            WimHofStage.prep => _CenterPrompt(
                title: l.prepGetReady,
                huge: '${m.prepRemainingSec}',
              ),
            WimHofStage.breathing => _BreathingView(
                l: l,
                machine: m,
                onStop: _stop,
              ),
            WimHofStage.retention => _RetentionView(
                l: l,
                machine: m,
                onTap: () {
                  m.endRetention();
                  _vibrate(60);
                },
              ),
            WimHofStage.recovery => _CenterPrompt(
                title: l.whRecoveryPrompt,
                huge: '${m.recoveryRemainingSec}',
              ),
            WimHofStage.finished => _FinishedView(
                l: l,
                theme: theme,
                retentions: m.retentionsSec,
                prevBestEver: _prevBestEver,
                prevBestToday: _prevBestToday,
                onClose: () {
                  _record(completed: true);
                  Navigator.of(context).pop();
                },
              ),
          },
        ),
      ),
    );
  }
}

// ─── Стадии ───────────────────────────────────────────────────────────────

class _CenterPrompt extends StatelessWidget {
  final String title;
  final String huge;

  const _CenterPrompt({required this.title, required this.huge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Text(
            huge,
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

class _BreathingView extends StatelessWidget {
  final AppLocalizations l;
  final WimHofMachine machine;
  final VoidCallback onStop;

  const _BreathingView({
    required this.l,
    required this.machine,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Пульс круга: вдох — первые 45 % темпа, выдох — остальные 55 %.
    final p = machine.breathProgress;
    final fraction = p < 0.45 ? p / 0.45 : 1.0 - (p - 0.45) / 0.55;
    final size = 140.0 + 90.0 * fraction;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            l.whRoundOf(machine.round, machine.config.rounds),
            style: theme.textTheme.titleMedium,
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 230,
                    height: 230,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 60),
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primaryContainer,
                        ),
                        child: Center(
                          child: Text(
                            '${machine.breathIndex + 1}',
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.whBreathePrompt,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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
    );
  }
}

class _RetentionView extends StatelessWidget {
  final AppLocalizations l;
  final WimHofMachine machine;
  final VoidCallback onTap;

  const _RetentionView({
    required this.l,
    required this.machine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              l.whRoundOf(machine.round, machine.config.rounds),
              style: theme.textTheme.titleMedium,
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l.whExhaleHold, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 24),
                    Text(
                      '${machine.retentionMs ~/ 1000}',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l.whTapWhenUrge,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onTap,
                child: Text(l.whBreatheInStop),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinishedView extends StatelessWidget {
  final AppLocalizations l;
  final ThemeData theme;
  final List<int> retentions;

  /// Рекорды ДО этой сессии (для мотивирующей строки, ПЛАН П19 §2.4).
  final int? prevBestEver;
  final int? prevBestToday;
  final VoidCallback onClose;

  const _FinishedView({
    required this.l,
    required this.theme,
    required this.retentions,
    required this.prevBestEver,
    required this.prevBestToday,
    required this.onClose,
  });

  /// Строка сравнения: «Новый рекорд!» с огоньком, если лучшая задержка этой
  /// сессии побила прежний рекорд (или это первая сессия с данными); иначе —
  /// «Лучшая за сегодня: N с · Рекорд: M с». null — задержек нет вовсе.
  Widget? _recordLine(BuildContext context) {
    if (retentions.isEmpty) return null;
    final currentBest = retentions.reduce((a, b) => a > b ? a : b);
    final isRecord = prevBestEver == null || currentBest > prevBestEver!;
    if (isRecord) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BreathinIcon(BreathinIcons.flame,
              size: 20, color: AppTheme.accentSunColor(context)),
          const SizedBox(width: 8),
          Text(
            l.whNewRecord,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      );
    }
    // Не рекорд ⇒ prevBestEver != null и не меньше текущей лучшей.
    final bestEver = prevBestEver!;
    final bestToday = prevBestToday == null || currentBest > prevBestToday!
        ? currentBest
        : prevBestToday!;
    return Text(
      l.whRecordCompare('$bestToday', '$bestEver'),
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Единый финиш (аудит §3 High): круг-галочка общий, результаты раундов —
    // телом под заголовком.
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SessionFinish(
        title: l.sessionDone,
        tapHint: l.sessionDoneTapHint,
        onClose: onClose,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.whResultsTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < retentions.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l.whRoundShort(i + 1),
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l.secondsShort('${retentions[i]}'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            if (_recordLine(context) case final line?) ...[
              const SizedBox(height: 12),
              line,
            ],
          ],
        ),
      ),
    );
  }
}
