/// Домен таймер-режима: свободное дыхание заданной длительности без счёта
/// фаз (ПЛАН §10). Чистый Dart без Flutter — тестируется юнитами; экран лишь
/// двигает время через [TimerSessionMachine.advance] и рисует стадии.
///
/// В отличие от counted-сессий здесь НЕТ пре-рендеренного таймлайна: фоновый
/// трек-луп держит foreground-сервис, а подсказки смены ноздри — one-shot'ы
/// по Dart-часам (погрешность десятков мс несущественна — счёт идёт секундами).
library;

/// Подсказка ноздри для Нади Шодханы. Классически начинают с ЛЕВОЙ.
enum TimerCue { left, right }

/// Событие подсказки на абсолютной оси практики (мс от её начала).
class TimerCueEvent {
  final int tMs;
  final TimerCue cue;
  const TimerCueEvent(this.tMs, this.cue);
}

/// Параметры таймер-сессии (из setup; клэмп диапазонов техники — задача
/// стора/UI, не домена).
class TimerSessionConfig {
  /// Длительность практики, минуты.
  final int minutes;

  /// Подготовка перед практикой, секунды (0..5, как у counted).
  final int prepSeconds;

  /// Интервал подсказок смены ноздри, секунды. 0 = подсказки выключены
  /// (все техники кроме Нади Шодханы).
  final int cueIntervalSec;

  const TimerSessionConfig({
    required this.minutes,
    this.prepSeconds = 3,
    this.cueIntervalSec = 0,
  });

  int get practiceMs => minutes * 60 * 1000;
}

/// Расписание подсказок смены ноздри на всю практику. Первая — в t=0 (начало
/// практики, [TimerCue.left]), далее каждые [TimerSessionConfig.cueIntervalSec],
/// чередуя left/right. Последняя не ставится, если до конца практики остаётся
/// меньше половины интервала (обрубок бессмыслен). Интервал ≤ 0 → пусто.
List<TimerCueEvent> cueSchedule(TimerSessionConfig c) {
  if (c.cueIntervalSec <= 0) return const [];
  final stepMs = c.cueIntervalSec * 1000;
  final end = c.practiceMs;
  final events = <TimerCueEvent>[];
  var t = 0;
  var i = 0;
  while (t <= end - stepMs ~/ 2) {
    events.add(TimerCueEvent(t, i.isEven ? TimerCue.left : TimerCue.right));
    t += stepMs;
    i++;
  }
  return events;
}

enum TimerStage { prep, practice, finished }

/// Машина состояний таймер-сессии. [advance] двигает время, перенося остаток
/// dt через границы стадий (крупные шаги в тестах не теряют время). Подсказки
/// «созревают» по достижении их отметки на оси практики — экран отслеживает
/// рост [cueIndex], чтобы сыграть звук/вибро.
class TimerSessionMachine {
  final TimerSessionConfig config;
  final List<TimerCueEvent> _cues;

  TimerStage _stage;
  int _stageElapsedMs = 0;
  int _practiceElapsedMs = 0;
  int _totalElapsedMs = 0;

  /// Индекс последней достигнутой подсказки (-1 — ни одной).
  int _cueIndex = -1;

  TimerSessionMachine(this.config)
      : _cues = cueSchedule(config),
        _stage =
            config.prepSeconds > 0 ? TimerStage.prep : TimerStage.practice;

  TimerStage get stage => _stage;
  int get totalElapsedMs => _totalElapsedMs;
  bool get isFinished => _stage == TimerStage.finished;

  /// Прошло практики, мс (0 в подготовке).
  int get practiceElapsedMs =>
      _stage == TimerStage.prep ? 0 : _practiceElapsedMs;

  /// Осталось практики, секунды (для крупного таймера).
  int get practiceRemainingSec =>
      ((config.practiceMs - practiceElapsedMs) / 1000).ceil().clamp(0, 1 << 30);

  /// Осталось подготовки, секунды.
  int get prepRemainingSec => _stage == TimerStage.prep
      ? ((config.prepSeconds * 1000 - _stageElapsedMs) / 1000).ceil()
      : 0;

  int get cueIndex => _cueIndex;

  /// Текущая метка ноздри (последняя достигнутая подсказка); null — подсказок
  /// нет или практика не началась.
  TimerCue? get currentCue => _cueIndex >= 0 && _cueIndex < _cues.length
      ? _cues[_cueIndex].cue
      : null;

  /// Двигает время на [dtMs], перенося остаток через границы стадий.
  void advance(int dtMs) {
    if (dtMs <= 0 || _stage == TimerStage.finished) return;
    _totalElapsedMs += dtMs;
    var rest = dtMs;
    while (rest > 0 && _stage != TimerStage.finished) {
      if (_stage == TimerStage.prep) {
        final room = config.prepSeconds * 1000 - _stageElapsedMs;
        if (rest < room) {
          _stageElapsedMs += rest;
          rest = 0;
        } else {
          rest -= room;
          _stageElapsedMs = 0;
          _stage = TimerStage.practice;
          _syncCues(); // первая подсказка (t=0) созревает сразу
        }
      } else {
        // practice
        final room = config.practiceMs - _practiceElapsedMs;
        if (rest < room) {
          _practiceElapsedMs += rest;
          _stageElapsedMs += rest;
          rest = 0;
          _syncCues();
        } else {
          rest -= room;
          _practiceElapsedMs = config.practiceMs;
          _syncCues();
          _stage = TimerStage.finished;
        }
      }
    }
  }

  /// Продвигает [_cueIndex] по всем подсказкам, чья отметка достигнута.
  void _syncCues() {
    while (_cueIndex + 1 < _cues.length &&
        _cues[_cueIndex + 1].tMs <= _practiceElapsedMs) {
      _cueIndex++;
    }
  }
}
