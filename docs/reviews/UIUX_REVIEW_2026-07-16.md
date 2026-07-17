# UI/UX-аудит «Дыши» — 2026-07-16

**Ветка обзора:** `review/uiux-2026-07-16` (от `feat/hant-theme`).
**Тип работы:** ревью без изменений кода приложения. Единственный артефакт — этот отчёт.

## Методика и охват

- Прочитаны исходники всех пользовательских экранов (`lib/features/**`), система иконок
  (`lib/ui/icons/**`, `lib/features/catalog/technique_icons.dart`), обе темы
  (`lib/app/theme.dart` классическая, `lib/app/hant_theme.dart` HANT) и HANT-фон
  (`lib/ui/hant/hant_backdrop.dart`), дыхательный пейнтер (`lib/features/session/breathing_painter.dart`).
- Оценка иконок — по SVG-путям (viewBox 24×24): визуальный вес/плотность штриха, заполнение
  вьюбокса, число под-путей, стилистическая согласованность в наборе Tabler.
- Оценка UX — иерархия, консистентность отступов/радиусов/типографики, доступность (контраст,
  семантика, размеры целей нажатия), тексты. Каждая находка: `файл:строка` → суть → почему
  проблема → предложение.
- Ранжирование: **High** (бьёт по восприятию/доступности/цельности сразу), **Medium** (заметная
  несогласованность), **Low** (полировка).
- Сборки/тесты не запускались (по заданию). Flutter в `C:\src\flutter\bin\flutter.bat`.

Приложение поддерживает **две темы**: классическую (Material 3 из seed-цвета, светлая/тёмная) и
HANT (техно-мистика, только тёмная, `ThemeExtension<HantStyle>`). Ключевой риск цельности — HANT
задаёт токены через расширение темы, но многие экраны рисуют декор мимо `Theme`/`CardTheme` и
жёстко зашитыми цветами; см. раздел 4.

---

## 1. Единообразие иконок дыханий (запрос владельца)

**Источник:** `lib/ui/icons/breathin_icons.dart` (43 набора путей Tabler), маппинг
`lib/features/catalog/technique_icons.dart`, рендер `lib/ui/icons/breathin_icon.dart`
(штрих 2/24, `StrokeCap.round`, `StrokeJoin.round`, цвет от темы).

Все иконки — из одного семейства Tabler (штрих-стиль, скруглённые концы), это правильная база.
Но «вразнобой» — про **визуальный вес и заполнение вьюбокса**: техники в одной сетке главного
экрана стоят рядом, и глаз ловит, что одни иконки «жирные и плотные», другие — «тонкие и мелкие».
Ниже — конкретные выпадения (иконки техник, т.е. те, что реально стоят в каталоге через
`iconDataFor`).

### High — сильные выпадения по весу/заполнению

- **`snowflake` (снежинка, Вим Хоф) — `breathin_icons.dart:68-81`.** 12 под-путей, множество
  коротких отрезков → при 28 px в круге каталога выглядит как плотный «ёжик»: самая «тяжёлая»
  и самая мелко-детальная иконка набора. Рядом с ней `wind`/`ripple` (3 плавные линии) кажутся
  почти пустыми. Это первое, что бросается в глаза в группе «Энергия». **Предложение:**
  снежинка Tabler семантически идеальна, но визуально перегружена — она диктует «потолок
  плотности». Ориентир для всех иконок — её НЕ превышать; а тонкие (`energyWave`, `ripple`,
  `wind`) подтянуть по заполнению (см. ниже, приём `visualScale`).

- **`energyWave` (Энерговолна) — `breathin_icons.dart:301-303`.** Один путь — вертикальный
  серпантин `M12 21c-3 -1.5 -3 -4.5 0 -6...`. Занимает лишь **центральную вертикальную полосу**
  вьюбокса (x≈9…15 из 24), по бокам пусто. На фоне соседей, заполняющих 3–20 по ширине, читается
  как тонкая ниточка по центру → визуально «легче всех» и смещённая. **Почему проблема:** самая
  свежая иконка (каталог 23) не выровнена по оптическому весу с набором. **Предложение:**
  либо расширить фигуру по горизонтали (взять шире по вьюбоксу), либо задать ей `visualScale`
  1.15 на рендере. В терминах набора — это анти-полюс к снежинке; между ними разброс веса
  максимальный.

- **`heartbeat` (когерентное) — `breathin_icons.dart:62-65`.** Владелец прямо указал:
  «сердце с пульсом» — плотный контур. Действительно, сердце (крупная замкнутая кривая, залитый
  силуэт по восприятию) + пульс-линия = высокая площадь тёмного → на фоне линейных «ветра»/«ряби»
  выглядит как заполненный знак, а не контурный. **Предложение:** это осознанный Tabler-микс
  контур+линия; допустимо оставить, но зафиксировать в «правиле веса» как верхнюю границу
  плотности замкнутых фигур.

### Medium — умеренные выпадения

- **`sparkles` (девять очищающих) — `breathin_icons.dart:266-268`** и **`star` (избранное) —
  `271-273`.** Обе — крупные почти-залитые звёздчатые фигуры (одна кривая, большая площадь).
  `sparkles` при этом рисует «большую 6-конечную искру + 2 маленькие» → плотный левый-нижний угол,
  разрежённый верх-право. Асимметрия заполнения заметна рядом с центрированными иконками.
- **`circles` (по элементам) — `breathin_icons.dart:238-242`** — три средних окружности треугольником,
  оптически «крупная» и «воздушная» одновременно; вес нормальный, но радиус кругов (3.5) даёт
  ощущение бо́льшего размера, чем у соседей. Пограничный случай.
- **`lungs` (диафрагмальное) — `84-89`** — 4 под-пути, средне-плотная; ок, но одна из более
  «занятых» — держать в уме при выравнивании.
- **`settings`/`sun`** используют многолучевую симметрию — вместе со `snowflake` задают «плотный»
  полюс; всё, что тоньше половины их штриховой площади, будет казаться «пустым».

### Low — чистота данных набора

- **Оторванный docstring — `breathin_icons.dart:244-245`.** Комментарий
  «`/// Все иконки набора (для тестов парсинга).`» стоит **над** `quote`, а сам список `all`
  объявлен ниже (305). Docstring оторван от объявления — при чтении путает. Косметика.
- **`music` (`105-110`)** помечена «резерв для звуковых наборов (этап 3)» и не используется в
  `iconDataFor` — «спящий» набор в общем списке. Не проблема отрисовки, но чистота набора.

### «Формула веса» (практический вывод раздела)

- Ввести ориентир (в docstring набора): «иконка заполняет ~60–75% площади bounding-box вьюбокса,
  штрих 2/24, без экстремумов плотности». Кандидаты «подтянуть вверх» (слишком лёгкие):
  `energyWave`, `wind`, `ripple`, `waveSine`, `rotate`, `trendingDown`. Кандидаты «не перегружать»:
  `snowflake`, `settings`, `sun`, `heartbeat`, `sparkles`.
- **Приём без перерисовки путей:** сейчас `BreathinIcon` (`breathin_icon.dart:46-64`) масштабирует
  путь ровно `canvasSize/24`. Ввести необязательный `visualScale` в `BreathinIconData`
  (1.0 по умолчанию; 1.1–1.15 для «худых» — `energyWave`, `wind`, `ripple`) и применять его
  внутри `_BreathinIconPainter.paint` дополнительным `canvas.scale` вокруг центра вьюбокса.
  Тонкие иконки станут чуть крупнее в том же круге, вес выровняется. Это правка **рендера**,
  не путей — дёшево, обратимо, не трогает семантику Tabler.

> Итог по разделу: набор стилистически один (Tabler-штрих), «вразнобой» = разброс **оптического
> веса и заполнения вьюбокса**. Полюса: `snowflake`/`settings`/`sun` (плотные) ↔
> `energyWave`/`wind`/`ripple` (тонкие). Приоритет — подтянуть `energyWave` (свежая, центр-полоса)
> и общее правило веса; технически проще всего — per-icon `visualScale` в рендере.

---

## 2. Унификация дублирующихся UI-модулей (запрос владельца)

Приложение выросло экран за экраном, и один и тот же визуальный модуль свёрстан заново вручную
в 4–6 местах каждый. Ниже — карта дублей, затем предлагаемая «общая формула» (виджеты в `lib/ui/`),
затем план миграции по файлам.

### 2.1. Карта дублирующихся модулей

**A. Иконка-в-круге (`CircleAvatar`/`Container` с `primaryContainer`).** Одна и та же связка
«круг фона + `BreathinIcon` цвета onPrimaryContainer» продублирована:
- `home_screen.dart:282-290` — быстрый старт (radius 22, primary).
- `home_screen.dart:421-433` — карточка техники в сетке (radius 28, primaryContainer/surface для dimmed).
- `technique_card_screen.dart:99-107` — крупная иконка карточки (radius 48).
- `welcome_screen.dart:34-42` — приветствие (radius 36).
- `account_section.dart:228-231` — аватар-инициал (дефолтный CircleAvatar).
Пять разных `radius`/цветовых веток, один и тот же смысл. Плюс `_finishedFigure`
(`session_view.dart:200-216`) — по сути тот же «глиф-в-круге», но `Container`+`BoxDecoration`.

**B. Заголовок секции (primary, bold, titleSmall/titleMedium).** Приватный `_SectionHeader`
объявлен ЗАНОВО в каждом файле, местами с разным `textTheme`:
- `session_setup_screen.dart:756-771` — titleSmall + primary + w600.
- `technique_card_screen.dart:279-293` — titleMedium + bold (иной вес!).
- `bolt_test_screen.dart:408-426` (`_Section`) — titleSmall + primary + w600.
- `timer_setup_screen.dart` / `wim_hof_setup_screen.dart` — инлайн в `_SliderTile` (titleSmall+primary+w600).
- В `stats_screen.dart`/`settings_screen.dart` заголовки секций — инлайн `Text(..., titleSmall)`
  БЕЗ primary-окраски (ещё один вариант). Итого 3+ несогласованных стиля «заголовок секции».

**C. Строка «метка · значение · слайдер» (`_SliderTile`).** Дословно продублирована —
`timer_setup_screen.dart:182-218` и `wim_hof_setup_screen.dart:161-197` (комментарий в коде
прямо признаёт: «класс там приватный, поэтому продублирован»). В `session_setup_screen.dart`
слайдеры фаз собраны инлайн ещё третьим способом (`_buildPhaseSliders`).

**D. Список-строка «иконка + заголовок + подзаголовок + шеврон» (тап-карточка).**
- `home_screen.dart:257-322` — `_QuickStartCard`.
- `home_screen.dart:326-379` — `_StreakBanner` (иконка+число+подпись+шеврон).
- `stats_screen.dart:181-236` — `_BoltEntryCard`.
- `stats_screen.dart:459-558` — строки `_ByTechnique._row` (иконка+заголовок+подпись+значение).
- `settings_screen.dart:244-267` — ListTile «leading иконка + title + trailing шеврон» ×3.
- `update_section.dart:39-70` — карточка обновления (иконка+заголовок+подпись+кнопка).
Один паттерн, шесть верстаний.

**E. Пустое/гейт-состояние «крупная иконка 56 + текст (+ CTA)».**
- `challenges_screen.dart:126-199` (`_SignInGate`), `203-234` (`_EmptyState`),
  `238-279` (`_ErrorState`) — ТРИ почти идентичных виджета в одном файле (иконка trophy 56 +
  текст + опц. кнопка).
- `stats_screen.dart:238-269` (`_Empty`) — иконка calendar 56 + текст.
Пять копий одной композиции.

**F. Экран финиша.** Три разных дизайна одного момента «сессия завершена» (см. §3, High).

### 2.2. Предлагаемая «общая формула» (виджеты в `lib/ui/`)

Эскиз API (имена/параметры; рисуют ТОЛЬКО через `Theme`, поэтому автоматически подхватывают HANT):

```dart
// lib/ui/widgets/icon_badge.dart
/// Иконка в круге. Единая замена всем CircleAvatar+BreathinIcon.
/// Варианты нужны для dimmed (stage2) и «крупная карточка».
class IconBadge extends StatelessWidget {
  final BreathinIconData icon;
  final double radius;            // 22 / 28 / 36 / 48 — как сейчас
  final bool dimmed;              // surfaceContainerHighest вместо primaryContainer
  final Color? background;        // переопределение (элементные цвета)
  const IconBadge(this.icon, {this.radius = 24, this.dimmed = false, this.background});
}

// lib/ui/widgets/section_header.dart
/// Единый заголовок секции: titleSmall + colorScheme.primary + w600.
class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader(this.title, {super.key});
}

// lib/ui/widgets/slider_tile.dart
/// Строка «метка — значение — слайдер». Забирает дубль из timer/wim_hof/setup.
class SliderTile extends StatelessWidget {
  final String label; final String value; final Widget slider;
}

// lib/ui/widgets/list_action_card.dart
/// Тап-карточка: [leading] иконка-бейдж, title, subtitle, [trailing] (шеврон/кнопка).
class ListActionCard extends StatelessWidget {
  final Widget leading; final String title; final String? subtitle;
  final Widget? trailing;  // default: chevron
  final VoidCallback? onTap;
  final Color? color;      // primaryContainer для стрика, secondaryContainer для BOLT
}

// lib/ui/widgets/empty_state.dart
/// Заглушка/гейт: крупная иконка + сообщение + опц. набор действий.
class EmptyState extends StatelessWidget {
  final BreathinIconData icon; final String message;
  final List<Widget> actions;   // 0..2 полноширинные кнопки
}

// lib/ui/widgets/session_finish.dart  (см. §3)
/// Единый финиш: круг-«галочка» + заголовок + опц. тело (результаты ВХ) + подсказка тапа.
class SessionFinish extends StatelessWidget {
  final String title; final Widget? body; final VoidCallback onClose;
}
```

### 2.3. План миграции по файлам (порядок = от дешёвого к сложному)

| Модуль | Новый виджет | Файлы-потребители | Размер правки |
|---|---|---|---|
| Заголовок секции | `SectionHeader` | session_setup, technique_card, bolt, timer_setup, wim_hof_setup, stats, settings | S — удалить 3 приватных класса, заменить вызовы; свести вес к одному |
| Слайдер-строка | `SliderTile` | timer_setup, wim_hof_setup (+ опц. session_setup) | S — вынести дубль, 2 файла |
| Иконка-в-круге | `IconBadge` | home ×2, technique_card, welcome, stats `_row`, account | M — 6 мест, разные radius/dimmed |
| Тап-карточка | `ListActionCard` | home (quick/streak), stats (bolt/row), settings ×3, update_section | M — унести стили, проверить color-ветки |
| Пустое состояние | `EmptyState` | challenges ×3, stats `_Empty` | M — свести 4 копии, actions 0..2 |
| Финиш | `SessionFinish` | session_view, timer_session, wim_hof_session | L — визуальное решение (§3), 3 экрана |

Рекомендация: делать партиями по одному модулю (см. сводный план в конце) — каждая партия
самодостаточна, тайп-чекер после удаления приватного класса перечислит все места использования.

---

## 3. Общий UX-аудит экранов

### High

- **Три несогласованных экрана финиша.** Один и тот же момент «готово» выглядит по-разному:
  counted (`session_view.dart:190-223`) — круг 240 px `primaryContainer` с ТЕКСТОВЫМ глифом «✓»
  (`displayLarge`); таймер (`timer_session_screen.dart:508-544`) — иконка `circleCheck` 96 px
  `primary` + заголовок + подсказка; Вим Хоф (`wim_hof_session_screen.dart:457-577`) — вообще без
  фигуры, только текст-результаты. **Почему проблема:** финиш — «дофаминовая точка» (влад. §14),
  а пользователь видит три разных завершения в одном приложении → ощущение несобранности.
  **Предложение:** единый `SessionFinish` (§2.2): общая круг-галочка + заголовок + опц. тело
  (у ВХ — таблица задержек в теле, у остальных — пусто) + подсказка тапа. Заодно решить глиф:
  сейчас counted рисует юникод-«✓» шрифтом, а таймер — векторный `circleCheck` — свести к одному
  (лучше `circleCheck`, консистентно с набором).

- **Дублирующая надпись «Начать сессию» на карточке техники.** `technique_card_screen.dart:188-198`:
  круглая кнопка-рябь (её `Semantics.label = l.startSession`) и СРАЗУ под ней ещё `Text(l.startSession)`.
  Двойная подпись одного действия. Для disabled-состояния ниже добавляется третий текст
  (`comingSoonStage2`). **Почему проблема:** визуальный шум, кнопка и так подписана семантикой.
  **Предложение:** оставить одну подпись (под кнопкой) либо убрать текст, если кнопка узнаваема.

- **Контраст залитых ячеек календаря.** `stats_screen.dart:434,448-451`: заливка дня —
  `primary.withValues(alpha: 0.30…1.0)`, а текст переключается на `onPrimary` только при `alpha>0.6`.
  В диапазоне alpha 0.30–0.60 текст остаётся `onSurface` поверх полупрозрачного primary → на светлой
  теме бирюза 30–60 % под тёмным текстом читается, но на грани; в HANT (primary — янтарь) тёмный
  текст на 40 % янтаре рискует упасть ниже 4.5:1. **Предложение:** зафиксировать порог переключения
  цвета текста по фактической яркости фона, либо не опускать alpha ниже 0.35 и раньше переключать текст.

### Medium

- **Непоследовательная кнопка «Стоп» vs основной CTA.** В сессиях «Стоп» — `FilledButton.tonal`
  (`session_view.dart:142`, timer `:484`, wim_hof `:381`), а в ВХ на задержке основное действие
  «Вдохнуть» — обычный `FilledButton` (`wim_hof_session_screen.dart:445`). Разнобой уровней
  акцента кнопок между режимами. Ок по логике, но стоит свериться, что «Стоп» везде одного веса.

- **Заголовки секций разного веса.** Как отмечено в §2.1-B: `technique_card` рисует заголовок
  `titleMedium+bold`, а setup/bolt — `titleSmall+primary+w600`, а settings/stats — `titleSmall`
  вовсе без primary. Три визуально разных «заголовка секции» в одном приложении. Свести к `SectionHeader`.

- **Радиусы карточек: тема против ручных значений.** `CardTheme` даёт радиус 20 (классика) / 10
  (HANT), но ручные декорации его не наследуют: `hant_backdrop`-независимые `Container` с
  `BorderRadius.circular(...)` — coach-mark пузырёк 12 (`coach_mark.dart:119`), hint-пилюля 20
  (`tap_pause_hint.dart:66`), прогресс-бар 8 (`session_view.dart:320`), welcome-диалог 24
  (`welcome_screen.dart:27`). Набор радиусов 8/12/16/20/24 без системы. **Предложение:** ввести
  токены радиусов (напр. `AppRadii.sm=12, md=16, lg=20`) и свести значения.

- **Размер цели нажатия «Закрыть» у coach-mark.** `coach_mark.dart:141-148` — «Понятно ✕» это
  просто `Text` внутри общего `GestureDetector` пузырька; отдельной кнопки-цели нет. Тап по всему
  пузырьку закрывает — ок функционально, но «✕» выглядит как отдельная кнопка, а цель у неё — весь
  пузырёк. Мелкая неоднозначность аффорданса.

- **Дизейбл-цвет «следующего месяца».** `stats_screen.dart:351` — стрелка вперёд при недоступности
  красится `outlineVariant`. На тёмных темах `outlineVariant` малоконтрастен → «выключено» читается,
  но кнопка почти сливается. Приемлемо.

### Low

- **`Transform.flip` для «назад-стрелки месяца».** `stats_screen.dart:334-337` — зеркалит
  `chevronRight` вместо использования honest «chevron-left». В наборе есть `arrowLeft`, но нет
  `chevronLeft`; добавить парный `chevronLeft` в набор чище, чем flip. Косметика.
- **`_energizingSun`/звезда/огонёк — магическая константа `0xFFF9A825`** повторена в
  `technique_card_screen.dart:20`, `home_screen.dart:460,504`, `wim_hof_session_screen.dart:488`.
  Вынести в тему/константу (см. §4 — в HANT это должен быть `source`/`amber`).
- **Глиф «✕» в тексте coach-mark и «✓» на финише** — юникод-символы в тексте (осознанно, не эмодзи).
  Консистентности ради лучше векторные из набора (`playerStop`? нет; можно ввести `x`/`check`).
  Низкий приоритет.
- **Пустое состояние stats при первом входе** показывает BOLT-карточку + `_Empty` (calendar 56),
  тогда как challenges пустое — trophy 56. После унификации `EmptyState` оба станут единообразны.

---

## 4. Целостность темы HANT (ветка feat/hant-theme)

HANT задаёт палитру через `ColorScheme` + `ThemeExtension<HantStyle>` и рисует фон
`HantBackdrop` и «прицел» в `breathing_painter.dart`. Механизм правильный: всё, что берёт цвета
из `Theme.of(context).colorScheme`, переключается автоматически. Проблема — **места, которые
рисуют мимо темы** (жёсткие цвета, ручные декорации) и **экраны без `HantBackdrop`**. Ниже —
конкретика.

### High

- **Нет переключателя темы в UI.** `AppUiTheme`/`UiThemeStore`/`uiThemeNotifier` заведены и
  прокинуты в `app.dart:130-151`, гидрируются в `main.dart:20`, но **ни один экран не даёт
  сменить тему** — в `settings_screen.dart` секции выбора интерфейса нет. То есть на ветке HANT
  включить нельзя иначе как правкой prefs. **Предложение:** добавить в настройки секцию «Интерфейс»
  (SegmentedButton Классический/HANT), сохраняющую через `UiThemeStore` и толкающую `uiThemeNotifier`.
  Без этого тема недоступна пользователю.

- **`HantBackdrop` подключён только на 2 экранах.** Фон-«чертёж» оборачивает лишь тело главного
  (`home_screen.dart:163`) и сессии (`session_view.dart:156`). Остальные экраны в HANT останутся
  с плоским `scaffoldBackgroundColor` без сетки/звёзд: карточка техники, оба setup, таймер-сессия,
  Вим Хоф, статистика, челленджи, настройки, BOLT. **Почему проблема:** «приборная панель»
  появляется и исчезает при переходах → тема выглядит наполовину внедрённой. **Предложение:**
  обернуть `Scaffold.body` в `HantBackdrop` на всех полноэкранных маршрутах (в классике он
  прозрачен — регресса нет). Дёшево: один враппер на экран.

- **Финиш-экраны рисуют мимо HANT.** `session_view.dart:200-216` — `Container` круг
  `primaryContainer` (в HANT это тёмно-янтарный `0xFF33250E` → мутное коричневое пятно, а не
  «источник»). Таймер-финиш и ВХ-финиш — то же семейство. Прицельная фигура сессии в HANT
  красивая (`breathing_painter._paintReticle`), а финиш выпадает из стиля. **Предложение:** в
  `SessionFinish` (§2/§3) для HANT рисовать круг-«источник» токенами `HantStyle` (янтарное ядро +
  циан-контур), как дышащая фигура; ветка по `theme.extension<HantStyle>()`.

### Medium

- **Жёсткие цвета мимо темы (в HANT выпадут).**
  - Солнце/звезда/огонёк `Color(0xFFF9A825)` — `technique_card_screen.dart:20`, `home_screen.dart:460,504`,
    `wim_hof_session_screen.dart:488`. В HANT «бодрящее» солнце должно быть `source`/`amber`
    (`0xFFF0A63C`), звезда избранного — тоже амбер-акцент. Сейчас будет чужой золотой.
  - Цвета стихий `elementColor` (`segment_labels.dart:49-70`) — 8 фиксированных ярких цветов
    (земля/вода/огонь…). На космическом фоне HANT они «мультяшные». Пограничный случай: стихии —
    смысловая палитра, возможно оставить; но проверить контраст на `bg 0xFF070C16`.
  - Safety-карточки: high — `errorContainer` (тема даёт), medium — `AppTheme.warningContainer(b)`
    (`technique_card_screen.dart:323-337`) — **амбер жёстко из `AppTheme`, HANT-варианта нет**.
    В HANT medium-предупреждение возьмёт светло-жёлтый `AppTheme` вместо своего янтаря → чужой тон.
    **Предложение:** увести warning-пару в тему (или дать HANT-ветку в `warningContainer`).

- **`CircleAvatar` с `primaryContainer` в HANT — мутный.** Все бейджи-иконки (§2.1-A) на фоне
  `primaryContainer 0xFF33250E` (тёмно-коричневый) с `onPrimaryContainer 0xFFFFD9A0` (кремовый).
  Смотрится приглушённо-коричневым, тогда как стиль HANT — циан-контур/янтарное ядро. **Предложение:**
  в `IconBadge` дать HANT-ветку: прозрачный фон + тонкий циан-контур (`wireDim`) + иконка `wire`/`source`,
  как «HUD-чип». Тогда бейджи станут частью приборной эстетики.

- **Стрик-баннер и BOLT-карточка — цветные контейнеры.** `home_screen.dart:337`
  (`primaryContainer`) и `stats_screen.dart:190` (`secondaryContainer`). В HANT это тёмно-янтарный
  и тёмно-циановый — в принципе в палитре, но без wire-контура/HUD-рамки выглядят как простые
  заливки, не как элементы «панели». После `ListActionCard` с HANT-веткой (контур `wireDim`) впишутся.

- **`_StartRipplePainter` (кнопка старта).** `technique_card_screen.dart:416-440` — рисует рябь
  цветом `scheme.onPrimary`/`primary`. В HANT `primary`=амбер, `onPrimary`=тёмный — рябь будет
  тёмной на янтарном круге. Технически работает, но по стилю HANT кнопка-CTA — это «источник»
  (янтарь+свечение); можно дать ей HANT-ветку с `sourceGlow`. Опционально.

### Low

- **AppBar-титулы в HANT — моно-капс с трекингом** (`hant_theme.dart:153`, spacing 3.5). Экраны
  setup кладут в `AppBar.title` двухстрочный `Column` (`session_setup_screen.dart:178-190` и др.)
  с `titleMedium`/`bodySmall` — эти строки НЕ получат моно-HUD-стиль (они не `titleTextStyle`).
  В HANT шапка setup будет обычным шрифтом, а прочие экраны — моно-капсом → лёгкий разнобой шапок.
  Проверить визуально; при желании дать под-строке `labelSmall` (моно).
- **`snackBarTheme` HANT задан**, но контент-текст `GolosText` — ок; проверить, что снекбары
  ошибок аккаунта (`account_section.dart:64`) читаемы на `surfaceHigh`.
- **Дивайдеры/`outlineVariant`** в HANT заданы (`0xFF1B3A52`) — тёмно-синие, ок; но `LinearProgressIndicator`
  (сессия/челленджи) берёт `primary` (амбер) на треке `secondaryContainer`? Проверить трек-цвет
  прогресса на космическом фоне.

---

## Сводный план внедрения (партиями по 3–4 правки — спека для агентов-исполнителей)

Каждая партия самодостаточна и коммитится отдельно. Порядок — от дешёвого/безопасного к сложному.
Правки НЕ меняют поведение, только унифицируют отрисовку; после каждой — `svelte-check`-аналог:
`C:\src\flutter\bin\flutter.bat analyze` (тайп-чекер перечислит забытые вызовы после удаления
приватных классов).

**Партия 1 — общие мелкие виджеты (низкий риск).**
1. Создать `lib/ui/widgets/section_header.dart` (`SectionHeader`, titleSmall+primary+w600);
   заменить `_SectionHeader`/`_Section` в session_setup, technique_card, bolt, timer_setup,
   wim_hof_setup; заголовки-`Text` в stats/settings перевести на него (свести вес к одному).
2. Создать `lib/ui/widgets/slider_tile.dart` (`SliderTile`); убрать дубль из timer_setup и
   wim_hof_setup.
3. Вынести константу акцента `kAccentAmber` (или через тему) и заменить `Color(0xFFF9A825)` в
   technique_card, home ×2, wim_hof_session.

**Партия 2 — иконка-в-круге + HANT-ветка.**
1. Создать `lib/ui/widgets/icon_badge.dart` (`IconBadge` с `radius`/`dimmed`/`background` и
   HANT-веткой: контур `wireDim`, иконка `wire`).
2. Мигрировать home ×2, technique_card (radius 48), welcome, stats `_row`, account на `IconBadge`.
3. Проверить в обеих темах (классика — как было; HANT — HUD-чип вместо коричневого круга).

**Партия 3 — тап-карточка и пустые состояния.**
1. Создать `lib/ui/widgets/list_action_card.dart` (`ListActionCard`) и `lib/ui/widgets/empty_state.dart`
   (`EmptyState`, actions 0..2).
2. Мигрировать `_QuickStartCard`/`_StreakBanner` (home), `_BoltEntryCard`/`_ByTechnique._row` (stats),
   settings ListTiles, update_section на `ListActionCard`.
3. Свести `_SignInGate`/`_EmptyState`/`_ErrorState` (challenges) и `_Empty` (stats) в `EmptyState`.

**Партия 4 — единый финиш + HANT-целостность.**
1. Создать `lib/ui/widgets/session_finish.dart` (`SessionFinish`: круг-`circleCheck` + заголовок +
   опц. тело + подсказка тапа; HANT-ветка — «источник» токенами `HantStyle`).
2. Заменить финиши в session_view, timer_session, wim_hof_session (тело ВХ = таблица задержек).
3. Обернуть `Scaffold.body` в `HantBackdrop` на всех полноэкранных экранах (technique_card, оба
   setup, timer_session, wim_hof, stats, challenges, settings, bolt).

**Партия 5 — тема как настройка + токены (замыкающая).**
1. Добавить в `settings_screen.dart` секцию «Интерфейс» (SegmentedButton Классический/HANT →
   `UiThemeStore` + `uiThemeNotifier`).
2. Ввести токены радиусов (`AppRadii`) и свести ручные `BorderRadius.circular(8/12/16/20/24)`.
3. Увести warning-пару (medium-safety) в тему с HANT-веткой; проверить контраст ячеек календаря
   и элементных цветов на фоне HANT `bg`.

**Партия 6 — полировка иконок (по §1).**
1. Ввести `visualScale` в `BreathinIconData` + применить в `_BreathinIconPainter`.
2. Задать `visualScale` 1.1–1.15 «худым» (`energyWave`, `wind`, `ripple`, `waveSine`); при
   необходимости расширить путь `energyWave` по горизонтали.
3. Добавить парный `chevronLeft` в набор, заменить `Transform.flip` в stats.

> Итог: главные рычаги цельности — (а) единый финиш, (б) `HantBackdrop` на всех экранах,
> (в) переключатель темы в настройках, (г) `IconBadge`/`ListActionCard`/`EmptyState`/`SectionHeader`
> как «общая формула». Разброс веса иконок (§1) — отдельная полировочная партия; технически
> дешевле всего решается per-icon `visualScale` в рендере, без перерисовки путей Tabler.

