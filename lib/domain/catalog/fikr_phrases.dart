/// Фразы техники «Фикр» (№10): мысленное повторение, синхронное дыханию —
/// одна фраза на вдохе, другая на выдохе. Два набора переключателем (решение
/// владельца): нейтральные аффирмации и традиционные вазифы школы Инайят
/// Хана (подача светская — упоминаем школу, без религиозного акцента).
///
/// Тексты — ARB-ключи `fikr_<id>_in` / `fikr_<id>_ex` (см. FikrTexts в
/// lib/l10n/technique_texts.dart); доменный слой хранит только id.
library;

/// Набор фраз: нейтральные аффирмации или традиционные вазифы.
enum FikrPhraseSet { affirmations, wazifa }

/// Пара фраз «вдох/выдох», повторяемая весь сеанс.
class FikrPhrase {
  final String id;
  final FikrPhraseSet set;

  const FikrPhrase(this.id, this.set);
}

/// Каталог пар в порядке отображения. Первая пара каждого набора — дефолт
/// набора; глобальный дефолт — [defaultFikrPhrase].
const List<FikrPhrase> fikrPhrases = [
  FikrPhrase('calm', FikrPhraseSet.affirmations),
  FikrPhrase('presence', FikrPhraseSet.affirmations),
  FikrPhrase('light', FikrPhraseSet.affirmations),
  FikrPhrase('ishq', FikrPhraseSet.wazifa),
  FikrPhrase('shafee', FikrPhraseSet.wazifa),
  FikrPhrase('allah', FikrPhraseSet.wazifa),
];

/// Дефолтная пара — нейтральная аффирмация (светская подача по умолчанию).
const FikrPhrase defaultFikrPhrase = FikrPhrase('calm', FikrPhraseSet.affirmations);

/// Пара по id; неизвестный/устаревший id из сохранений — дефолт (правило
/// формата: старые данные переживают эволюцию, как в TechniqueSettings).
FikrPhrase fikrPhraseById(String? id) => fikrPhrases.firstWhere(
      (p) => p.id == id,
      orElse: () => defaultFikrPhrase,
    );
