import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:just_audio/just_audio.dart'
    show AudioPlayer, LoopMode, ProcessingState;
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../data/challenges_repository.dart';
import '../../data/session_log_repository.dart';
import '../../domain/engine/phase_engine.dart';
import '../../l10n/system_l10n.dart';
import '../../domain/engine/session_plan.dart';
import '../../domain/models/feedback_channels.dart';
import '../../domain/models/session_record.dart';
import '../../domain/models/technique.dart';
import '../../services/audio/audio_bootstrap.dart';
import '../../services/audio/sound_bank_loader.dart';
import '../../services/audio/sound_preferences.dart';
import '../../services/audio/timeline_renderer.dart' show VoiceBank;
import '../../services/audio/wav_target/session_wav_target.dart';
import '../../services/haptics/vibration_pattern.dart';
import '../../services/locale/locale_store.dart';
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

  /// Паттерн фаз сессии («4-8-8») для записи истории (влад. §15).
  final String? variant;

  /// Тексты фраз фикра (№10): показываются на экране синхронно фазе;
  /// null — техника без фраз.
  final ({String inhale, String exhale})? phraseTexts;

  const SessionRunner({
    super.key,
    required this.plan,
    required this.technique,
    this.feedback = const FeedbackChannels(),
    this.log,
    this.mediaTitle,
    this.variant,
    this.phraseTexts,
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

  /// Аудио-источник сессии (io — временный файл, web — Blob-URL); cleanup
  /// в dispose освобождает ресурс — кэш/память не растут (ревью К3).
  SessionWavTarget? _wavTarget;

  late SessionState _state;
  Object? _signature;
  bool _recorded = false;
  bool _paused = false;

  /// Экран закрывается (кнопка «Стоп», локскрин-стоп) — защита от двойного
  /// pop: наш же handler.stop() приводит плеер в idle.
  bool _closing = false;

  /// Аудио-режим активен (плеер загружен и запущен).
  bool _audioMode = false;

  /// Файл сессии загружен в плеер: стоп/dispose обязаны глушить его
  /// безусловно (Ж1: раньше стоп смотрел на _audioMode, который при висе
  /// _start не выставлялся — звук жил после выхода с экрана).
  bool _audioLoaded = false;
  bool _canVibrate = false;
  StreamSubscription<ProcessingState>? _playerSub;

  /// Веб (Ж2): опрос передачи мастер-часов плееру после позднего
  /// присоединения аудио к уже идущей сессии (см. [_tryJoinAudio]).
  Timer? _joinTimer;

  /// Фоновый медитативный трек (луп, отдельный слой just_audio): часть
  /// варианта «Арфа». В строгий таймлайн не входит — синхронизация не нужна.
  AudioPlayer? _bgPlayer;

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

    // Веб (Ж2, влад. 2026-07-18 «тормозит и не начинает, пока не потыкаешь»):
    // визуал стартует СРАЗУ на Ticker+Stopwatch, аудио готовится в фоне и
    // присоединяется через [_tryJoinAudio]. Раньше экран молча ждал загрузку
    // банка и рендер WAV (секунды), а сам play() браузер мог заблокировать
    // autoplay-политикой — позиция плеера-мастер-часов стояла на нуле
    // бессрочно; «оживал» экран только от тапов пауза→резюм (реальный жест,
    // который браузер принимал как разрешение на звук).
    if (kIsWeb) {
      _clock.start();
      _ticker.start();
      unawaited(_prepareAudio(joinLive: true));
      return;
    }

    await _prepareAudio(joinLive: false);
    if (!mounted) return;
    if (!_audioMode) _clock.start();
    _ticker.start();
  }

  /// Готовит аудио-путь сессии: банк звука → WAV → загрузка в плеер.
  ///
  /// [joinLive] = false (мобилки): плеер сразу становится мастер-часами и
  /// играет с нуля (прежнее поведение). true (веб): сессия уже идёт на
  /// визуальных часах — готовый файл присоединяется [_tryJoinAudio] с seek
  /// к текущей позиции.
  Future<void> _prepareAudio({required bool joinLive}) async {
    final handler = sessionAudioHandler;
    if (handler == null ||
        (!widget.feedback.sound &&
            !widget.feedback.metronome &&
            !widget.feedback.voice)) {
      return;
    }
    try {
      // Вариант звука — по выбору пользователя (настройки, дефолт «Арфа»).
      final set = await SoundSetStore().load();
      final bank = await loadSoundBank(set);
      // Голос (П8): клипы по языку приложения (выбор в настройках, иначе
      // системный). Сбой загрузки не валит сессию — просто без голоса.
      VoiceBank? voice;
      if (widget.feedback.voice) {
        try {
          final lang = (localeNotifier.value ??
                  PlatformDispatcher.instance.locale)
              .languageCode;
          voice = await loadVoiceBank(lang);
        } catch (_) {}
      }
      // Фон — только у «Арфы» и только при включённом звуке фаз.
      if (set == SoundSet.harp && widget.feedback.sound) {
        unawaited(_startBackground());
      }
      final target = await prepareSessionWav(widget.plan, bank, widget.feedback,
          voice: voice);
      if (target == null) return;
      if (!mounted || _closing) {
        unawaited(target.cleanup());
        return;
      }
      _wavTarget = target;
      await handler.loadSessionFile(
        target.source,
        title: widget.mediaTitle ?? systemL10n().sessionMediaTitle,
        duration: Duration(milliseconds: widget.plan.totalDurationMs),
      );
      // Экран закрыли, пока файл грузился: dispose видел _audioLoaded=false
      // и плеер не глушил — глушим сами, иначе звук переживёт экран.
      if (!mounted || _closing) {
        handler.stop().ignore();
        return;
      }
      // Жизненный цикл плеера: completed — гонг дозвучал (гасим
      // сервис), idle — «Стоп» с локскрина (ревью С1, М3).
      // Подписка и флаги — ДО play.
      _playerSub = handler.player.processingStateStream
          .listen(_onProcessingState);
      _audioLoaded = true;
      if (joinLive) {
        _tryJoinAudio();
      } else {
        _audioMode = true;
        // Ж1 (живой баг v0.3.0): play() у just_audio завершается только
        // при паузе/стопе/конце файла — await здесь вешал _start до конца
        // сессии: тикер не стартовал (визуал мёртв), _audioMode не
        // выставлялся (стоп не глушил звук). Запускаем и НЕ ждём.
        unawaited(handler.play().catchError((_) {}));
      }
    } catch (_) {
      // Не поднялось аудио — честный визуал-режим.
      _audioMode = false;
      _audioLoaded = false;
    }
  }

  /// Веб (Ж2): присоединяет готовый WAV к УЖЕ ИДУЩЕЙ сессии — seek к текущей
  /// позиции визуальных часов, play, и только когда позиция плеера реально
  /// поехала, он забирает роль мастер-часов (расхождение в момент передачи —
  /// доли секунды). Не поехала за ~3 с — браузер заблокировал автозапуск:
  /// сессия остаётся визуальной (тихой), следующий резюм с паузы (реальный
  /// жест) пробует присоединить звук ещё раз.
  ///
  /// ВАЖНО (влад. 2026-07-19): присоединяем СТРОГО к текущей позиции, сессию
  /// НЕ перезапускаем. Прежний «ранний джойн <10 с рестартил с нуля ради
  /// озвучки „Приготовьтесь“» давал видимый глюк «через ~10 с началось
  /// заново». Цена: если WAV дорендерился уже после подготовки (долгие
  /// техники на вебе), аудио-«Приготовьтесь» и первые сигналы не звучат —
  /// но визуальный отсчёт всё равно показан, а рывка назад нет.
  void _tryJoinAudio() {
    final handler = sessionAudioHandler;
    if (handler == null ||
        !_audioLoaded ||
        _audioMode ||
        _closing ||
        _paused) {
      return;
    }
    final target = _positionMs();
    unawaited(() async {
      try {
        await handler.seek(Duration(milliseconds: target));
        unawaited(handler.play().catchError((_) {}));
      } catch (_) {}
    }());
    _joinTimer?.cancel();
    var attempts = 0;
    _joinTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      if (!mounted || _closing || _paused || !_audioLoaded || _audioMode) {
        t.cancel();
        return;
      }
      if (handler.player.position.inMilliseconds > target + 50) {
        t.cancel();
        _clock.stop();
        _audioMode = true;
      } else if (++attempts >= 15) {
        t.cancel(); // автозапуск заблокирован — тихий визуальный режим
      }
    });
  }

  /// Поднимает фоновый луп. Отдельно от основного пути: сбой фона не должен
  /// валить сессию (и наоборот, тесты без плагина — тишина).
  Future<void> _startBackground() async {
    try {
      final p = AudioPlayer();
      await p.setAsset(backgroundLoopAsset);
      await p.setLoopMode(LoopMode.all);
      await p.setVolume(0.45);
      if (!mounted) {
        p.dispose();
        return;
      }
      _bgPlayer = p;
      unawaited(p.play().catchError((_) {}));
    } catch (_) {}
  }

  void _onProcessingState(ProcessingState ps) {
    if (!mounted) return;
    if (ps == ProcessingState.completed) {
      // Хвост гонга дозвучал до конца файла — теперь можно гасить
      // foreground-сервис (уведомление уходит). Экран остаётся: финиш
      // закрывается тапом по галочке (влад. §14).
      _audioMode = false;
      _audioLoaded = false;
      sessionAudioHandler?.stop().ignore();
    } else if (ps == ProcessingState.idle) {
      // «Стоп» на локскрине/уведомлении (ревью М3): закрываем экран так же,
      // как кнопкой. _closing отсекает idle от нашего собственного stop().
      if (_closing || _state.isFinished) return;
      _stop();
    }
  }

  /// Позиция сессии: аудио-режим — позиция плеера (мастер-часы),
  /// иначе Stopwatch (пауза его останавливает, резюм продолжает — позиция
  /// копится с места остановки).
  int _positionMs() => _audioMode
      ? sessionAudioHandler!.player.position.inMilliseconds
      : _clock.elapsedMilliseconds;

  void _onTick(Duration _) {
    final pos = _positionMs();

    // Прерывание (звонок, пауза с локскрина): плеер встал сам — отражаем в
    // UI; и наоборот, play с уведомления снимает паузу (система продолжает
    // с места остановки, без seek к началу фазы). pos > 0 — до фактического
    // старта воспроизведения не мигаем ложной «паузой».
    if (_audioMode && !_state.isFinished && mounted && pos > 0) {
      final playing = sessionAudioHandler!.player.playing;
      if (!playing && !_paused) {
        setState(() => _paused = true);
      } else if (playing && _paused) {
        setState(() => _paused = false);
      }
    }

    // Вибро-канал: события, чей t попал в окно с прошлого тика. На паузе
    // молчим (ревью Р5: между нажатием «Продолжить» и seek позиция ещё
    // старая — без guard'а окно от начала фазы стреляло бы лишний раз).
    // Окно шире 2 с — тикер молчал (возврат из фона в визуальном режиме):
    // пропускаем, чтобы не выстрелить залпом накопившееся (ревью М2).
    if (_canVibrate && !_paused && pos > _lastMs && pos - _lastMs <= 2000) {
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
      try {
        _bgPlayer?.pause();
      } catch (_) {}
      if (_audioMode && handler != null) {
        await handler.pause();
      } else {
        _clock.stop();
        // Веб: звук мог уже играть в ожидании передачи часов ([_tryJoinAudio])
        // — глушим и отменяем передачу; резюм попробует присоединить заново.
        _joinTimer?.cancel();
        if (_audioLoaded && handler != null) {
          try {
            await handler.pause();
          } catch (_) {}
        }
      }
      if (mounted) setState(() => _paused = true);
    } else {
      // Резюм — точно с места паузы (влад. 2026-07-19 №5: «пауза должна
      // ставить на паузу, а не начинать заново»; прежнее правило ПЛАН §3.3
      // п.5 «фаза целиком с начала» отменено). Плеер стоит на позиции
      // паузы — просто продолжаем; Stopwatch копит время сам. Без seek
      // резюм ещё и надёжнее на вебе (seek там мог сорваться в старт файла).
      if (_audioMode && handler != null) {
        // Как и на старте: play() не ждём (Ж1).
        unawaited(handler.play().catchError((_) {}));
      } else {
        _clock.start();
      }
      try {
        _bgPlayer?.play().catchError((_) {});
      } catch (_) {}
      if (mounted) setState(() => _paused = false);
      // Веб: резюм — реальный жест; если звук так и не присоединился
      // (браузер блокировал автозапуск) — самое время попробовать снова.
      if (kIsWeb && !_audioMode && _audioLoaded) _tryJoinAudio();
    }
  }

  void _stopClocks() {
    _ticker.stop();
    _clock.stop();
    _joinTimer?.cancel();
    try {
      _bgPlayer?.stop();
    } catch (_) {}
    // Глушим по _audioLoaded, не по _audioMode: файл в плеере — значит
    // стоп обязан его остановить в любом состоянии (Ж1).
    if (_audioLoaded) {
      _audioLoaded = false;
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
      variant: widget.variant,
    );
    // fire-and-forget: экран не ждёт ни диска, ни сети. Синк подхватывает
    // свежую запись сразу (ревью С8); без входа/сети он тихий no-op.
    final repo = widget.log ?? SessionLogRepository();
    unawaited(
      repo
          .add(record)
          .then((_) => SessionSyncService().syncNow())
          .then((_) => ChallengesRepository.syncProgressIfSignedIn()),
    );
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
    // По завершении тап по галочке возвращает СРАЗУ на главный экран-каталог
    // (отзыв №2: раньше падал на промежуточный экран настройки, приходилось
    // жать «назад» ещё раз). Прерывание до финиша (Стоп/локскрин) — на шаг
    // назад, к настройке той же техники.
    final nav = Navigator.of(context);
    if (wasFinished) {
      nav.popUntil((r) => r.isFirst);
    } else {
      nav.maybePop();
    }
  }

  @override
  void dispose() {
    _joinTimer?.cancel();
    _playerSub?.cancel();
    _bgPlayer?.dispose();
    _bgPlayer = null;
    if (_audioLoaded) sessionAudioHandler?.stop().ignore();
    _audioLoaded = false;
    // Источник сессии больше не нужен (плеер остановлен строкой выше):
    // io — удалить файл, web — отозвать Blob-URL.
    _wavTarget?.cleanup().ignore();
    _wavTarget = null;
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
        segment: widget.technique.segmentForCycle(_state.cycleIndex),
        phraseTexts: widget.phraseTexts,
      );
}
