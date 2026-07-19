/// Каналы сопровождения сессии (ТЗ §3.3): комбинируются свободно.
/// Чистый Dart; JSON — формат хранения в настройках per-техника.
library;

class FeedbackChannels {
  /// Голосовые подсказки фаз (П8, реализовано 2026-07-18): пре-рендеренные
  /// клипы «вдох/выдох/задержка/приготовьтесь» поверх выбранного звука.
  final bool voice;

  /// Звуковые сигналы фаз (набор «Минимал» и далее).
  final bool sound;

  /// Метроном с акцентом на смене фазы.
  final bool metronome;

  /// Вибро-паттерны смены фаз.
  final bool vibration;

  /// Визуальный режим (анимированная фигура + надпись + отсчёт).
  final bool visual;

  const FeedbackChannels({
    this.voice = false, // включим по умолчанию, когда появится голос (П8)
    this.sound = true,
    this.metronome = false,
    this.vibration = true,
    this.visual = true,
  });

  FeedbackChannels copyWith({
    bool? voice,
    bool? sound,
    bool? metronome,
    bool? vibration,
    bool? visual,
  }) {
    return FeedbackChannels(
      voice: voice ?? this.voice,
      sound: sound ?? this.sound,
      metronome: metronome ?? this.metronome,
      vibration: vibration ?? this.vibration,
      visual: visual ?? this.visual,
    );
  }

  Map<String, dynamic> toJson() => {
        'voice': voice,
        'sound': sound,
        'metronome': metronome,
        'vibration': vibration,
        'visual': visual,
      };

  factory FeedbackChannels.fromJson(Map<String, dynamic> json) {
    const def = FeedbackChannels();
    return FeedbackChannels(
      voice: json['voice'] as bool? ?? def.voice,
      sound: json['sound'] as bool? ?? def.sound,
      metronome: json['metronome'] as bool? ?? def.metronome,
      vibration: json['vibration'] as bool? ?? def.vibration,
      visual: json['visual'] as bool? ?? def.visual,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FeedbackChannels &&
      other.voice == voice &&
      other.sound == sound &&
      other.metronome == metronome &&
      other.vibration == vibration &&
      other.visual == visual;

  @override
  int get hashCode => Object.hash(voice, sound, metronome, vibration, visual);
}
