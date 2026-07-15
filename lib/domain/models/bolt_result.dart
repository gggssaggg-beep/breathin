/// Результат дыхательного теста BOLT (Body Oxygen Level Test): время в
/// секундах от спокойного выдоха до ПЕРВОГО непроизвольного позыва вдохнуть.
/// Чистый Dart, JSON — формат хранения (см. BoltRepository).
///
/// Научная рамка — docs/research/BOLT_scientific_reference.md: BOLT НЕ
/// медицинская метрика, а ориентир чувствительности дыхания к CO₂.
library;

class BoltResult {
  final String id;
  final DateTime takenAt;

  /// Секунды задержки (целые; тест считает секундомером).
  final int seconds;

  const BoltResult({
    required this.id,
    required this.takenAt,
    required this.seconds,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'takenAt': takenAt.toIso8601String(),
        'seconds': seconds,
      };

  factory BoltResult.fromJson(Map<String, dynamic> json) => BoltResult(
        id: json['id'] as String,
        takenAt: DateTime.parse(json['takenAt'] as String),
        seconds: (json['seconds'] as num).toInt(),
      );
}
