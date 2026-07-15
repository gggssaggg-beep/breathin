/// Интерпретация результата BOLT по диапазонам.
///
/// ВАЖНО (docs/research/BOLT_scientific_reference.md): пороги НЕ имеют
/// peer-reviewed валидации — это эмпирические диапазоны популярных источников
/// (Бутейко / McKeown). Подаём как ориентир CO₂-чувствительности, НЕ как
/// норматив и НЕ как медицинскую метрику. Тексты уровней — ARB-ключи,
/// подача светская и без обещаний диагностики.
library;

/// Уровень CO₂-толерантности по времени BOLT.
enum BoltLevel {
  /// < 10 c — низкая толерантность, склонность к гипервентиляции.
  low,

  /// 10–20 c — средняя (обычная реактивность дыхания в покое).
  medium,

  /// 20–40 c — высокая.
  high,

  /// > 40 c — очень высокая (обычно у тренированных).
  veryHigh,
}

/// Границы диапазонов (сек). Полуинтервалы: [0,10), [10,20), [20,40), [40,∞).
BoltLevel boltLevelFor(int seconds) {
  if (seconds < 10) return BoltLevel.low;
  if (seconds < 20) return BoltLevel.medium;
  if (seconds < 40) return BoltLevel.high;
  return BoltLevel.veryHigh;
}

/// Человеческая подпись диапазона для UI («< 10 c», «10–20 c», «20–40 c»,
/// «> 40 c»). Локаль-независимо (только цифры и знаки), без слова «секунд».
String boltRangeText(BoltLevel level) {
  switch (level) {
    case BoltLevel.low:
      return '< 10';
    case BoltLevel.medium:
      return '10–20';
    case BoltLevel.high:
      return '20–40';
    case BoltLevel.veryHigh:
      return '> 40';
  }
}
