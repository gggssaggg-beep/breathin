/// Доменные модели каталога техник. Чистый Dart, без Flutter-зависимостей
/// (см. ПЛАН_и_архитектура.md §3.1, §5). Тестируется как обычный Dart.
library;

/// Тип техники: со счётом фаз, по таймеру (свободный ритм), метод Вима Хофа
/// или скриптовая (фиксированная последовательность циклов с заранее заданными
/// длительностями — вытягивающее дыхание, где выдох растёт от цикла к циклу).
enum TechniqueType { counted, timer, wimHof, scripted }

/// Фаза дыхательного цикла.
enum PhaseKind { inhale, holdIn, exhale, holdOut }

/// Уровень предупреждений безопасности (ТЗ §2.4): low — без задержек,
/// medium — есть задержки, high — интенсивные/только для опытных.
enum SafetyLevel { low, medium, high }

/// Режим настройки длительностей фаз (ТЗ §2.1, ПЛАН §5.1).
enum ScalingMode {
  /// Каждая фаза настраивается независимым слайдером.
  perPhase,

  /// Слайдер базы, пропорция фиксирована (4-16-8 → 1:4:2).
  ratioLock,

  /// perPhase + переключатель «держать пропорцию» (2-8, 2-10).
  ratioOptional,

  /// Фазы фиксированы, настраивается множитель темпа (4-7-8).
  tempoMultiplier,
}

/// Фигура визуального режима (ТЗ §3.3: круг / точка по периметру фигуры).
enum VisualShape { circle, square, triangle }

/// Семантическая иконка техники; отображение в конкретную графику — задача UI.
enum TechniqueIcon {
  square,
  triangle,
  moon,
  balance,
  wave,
  deepWave,
  mountain,
  heart,
  snowflake,
  belly,
  nostrils,
  hum,
  stretch,
  elements,
  quote,
  vessel,
  axis,
  sparkles,
  sigh,
  lock,
  orbit,
  eye,
  energyWave,
}

/// Маршрут дыхания: через нос или через рот.
enum BreathRoute { nose, mouth }

/// Сегмент скриптовой техники с маршрутом дыхания (элемент стихии):
/// объединяет несколько циклов под общей семантической меткой.
/// [inhale]/[exhale] == null означает тихое дыхание без указания маршрута (эфир).
class BreathSegment {
  final String id;
  final int cycles;
  final BreathRoute? inhale;
  final BreathRoute? exhale;

  const BreathSegment({
    required this.id,
    required this.cycles,
    this.inhale,
    this.exhale,
  });
}

/// Спецификация одной фазы техники: дефолт и допустимый диапазон настройки
/// (шаг слайдера 0.5 с — ТЗ §3.2; клэмп значений — задача UI, не компилятора).
class PhaseSpec {
  final PhaseKind kind;
  final double defaultSec;
  final bool editable;
  final double minSec;
  final double maxSec;

  const PhaseSpec({
    required this.kind,
    required this.defaultSec,
    this.editable = true,
    this.minSec = 2.0,
    this.maxSec = 10.0,
  });
}

/// Периодическая подсказка timer-техники (Нади Шодхана: «левая… правая…»).
/// Интервал 0 в [intervalOptionsSec] означает «подсказки выключены».
class PeriodicCue {
  final List<int> intervalOptionsSec;
  final int defaultIntervalSec;

  const PeriodicCue({
    required this.intervalOptionsSec,
    required this.defaultIntervalSec,
  });
}

/// Дефолты и диапазоны метода Вима Хофа (ТЗ §2.3, ПЛАН §3.4).
class WimHofDefaults {
  final int breaths;
  final int minBreaths;
  final int maxBreaths;
  final double paceSec;
  final double minPaceSec;
  final double maxPaceSec;
  final int rounds;
  final int minRounds;
  final int maxRounds;
  final int recoveryHoldSec;

  const WimHofDefaults({
    this.breaths = 30,
    this.minBreaths = 20,
    this.maxBreaths = 50,
    this.paceSec = 2.0,
    this.minPaceSec = 1.5,
    this.maxPaceSec = 3.0,
    this.rounds = 3,
    this.minRounds = 1,
    this.maxRounds = 5,
    this.recoveryHoldSec = 15,
  });
}

/// Запись каталога (ПЛАН §5.1). Тексты — ARB-ключи вида `tech_<id>_name`;
/// доменный слой хранит только идентификаторы, локализация — задача UI.
class Technique {
  final String id;
  final TechniqueType type;
  final SafetyLevel safetyLevel;

  /// ARB-ключ текста безопасности: safety_low / safety_holds_generic /
  /// safety_intense (ТЗ §2.4).
  final String safetyKey;
  final VisualShape visual;
  final TechniqueIcon icon;

  // --- counted ---
  /// Фазовая структура; null для timer-техник и Вима Хофа.
  final List<PhaseSpec>? phases;
  final ScalingMode? scaling;

  /// Для [ScalingMode.ratioOptional]: начальное положение тумблера
  /// «держать пропорцию». У 2-8/2-10 пропорция — суть техники (true);
  /// у box/triangle/4-2-4 тумблер добавлен по просьбе владельца (§6),
  /// но по умолчанию выключен — привычные независимые слайдеры.
  final bool keepRatioDefault;

  /// 4-7-8: варианты множителя темпа.
  final List<double>? tempoOptions;

  /// 4-16-8: упрощённый паттерн, предлагаемый по умолчанию (ТЗ §2.1).
  final List<PhaseSpec>? simplifiedPhases;
  final int defaultCycles;

  /// 4-7-8 и 4-16-8: рекомендация новичкам не превышать N циклов.
  final int? recommendedMaxCyclesNovice;

  // --- timer ---
  final int? defaultTimerMin;
  final int? minTimerMin;
  final int? maxTimerMin;
  final PeriodicCue? periodicCue;
  final bool backgroundSoundOption;

  // --- scripted ---
  /// Фиксированная последовательность циклов: каждый элемент — фазы одного
  /// цикла с заранее заданными длительностями (не масштабируются слайдерами).
  /// Задан только для [TechniqueType.scripted] (вытягивающее дыхание).
  final List<List<PhaseSpec>>? cycleScript;

  /// Сегменты скриптовой техники с общей меткой (элементы): UI подсвечивает
  /// метку, цвет и маршрут (например, «Дыхание по элементам»).
  final List<BreathSegment>? segments;

  // --- wimHof ---
  final WimHofDefaults? wimHof;

  /// Техника этапа 2 (Вим Хоф): видна в каталоге, но запуск отключён до П18.
  final bool stage2;

  /// Бодрящая техника (влад. §10): рядом с названием показываем солнышко.
  /// Пока единственная такая — метод Вима Хофа.
  final bool energizing;

  const Technique({
    required this.id,
    required this.type,
    required this.safetyLevel,
    required this.safetyKey,
    required this.icon,
    this.visual = VisualShape.circle,
    this.phases,
    this.scaling,
    this.keepRatioDefault = true,
    this.tempoOptions,
    this.simplifiedPhases,
    this.defaultCycles = 10,
    this.recommendedMaxCyclesNovice,
    this.defaultTimerMin,
    this.minTimerMin,
    this.maxTimerMin,
    this.periodicCue,
    this.backgroundSoundOption = false,
    this.cycleScript,
    this.segments,
    this.wimHof,
    this.stage2 = false,
    this.energizing = false,
  });

  /// Паттерн, предлагаемый по умолчанию: упрощённый, если техника его задаёт
  /// (4-16-8 → 4-8-8, ТЗ §2.1), иначе основной.
  List<PhaseSpec>? get defaultPhases => simplifiedPhases ?? phases;

  /// ARB-ключи текстов техники.
  String get nameKey => 'tech_${id}_name';
  String get descriptionKey => 'tech_${id}_desc';
  String get benefitKey => 'tech_${id}_benefit';

  /// Сегмент, соответствующий циклу [cycleIndex] (0-based).
  /// Использует префиксные суммы [segments.cycles]. Возвращает null при
  /// отрицательном индексе, отсутствии сегментов или выходе за их сумму.
  BreathSegment? segmentForCycle(int cycleIndex) {
    if (cycleIndex < 0) return null;
    final segs = segments;
    if (segs == null) return null;
    var offset = 0;
    for (final seg in segs) {
      offset += seg.cycles;
      if (cycleIndex < offset) return seg;
    }
    return null;
  }
}
