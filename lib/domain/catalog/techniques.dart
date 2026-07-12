import '../models/technique.dart';

/// Каталог техник MVP (ТЗ §2, ПЛАН §5.2): 8 со счётом + 3 таймерные;
/// Вим Хоф — 12-я запись, помечена stage2 (запуск — этап 2, П18).
/// Данные-как-код: константы проверяются компилятором, тексты — ARB-ключи.

/// Квадратное дыхание 4-4-4-4 — классика для снятия стресса.
const boxBreathing = Technique(
  id: 'box',
  type: TechniqueType.counted,
  safetyLevel: SafetyLevel.medium,
  safetyKey: 'safety_holds_generic',
  icon: TechniqueIcon.square,
  visual: VisualShape.square,
  // Тумблер «держать пропорцию» по просьбе владельца (§6); дефолт выкл —
  // привычные независимые слайдеры.
  scaling: ScalingMode.ratioOptional,
  keepRatioDefault: false,
  defaultCycles: 10,
  phases: [
    PhaseSpec(kind: PhaseKind.inhale, defaultSec: 4),
    PhaseSpec(kind: PhaseKind.holdIn, defaultSec: 4),
    PhaseSpec(kind: PhaseKind.exhale, defaultSec: 4),
    PhaseSpec(kind: PhaseKind.holdOut, defaultSec: 4),
  ],
);

/// Треугольное дыхание 4-4-4 — вариант без второй задержки.
const triangleBreathing = Technique(
  id: 'triangle',
  type: TechniqueType.counted,
  safetyLevel: SafetyLevel.medium,
  safetyKey: 'safety_holds_generic',
  icon: TechniqueIcon.triangle,
  visual: VisualShape.triangle,
  scaling: ScalingMode.ratioOptional,
  keepRatioDefault: false,
  defaultCycles: 10,
  phases: [
    PhaseSpec(kind: PhaseKind.inhale, defaultSec: 4),
    PhaseSpec(kind: PhaseKind.holdIn, defaultSec: 4),
    PhaseSpec(kind: PhaseKind.exhale, defaultSec: 4),
  ],
);

/// 4-7-8 (метод Э. Вейла) — для засыпания; пропорция фиксирована,
/// настраивается только множитель темпа. Новичкам — не более 4 циклов.
const fourSevenEight = Technique(
  id: 'four_seven_eight',
  type: TechniqueType.counted,
  safetyLevel: SafetyLevel.medium,
  safetyKey: 'safety_holds_generic',
  icon: TechniqueIcon.moon,
  scaling: ScalingMode.tempoMultiplier,
  tempoOptions: [0.5, 0.75, 1.0, 1.25],
  defaultCycles: 4,
  recommendedMaxCyclesNovice: 4,
  phases: [
    PhaseSpec(kind: PhaseKind.inhale, defaultSec: 4, editable: false),
    PhaseSpec(kind: PhaseKind.holdIn, defaultSec: 7, editable: false),
    PhaseSpec(kind: PhaseKind.exhale, defaultSec: 8, editable: false),
  ],
);

/// 4-2-4 — мягкая балансирующая техника.
const fourTwoFour = Technique(
  id: 'four_two_four',
  type: TechniqueType.counted,
  safetyLevel: SafetyLevel.medium,
  safetyKey: 'safety_holds_generic',
  icon: TechniqueIcon.balance,
  scaling: ScalingMode.ratioOptional,
  keepRatioDefault: false,
  defaultCycles: 10,
  phases: [
    PhaseSpec(kind: PhaseKind.inhale, defaultSec: 4),
    PhaseSpec(kind: PhaseKind.holdIn, defaultSec: 2),
    PhaseSpec(kind: PhaseKind.exhale, defaultSec: 4),
  ],
);

/// 2-8 — удлинённый выдох (1:4): активация парасимпатики, расслабление.
const twoEight = Technique(
  id: 'two_eight',
  type: TechniqueType.counted,
  safetyLevel: SafetyLevel.low,
  safetyKey: 'safety_low',
  icon: TechniqueIcon.wave,
  scaling: ScalingMode.ratioOptional,
  defaultCycles: 10,
  phases: [
    PhaseSpec(kind: PhaseKind.inhale, defaultSec: 2),
    PhaseSpec(kind: PhaseKind.exhale, defaultSec: 8),
  ],
);

/// 2-10 — более глубокая версия 2-8 (1:5).
const twoTen = Technique(
  id: 'two_ten',
  type: TechniqueType.counted,
  safetyLevel: SafetyLevel.low,
  safetyKey: 'safety_low',
  icon: TechniqueIcon.deepWave,
  scaling: ScalingMode.ratioOptional,
  defaultCycles: 10,
  phases: [
    PhaseSpec(kind: PhaseKind.inhale, defaultSec: 2),
    PhaseSpec(kind: PhaseKind.exhale, defaultSec: 10),
  ],
);

/// 4-16-8 — пранаяма-соотношение 1:4:2, только для опытных; по умолчанию
/// предлагается упрощённый режим 4-8-8 (ТЗ §2.1). База масштабируется 3–5 с.
const fourSixteenEight = Technique(
  id: 'four_sixteen_eight',
  type: TechniqueType.counted,
  safetyLevel: SafetyLevel.high,
  safetyKey: 'safety_intense',
  icon: TechniqueIcon.mountain,
  scaling: ScalingMode.ratioLock,
  defaultCycles: 4,
  recommendedMaxCyclesNovice: 4,
  phases: [
    PhaseSpec(kind: PhaseKind.inhale, defaultSec: 4, minSec: 3, maxSec: 5),
    PhaseSpec(kind: PhaseKind.holdIn, defaultSec: 16, minSec: 12, maxSec: 20),
    PhaseSpec(kind: PhaseKind.exhale, defaultSec: 8, minSec: 6, maxSec: 10),
  ],
  simplifiedPhases: [
    PhaseSpec(kind: PhaseKind.inhale, defaultSec: 4, minSec: 3, maxSec: 5),
    PhaseSpec(kind: PhaseKind.holdIn, defaultSec: 8, minSec: 6, maxSec: 10),
    PhaseSpec(kind: PhaseKind.exhale, defaultSec: 8, minSec: 6, maxSec: 10),
  ],
);

/// Когерентное дыхание 5.5-5.5 — ~5–6 дыханий в минуту, выравнивание ВСР.
const coherent = Technique(
  id: 'coherent',
  type: TechniqueType.counted,
  safetyLevel: SafetyLevel.low,
  safetyKey: 'safety_low',
  icon: TechniqueIcon.heart,
  scaling: ScalingMode.perPhase,
  defaultCycles: 10,
  phases: [
    PhaseSpec(kind: PhaseKind.inhale, defaultSec: 5.5, minSec: 4, maxSec: 7),
    PhaseSpec(kind: PhaseKind.exhale, defaultSec: 5.5, minSec: 4, maxSec: 7),
  ],
);

/// Метод Вима Хофа — особая логика движка (ПЛАН §3.4); этап 2 (П18).
const wimHof = Technique(
  id: 'wim_hof',
  type: TechniqueType.wimHof,
  safetyLevel: SafetyLevel.high,
  safetyKey: 'safety_intense',
  icon: TechniqueIcon.snowflake,
  wimHof: WimHofDefaults(),
  stage2: true,
  energizing: true,
);

/// Диафрагмальное (брюшное) дыхание — свободный ритм по таймеру.
const diaphragmatic = Technique(
  id: 'diaphragmatic',
  type: TechniqueType.timer,
  safetyLevel: SafetyLevel.low,
  safetyKey: 'safety_low',
  icon: TechniqueIcon.belly,
  defaultTimerMin: 5,
  minTimerMin: 1,
  maxTimerMin: 30,
  backgroundSoundOption: true,
);

/// Попеременное дыхание ноздрями (Нади Шодхана) — подсказки «левая/правая»
/// с настраиваемым интервалом (0 = выкл).
const nadiShodhana = Technique(
  id: 'nadi_shodhana',
  type: TechniqueType.timer,
  safetyLevel: SafetyLevel.low,
  safetyKey: 'safety_low',
  icon: TechniqueIcon.nostrils,
  defaultTimerMin: 5,
  minTimerMin: 1,
  maxTimerMin: 30,
  periodicCue: PeriodicCue(
    intervalOptionsSec: [0, 10, 15, 20, 30],
    defaultIntervalSec: 15,
  ),
);

/// Дыхание со звуком (Уджайи / Брамари «пчела»).
const soundBreath = Technique(
  id: 'sound_breath',
  type: TechniqueType.timer,
  safetyLevel: SafetyLevel.low,
  safetyKey: 'safety_low',
  icon: TechniqueIcon.hum,
  defaultTimerMin: 5,
  minTimerMin: 1,
  maxTimerMin: 30,
);

/// Каталог в порядке отображения на главном экране (ТЗ §6.2).
const List<Technique> catalog = [
  boxBreathing,
  triangleBreathing,
  fourSevenEight,
  fourTwoFour,
  twoEight,
  twoTen,
  fourSixteenEight,
  coherent,
  diaphragmatic,
  nadiShodhana,
  soundBreath,
  wimHof,
];

/// Поиск техники по id; бросает [ArgumentError], если id неизвестен.
Technique techniqueById(String id) => catalog.firstWhere(
      (t) => t.id == id,
      orElse: () => throw ArgumentError('Неизвестная техника: $id'),
    );
