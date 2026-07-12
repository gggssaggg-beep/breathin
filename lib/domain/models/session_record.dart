/// Запись завершённой (или прерванной) практики — строка истории сессий
/// (ТЗ §9 Session, ПЛАН §4.1). Чистый Dart; JSON — формат хранения.
class SessionRecord {
  final String id;
  final String techniqueId;

  /// Локальное время старта (пояс устройства — без сети, ТЗ §7).
  final DateTime startedAt;

  /// Фактическая длительность, секунды.
  final int durationSec;

  /// Полных завершённых циклов.
  final int cyclesCompleted;

  /// true — доведена до гонга; false — прервана пользователем.
  final bool completed;

  /// Фактический паттерн фаз сессии, например «4-8-8» (влад. §15: отличать
  /// упрощённый режим от полного и видеть прогресс). null — записи старых
  /// версий приложения.
  final String? variant;

  const SessionRecord({
    required this.id,
    required this.techniqueId,
    required this.startedAt,
    required this.durationSec,
    required this.cyclesCompleted,
    required this.completed,
    this.variant,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'techniqueId': techniqueId,
        'startedAt': startedAt.millisecondsSinceEpoch,
        'durationSec': durationSec,
        'cyclesCompleted': cyclesCompleted,
        'completed': completed,
        if (variant != null) 'variant': variant,
      };

  factory SessionRecord.fromJson(Map<String, dynamic> json) => SessionRecord(
        id: json['id'] as String,
        techniqueId: json['techniqueId'] as String,
        startedAt: DateTime.fromMillisecondsSinceEpoch(
          (json['startedAt'] as num).toInt(),
        ),
        durationSec: (json['durationSec'] as num).toInt(),
        cyclesCompleted: (json['cyclesCompleted'] as num).toInt(),
        completed: json['completed'] as bool? ?? true,
        variant: json['variant'] as String?,
      );
}

/// Паттерн-строка из длительностей фаз: «4-8-8»; целые — без «.0»,
/// дробные — с одним знаком (формат как в подписи техники).
String variantOf(Iterable<double> phaseSeconds) => phaseSeconds
    .map((s) =>
        s == s.roundToDouble() ? s.toInt().toString() : s.toStringAsFixed(1))
    .join('-');
