/// Машина раундов метода Вима Хофа (ПЛАН §3.4, ТЗ §2.3).
///
/// Единственная техника с недетерминированной длительностью: задержка «до
/// позыва» завершается тапом пользователя, остальные стадии детерминированы.
/// Чистый Dart без Flutter — тестируется юнитами; экран лишь двигает время
/// через [advance] и рисует [WimHofStage]-стадии.
library;

/// Параметры сессии (диапазоны — WimHofDefaults каталога).
class WimHofConfig {
  final int breaths;
  final double paceSec;
  final int rounds;
  final int recoveryHoldSec;
  final int prepSeconds;

  const WimHofConfig({
    this.breaths = 30,
    this.paceSec = 2.0,
    this.rounds = 3,
    this.recoveryHoldSec = 15,
    this.prepSeconds = 3,
  });

  int get paceMs => (paceSec * 1000).round();
  int get breathingMs => breaths * paceMs;
}

enum WimHofStage { prep, breathing, retention, recovery, finished }

/// Машина состояний. [advance] двигает детерминированные стадии (перенося
/// остаток dt через границы — крупные шаги в тестах не теряют время);
/// задержка копит время до [endRetention] (тап «хочу вдохнуть»).
class WimHofMachine {
  final WimHofConfig config;

  WimHofStage _stage;
  int _round = 1; // 1-based
  int _stageElapsedMs = 0;
  int _totalElapsedMs = 0;
  final List<int> _retentionsSec = [];

  WimHofMachine(this.config)
      : _stage =
            config.prepSeconds > 0 ? WimHofStage.prep : WimHofStage.breathing;

  WimHofStage get stage => _stage;
  int get round => _round;
  int get totalElapsedMs => _totalElapsedMs;

  /// Завершённые задержки по раундам, секунды (для итога и истории).
  List<int> get retentionsSec => List.unmodifiable(_retentionsSec);

  bool get isFinished => _stage == WimHofStage.finished;

  /// Текущее дыхание (0-based) на стадии breathing.
  int get breathIndex => _stage == WimHofStage.breathing
      ? (_stageElapsedMs ~/ config.paceMs).clamp(0, config.breaths - 1)
      : 0;

  /// Прогресс текущего дыхания 0..1 (для пульсации фигуры).
  double get breathProgress => _stage == WimHofStage.breathing
      ? (_stageElapsedMs % config.paceMs) / config.paceMs
      : 0.0;

  /// Набежавшее время текущей задержки, мс.
  int get retentionMs => _stage == WimHofStage.retention ? _stageElapsedMs : 0;

  int get prepRemainingSec => _stage == WimHofStage.prep
      ? ((config.prepSeconds * 1000 - _stageElapsedMs) / 1000).ceil()
      : 0;

  int get recoveryRemainingSec => _stage == WimHofStage.recovery
      ? ((config.recoveryHoldSec * 1000 - _stageElapsedMs) / 1000).ceil()
      : 0;

  /// Двигает время на [dtMs]. Детерминированные стадии переходят по
  /// достижении длительности; retention ждёт [endRetention] бесконечно.
  void advance(int dtMs) {
    if (dtMs <= 0 || _stage == WimHofStage.finished) return;
    _totalElapsedMs += dtMs;
    var rest = dtMs;
    while (rest > 0) {
      final limit = switch (_stage) {
        WimHofStage.prep => config.prepSeconds * 1000,
        WimHofStage.breathing => config.breathingMs,
        WimHofStage.retention => null, // открытая стадия
        WimHofStage.recovery => config.recoveryHoldSec * 1000,
        WimHofStage.finished => null,
      };
      if (limit == null) {
        // retention копит время; finished поглощает остаток.
        if (_stage == WimHofStage.retention) _stageElapsedMs += rest;
        return;
      }
      final room = limit - _stageElapsedMs;
      if (rest < room) {
        _stageElapsedMs += rest;
        return;
      }
      rest -= room;
      _transition();
    }
  }

  void _transition() {
    _stageElapsedMs = 0;
    switch (_stage) {
      case WimHofStage.prep:
        _stage = WimHofStage.breathing;
      case WimHofStage.breathing:
        _stage = WimHofStage.retention;
      case WimHofStage.retention:
        // Достижимо только через endRetention.
        _stage = WimHofStage.recovery;
      case WimHofStage.recovery:
        if (_round < config.rounds) {
          _round += 1;
          _stage = WimHofStage.breathing;
        } else {
          _stage = WimHofStage.finished;
        }
      case WimHofStage.finished:
        break;
    }
  }

  /// Тап «хочу вдохнуть»: фиксирует задержку раунда и уводит в recovery.
  void endRetention() {
    if (_stage != WimHofStage.retention) return;
    _retentionsSec.add(_stageElapsedMs ~/ 1000);
    _transition();
  }
}
