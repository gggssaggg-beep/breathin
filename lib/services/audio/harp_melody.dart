/// «Мелодия дышит» — раскладка живых нот арфы по фазам дыхания (утверждена
/// владельцем 2026-07-16 после прослушки превью; все синтезы забракованы).
///
/// Лесенка — пентатоника до (8 нот C4..E5, assets/audio/sets/harp/):
/// вдох — восходящие ноты (по одной в секунду, адаптивно к длительности),
/// выдох — те же зеркально вниз, задержки — одна тихая нота (верхняя C5
/// после вдоха, нижняя C4 после выдоха). Ноты — реальные щипки арфы
/// (VSCO 2 CE, CC0): звон тает сам, ничего не обрывается.
library;

import '../../domain/models/technique.dart';

/// Нота мелодии: смещение от начала фазы, индекс в лесенке, громкость.
typedef MelodyNote = ({int offsetMs, int scaleIndex, double gain});

/// Число нот лесенки в наборе (note_0..note_7).
const int harpScaleSize = 8;

/// Индексы тихих нот задержек: верхняя (C5) и нижняя (C4).
const int _holdHighIndex = 5;
const int _holdLowIndex = 0;

/// Ноты фазы [kind] длительностью [durMs]: как в утверждённом превью.
/// Вдох/выдох — примерно нота в секунду (2..8 нот), позиции равномерно;
/// задержки — одна тихая нота в начале фазы.
List<MelodyNote> notesForPhase(PhaseKind kind, int durMs) {
  switch (kind) {
    case PhaseKind.holdIn:
      return [(offsetMs: 0, scaleIndex: _holdHighIndex, gain: 0.30)];
    case PhaseKind.holdOut:
      return [(offsetMs: 0, scaleIndex: _holdLowIndex, gain: 0.25)];
    case PhaseKind.inhale:
    case PhaseKind.exhale:
      final k = (durMs / 1000).round().clamp(2, harpScaleSize);
      final step = durMs / k;
      return [
        for (var j = 0; j < k; j++)
          (
            offsetMs: (j * step).round(),
            scaleIndex: kind == PhaseKind.inhale ? j : k - 1 - j,
            gain: 0.8,
          ),
      ];
  }
}
