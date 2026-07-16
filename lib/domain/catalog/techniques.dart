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
  // «Подходит для дневной практики», тонизирующая акцентировка — солнышко.
  energizing: true,
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

/// Физиологический вздох (запрос владельца 2026-07-16): двойной вдох +
/// длинный выдох ртом — самый быстрый научно подтверждённый сброс острого
/// стресса (аварийная кнопка, 1–3 повтора). Двойной вдох описан текстом:
/// движок ведёт один вдох, довдох пользователь делает на его пике.
const physiologicalSigh = Technique(
  id: 'sigh',
  type: TechniqueType.counted,
  safetyLevel: SafetyLevel.low,
  safetyKey: 'safety_low',
  icon: TechniqueIcon.sigh,
  phases: [
    PhaseSpec(kind: PhaseKind.inhale, defaultSec: 3.0, minSec: 2.0, maxSec: 5.0),
    PhaseSpec(kind: PhaseKind.exhale, defaultSec: 7.0, minSec: 4.0, maxSec: 10.0),
  ],
  scaling: ScalingMode.perPhase,
  defaultCycles: 3,
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
  // «Усиливает концентрацию и энергетический тонус» — солнышко.
  energizing: true,
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

/// Вытягивающее дыхание (Stretch) — практика Суфийского движения (учение
/// Хазрата Инайят Хана). Вдох всегда 4 через нос, выдох через рот плавно
/// удлиняется 4→6→…→28, затем возвращается 26→…→4 (шаг +2, всего 25 дыханий).
/// Скриптовая техника: длительности выдоха фиксированы и растут по циклам,
/// поэтому не масштабируются слайдерами (движок поддерживает переменные фазы).
List<List<PhaseSpec>> _stretchScript() {
  // Выдохи: вверх 4..28 (13 значений), затем вниз 26..4 (12) — 25 дыханий.
  final exhales = <int>[
    for (var s = 4; s <= 28; s += 2) s,
    for (var s = 26; s >= 4; s -= 2) s,
  ];
  return [
    for (final ex in exhales)
      [
        const PhaseSpec(kind: PhaseKind.inhale, defaultSec: 4, editable: false),
        PhaseSpec(
          kind: PhaseKind.exhale,
          defaultSec: ex.toDouble(),
          editable: false,
        ),
      ],
  ];
}

final stretchBreath = Technique(
  id: 'stretch',
  type: TechniqueType.scripted,
  safetyLevel: SafetyLevel.low,
  safetyKey: 'safety_low',
  icon: TechniqueIcon.stretch,
  cycleScript: _stretchScript(),
);

/// Дыхание по элементам — очистительная практика Суфийского движения
/// (учение Хазрата Инайят Хана): пять элементов по пять дыханий,
/// у каждого свой маршрут (нос/рот); вдох 4, выдох 6, 60 BPM.
List<List<PhaseSpec>> _elementalScript() => [
      for (var i = 0; i < 25; i++)
        [
          const PhaseSpec(
              kind: PhaseKind.inhale, defaultSec: 4, editable: false),
          const PhaseSpec(
              kind: PhaseKind.exhale, defaultSec: 6, editable: false),
        ],
    ];

final elementalBreath = Technique(
  id: 'elemental',
  type: TechniqueType.scripted,
  safetyLevel: SafetyLevel.low,
  safetyKey: 'safety_low',
  icon: TechniqueIcon.elements,
  cycleScript: _elementalScript(),
  segments: const [
    BreathSegment(
        id: 'earth',
        cycles: 5,
        inhale: BreathRoute.nose,
        exhale: BreathRoute.nose),
    BreathSegment(
        id: 'water',
        cycles: 5,
        inhale: BreathRoute.nose,
        exhale: BreathRoute.mouth),
    BreathSegment(
        id: 'fire',
        cycles: 5,
        inhale: BreathRoute.mouth,
        exhale: BreathRoute.nose),
    BreathSegment(
        id: 'air',
        cycles: 5,
        inhale: BreathRoute.mouth,
        exhale: BreathRoute.mouth),
    BreathSegment(id: 'ether', cycles: 5), // тихое, едва заметное дыхание
  ],
);

/// Фикр (№10, школа Инайят Хана в светской подаче): спокойное дыхание носом
/// вдох 4 / выдох 6, на каждой фазе мысленно повторяется фраза (аффирмация
/// или традиционная вазифа — выбор в настройке сессии, см. fikr_phrases.dart).
const fikr = Technique(
  id: 'fikr',
  type: TechniqueType.counted,
  safetyLevel: SafetyLevel.low,
  safetyKey: 'safety_low',
  icon: TechniqueIcon.quote,
  phases: [
    PhaseSpec(kind: PhaseKind.inhale, defaultSec: 4.0),
    PhaseSpec(kind: PhaseKind.exhale, defaultSec: 6.0),
  ],
  scaling: ScalingMode.perPhase,
  defaultCycles: 30, // ~5 минут при 4+6 с
);

/// Мягкое дыхание сосуда (контент владельца 2026-07-15, тибетское «кувшинное»
/// в безопасном варианте): вдох вниз → мягкая задержка 3–5 c (максимум
/// ЖЁСТКО 8 c — требование владельца) → медленный выдох; внимание на точке
/// ниже пупка. Стабилизация «бьющей вверх» энергии.
const vesselBreath = Technique(
  id: 'vessel',
  type: TechniqueType.counted,
  safetyLevel: SafetyLevel.medium,
  safetyKey: 'safety_holds_generic',
  icon: TechniqueIcon.vessel,
  phases: [
    PhaseSpec(kind: PhaseKind.inhale, defaultSec: 4.0),
    PhaseSpec(kind: PhaseKind.holdIn, defaultSec: 4.0, maxSec: 8.0),
    PhaseSpec(kind: PhaseKind.exhale, defaultSec: 6.0),
  ],
  scaling: ScalingMode.perPhase,
  defaultCycles: 10, // 7–15 по контенту
);

/// Дыхание с бандхами (запрос владельца 2026-07-16): ознакомительная форма
/// работы с мышечными «замками» хатха-йоги — вдох 4 → задержка 4 с мягкой
/// мула-бандхой (треть силы, без натуживания) → выдох 8 с расслаблением.
/// Традиционно связывается с сублимацией (перенаправлением витальной энергии
/// вверх). Описание ЧЕСТНО помечает упрощённость: полные бандхи — только с
/// наставником традиции (решение после разбора «ВХ ≠ туммо»: не приписывать
/// технике то, чего в ней нет).
const bandhaBreath = Technique(
  id: 'bandha',
  type: TechniqueType.counted,
  safetyLevel: SafetyLevel.medium,
  safetyKey: 'safety_bandha',
  icon: TechniqueIcon.lock,
  phases: [
    PhaseSpec(kind: PhaseKind.inhale, defaultSec: 4.0, maxSec: 6.0),
    PhaseSpec(kind: PhaseKind.holdIn, defaultSec: 4.0, maxSec: 8.0),
    PhaseSpec(kind: PhaseKind.exhale, defaultSec: 8.0, minSec: 4.0, maxSec: 12.0),
  ],
  scaling: ScalingMode.perPhase,
  defaultCycles: 8,
  recommendedMaxCyclesNovice: 6,
);

/// Малая (микрокосмическая) орбита — даосская внутренняя работа в светской
/// форме (запрос владельца 2026-07-16, «трансформация энергии»): свободное
/// дыхание, внимание кругом «вдох — вверх по спине, выдох — вниз по передней
/// линии в живот». Движку ничего нового не нужно — чистая timer-техника.
const orbitBreath = Technique(
  id: 'orbit',
  type: TechniqueType.timer,
  safetyLevel: SafetyLevel.low,
  safetyKey: 'safety_low',
  icon: TechniqueIcon.orbit,
  defaultTimerMin: 10,
  minTimerMin: 5,
  maxTimerMin: 20,
);

/// Осознанное дыхание (анапанасати / дзенский счёт дыханий): наблюдение
/// без управления. Старейшая медитативная техника; чистый таймер.
const mindfulBreath = Technique(
  id: 'mindful',
  type: TechniqueType.timer,
  safetyLevel: SafetyLevel.low,
  safetyKey: 'safety_low',
  icon: TechniqueIcon.eye,
  defaultTimerMin: 10,
  minTimerMin: 5,
  maxTimerMin: 30,
);

/// Дыхание по центральной оси (контент владельца): естественное дыхание без
/// счёта, внимание скользит по вертикали тела — timer-техника.
const axisBreath = Technique(
  id: 'axis',
  type: TechniqueType.timer,
  safetyLevel: SafetyLevel.low,
  safetyKey: 'safety_low',
  icon: TechniqueIcon.axis,
  defaultTimerMin: 7,
  minTimerMin: 5,
  maxTimerMin: 10,
);

/// Девять очищающих дыханий (контент владельца, тибетская очистка каналов):
/// ровно 9 дыханий — 3 «вдох левой/выдох правой», 3 наоборот, 3 обеими.
/// Скриптовая, как элементы: сегменты дают метку стороны на экране.
final nineBreaths = Technique(
  id: 'nine_breaths',
  type: TechniqueType.scripted,
  safetyLevel: SafetyLevel.medium,
  safetyKey: 'safety_holds_generic',
  icon: TechniqueIcon.sparkles,
  cycleScript: [
    for (var i = 0; i < 9; i++)
      const [
        PhaseSpec(kind: PhaseKind.inhale, defaultSec: 4.0, editable: false),
        PhaseSpec(kind: PhaseKind.exhale, defaultSec: 4.0, editable: false),
      ],
  ],
  segments: const [
    BreathSegment(
        id: 'nine_left',
        cycles: 3,
        inhale: BreathRoute.nose,
        exhale: BreathRoute.nose),
    BreathSegment(
        id: 'nine_right',
        cycles: 3,
        inhale: BreathRoute.nose,
        exhale: BreathRoute.nose),
    BreathSegment(
        id: 'nine_both',
        cycles: 3,
        inhale: BreathRoute.nose,
        exhale: BreathRoute.nose),
  ],
);

/// Метод Вима Хофа — особая логика движка: машина раундов WimHofMachine
/// (ПЛАН §3.4), запуск через полноэкранное предупреждение (ТЗ §2.4).
const wimHof = Technique(
  id: 'wim_hof',
  type: TechniqueType.wimHof,
  safetyLevel: SafetyLevel.high,
  safetyKey: 'safety_intense',
  icon: TechniqueIcon.snowflake,
  wimHof: WimHofDefaults(),
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
/// `final`, а не `const`: у вытягивающего скрипт строится генератором.
final List<Technique> catalog = [
  boxBreathing,
  triangleBreathing,
  fourSevenEight,
  fourTwoFour,
  twoEight,
  twoTen,
  physiologicalSigh,
  fourSixteenEight,
  coherent,
  stretchBreath,
  elementalBreath,
  nineBreaths,
  fikr,
  vesselBreath,
  bandhaBreath,
  orbitBreath,
  diaphragmatic,
  mindfulBreath,
  nadiShodhana,
  axisBreath,
  soundBreath,
  wimHof,
];

/// Поиск техники по id; бросает [ArgumentError], если id неизвестен.
Technique techniqueById(String id) => catalog.firstWhere(
      (t) => t.id == id,
      orElse: () => throw ArgumentError('Неизвестная техника: $id'),
    );
