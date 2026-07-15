/// Фразы техники «Фикр» (№10): мысленное повторение, синхронное дыханию —
/// одна фраза на вдохе, другая на выдохе. Аффирмации на выбор (решение
/// владельца): никаких религиозных упоминаний, только светская подача.
///
/// Тексты — ARB-ключи `fikr_<id>_in` / `fikr_<id>_ex` (см. FikrTexts в
/// lib/l10n/technique_texts.dart); доменный слой хранит только id.
library;

/// Пара фраз «вдох/выдох», повторяемая весь сеанс.
class FikrPhrase {
  final String id;

  const FikrPhrase(this.id);
}

/// «Своя фраза» владельца — тексты в CustomFikrPhraseStore; не входит в
/// список [fikrPhrases].
const String customFikrPhraseId = 'custom';

/// Каталог пар в порядке отображения. Первая пара — дефолт;
/// глобальный дефолт — [defaultFikrPhrase].
const List<FikrPhrase> fikrPhrases = [
  FikrPhrase('calm'),
  FikrPhrase('presence'),
  FikrPhrase('light'),
  // Созерцательные пары от владельца (2026-07-15): длинная фраза на вдохе,
  // её раскрытие на выдохе. first_light и heart_waves — авторские формулировки
  // владельца (практиковались на берегу), wave_ocean — в том же духе.
  FikrPhrase('first_light'),
  FikrPhrase('heart_waves'),
  FikrPhrase('wave_ocean'),
  // Собственные пары в том же духе (2026-07-15, «придумай своё»):
  // море/тишина/отдача — темы бренда (Штиль…Прибой) и философии школы.
  FikrPhrase('shore'),
  FikrPhrase('gift'),
  FikrPhrase('stillness'),
  FikrPhrase('sky_mind'),
];

/// Дефолтная пара.
const FikrPhrase defaultFikrPhrase = FikrPhrase('calm');

/// Пара по id; неизвестный/устаревший id из сохранений — дефолт (правило
/// формата: старые данные переживают эволюцию, как в TechniqueSettings).
FikrPhrase fikrPhraseById(String? id) => fikrPhrases.firstWhere(
      (p) => p.id == id,
      orElse: () => defaultFikrPhrase,
    );
