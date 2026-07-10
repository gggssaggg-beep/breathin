/// Доменные модели каталога техник. Чистый Dart, без Flutter-зависимостей
/// (см. ПЛАН_и_архитектура.md §3.1, §5). Тестируется как обычный Dart.
library;

/// Тип техники: со счётом фаз, по таймеру (свободный ритм) или метод Вима Хофа.
enum TechniqueType { counted, timer, wimHof }

/// Фаза дыхательного цикла.
enum PhaseKind { inhale, holdIn, exhale, holdOut }

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

/// Запись каталога. Для среза №1 достаточно counted-полей; timer/wimHof-поля
/// добавляются в последующих партиях (см. ПЛАН §5.1).
class Technique {
  final String id;
  final TechniqueType type;
  final List<PhaseSpec> phases;
  final int defaultCycles;

  const Technique({
    required this.id,
    required this.type,
    required this.phases,
    this.defaultCycles = 10,
  });
}
