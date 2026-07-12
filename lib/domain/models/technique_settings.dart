import 'feedback_channels.dart';
import 'session_config.dart';
import 'technique.dart';

/// Последние настройки сессии per-техника (ТЗ §3: «сохраняются per-техника»,
/// ПЛАН §4.1). Иммутабельны; JSON — формат хранения. Чистый Dart.
class TechniqueSettings {
  final String techniqueId;
  final EndMode endMode;

  /// Число циклов при [EndMode.cycles] (ТЗ §3.1: 1..100).
  final int cycles;

  /// Таймер в минутах при [EndMode.timer] (ТЗ §3.1: 1..60; timer-техники 1..30).
  final int timerMinutes;

  /// Длительности фаз counted-техники; пустой список для timer/wimHof.
  final List<double> phaseSeconds;

  /// Множитель темпа для [ScalingMode.tempoMultiplier] (4-7-8).
  final double tempoMultiplier;

  /// «Держать пропорцию» для [ScalingMode.ratioOptional] (2-8, 2-10).
  final bool keepRatio;

  /// 4-16-8: упрощённый режим 4-8-8 (дефолт по ТЗ §2.1) вместо полного.
  final bool useSimplified;

  final FeedbackChannels feedback;

  /// Подготовительный отсчёт перед первым вдохом (3..5 c, ТЗ §3.4).
  final int prepSeconds;

  const TechniqueSettings({
    required this.techniqueId,
    required this.endMode,
    required this.cycles,
    required this.timerMinutes,
    required this.phaseSeconds,
    this.tempoMultiplier = 1.0,
    this.keepRatio = true,
    this.useSimplified = true,
    this.feedback = const FeedbackChannels(),
    this.prepSeconds = 3,
  });

  /// Классические настройки техники — состояние «Сбросить к классике»
  /// (ТЗ §3.2) и дефолт до первого сохранения.
  factory TechniqueSettings.classic(Technique t) {
    return TechniqueSettings(
      techniqueId: t.id,
      endMode:
          t.type == TechniqueType.timer ? EndMode.timer : EndMode.cycles,
      cycles: t.defaultCycles,
      timerMinutes: t.defaultTimerMin ?? 5,
      phaseSeconds:
          (t.defaultPhases ?? const []).map((p) => p.defaultSec).toList(),
      keepRatio: t.keepRatioDefault,
    );
  }

  TechniqueSettings copyWith({
    EndMode? endMode,
    int? cycles,
    int? timerMinutes,
    List<double>? phaseSeconds,
    double? tempoMultiplier,
    bool? keepRatio,
    bool? useSimplified,
    FeedbackChannels? feedback,
    int? prepSeconds,
  }) {
    return TechniqueSettings(
      techniqueId: techniqueId,
      endMode: endMode ?? this.endMode,
      cycles: cycles ?? this.cycles,
      timerMinutes: timerMinutes ?? this.timerMinutes,
      phaseSeconds: phaseSeconds ?? this.phaseSeconds,
      tempoMultiplier: tempoMultiplier ?? this.tempoMultiplier,
      keepRatio: keepRatio ?? this.keepRatio,
      useSimplified: useSimplified ?? this.useSimplified,
      feedback: feedback ?? this.feedback,
      prepSeconds: prepSeconds ?? this.prepSeconds,
    );
  }

  /// Собирает [SessionConfig] для компилятора плана. Только counted-техники;
  /// timer — режим компилятора П10, Вим Хоф — движок П18.
  ///
  /// В режиме [ScalingMode.tempoMultiplier] длительности берутся из дефолтов
  /// техники × множитель (сохранённые [phaseSeconds] игнорируются — фазы
  /// нередактируемы, ТЗ §2.1).
  SessionConfig toSessionConfig(Technique t) {
    if (t.type != TechniqueType.counted) {
      throw ArgumentError('toSessionConfig: техника ${t.id} не counted');
    }
    final List<double> secs;
    if (t.scaling == ScalingMode.tempoMultiplier) {
      secs = t.phases!.map((p) => p.defaultSec * tempoMultiplier).toList();
    } else {
      secs = phaseSeconds;
    }
    return SessionConfig(
      endMode: endMode,
      cycles: cycles,
      timerMinutes: timerMinutes,
      phaseSeconds: secs,
      prepSeconds: prepSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'techniqueId': techniqueId,
        'endMode': endMode.name,
        'cycles': cycles,
        'timerMinutes': timerMinutes,
        'phaseSeconds': phaseSeconds,
        'tempoMultiplier': tempoMultiplier,
        'keepRatio': keepRatio,
        'useSimplified': useSimplified,
        'feedback': feedback.toJson(),
        'prepSeconds': prepSeconds,
      };

  /// Читает JSON; неизвестные/отсутствующие поля закрываются классикой [t],
  /// чтобы старые сохранения переживали эволюцию формата.
  factory TechniqueSettings.fromJson(Technique t, Map<String, dynamic> json) {
    final classic = TechniqueSettings.classic(t);
    return TechniqueSettings(
      techniqueId: t.id,
      endMode: EndMode.values.asNameMap()[json['endMode']] ?? classic.endMode,
      cycles: (json['cycles'] as num?)?.toInt() ?? classic.cycles,
      timerMinutes:
          (json['timerMinutes'] as num?)?.toInt() ?? classic.timerMinutes,
      phaseSeconds: (json['phaseSeconds'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          classic.phaseSeconds,
      tempoMultiplier: (json['tempoMultiplier'] as num?)?.toDouble() ??
          classic.tempoMultiplier,
      keepRatio: json['keepRatio'] as bool? ?? classic.keepRatio,
      useSimplified:
          json['useSimplified'] as bool? ?? classic.useSimplified,
      feedback: json['feedback'] is Map<String, dynamic>
          ? FeedbackChannels.fromJson(json['feedback'] as Map<String, dynamic>)
          : classic.feedback,
      prepSeconds:
          (json['prepSeconds'] as num?)?.toInt() ?? classic.prepSeconds,
    );
  }
}
