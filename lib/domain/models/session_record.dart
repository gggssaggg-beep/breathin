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

  const SessionRecord({
    required this.id,
    required this.techniqueId,
    required this.startedAt,
    required this.durationSec,
    required this.cyclesCompleted,
    required this.completed,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'techniqueId': techniqueId,
        'startedAt': startedAt.millisecondsSinceEpoch,
        'durationSec': durationSec,
        'cyclesCompleted': cyclesCompleted,
        'completed': completed,
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
      );
}
