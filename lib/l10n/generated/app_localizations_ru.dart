// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Дыши';

  @override
  String get tech_box_name => 'Квадратное дыхание';

  @override
  String get tech_box_desc =>
      'Классическая техника: вдох, задержка, выдох и повторная задержка — каждая фаза одинаковой длины, по умолчанию 4 секунды. Визуально образует квадрат: мысленно «обходите» его углы, удерживая ритм. Подходит для начинающих и регулярной практики в любой обстановке.';

  @override
  String get tech_box_benefit =>
      'Быстро снижает стресс и тревогу, восстанавливает концентрацию, успокаивает нервную систему за счёт равномерного ритма дыхания.';

  @override
  String get tech_triangle_name => 'Треугольное дыхание';

  @override
  String get tech_triangle_desc =>
      'Трёхфазная техника: вдох — задержка — выдох без второй паузы. Паттерн образует треугольник: плавный, но с элементом задержки. Длительность каждой фазы настраивается от 2 до 10 секунд.';

  @override
  String get tech_triangle_benefit =>
      'Мягко успокаивает ум и снимает напряжение, является хорошей подготовкой перед более продвинутыми практиками с задержками.';

  @override
  String get tech_four_seven_eight_name => '4-7-8';

  @override
  String get tech_four_seven_eight_desc =>
      'Техника Эндрю Вейла: вдох на 4 счёта, задержка на 7, медленный выдох на 8. Пропорция фаз фиксирована; доступен выбор множителя темпа (×0.5 / ×0.75 / ×1 / ×1.25) для замедления или ускорения цикла. Новичкам рекомендуется начинать с 4 циклов.';

  @override
  String get tech_four_seven_eight_benefit =>
      'Эффективно снижает тревогу и помогает заснуть: длинная задержка и протяжный выдох активируют парасимпатическую нервную систему.';

  @override
  String get tech_four_two_four_name => '4-2-4';

  @override
  String get tech_four_two_four_desc =>
      'Мягкая балансирующая техника: вдох на 4 счёта, короткая задержка на 2, выдох на 4. Все фазы можно настраивать в диапазоне 2–10 секунд. Доступна и расслабляющая, и тонизирующая акцентировка в зависимости от темпа.';

  @override
  String get tech_four_two_four_benefit =>
      'Балансирует нервную систему, устраняет лёгкое напряжение, подходит для дневной практики в паузах между делами.';

  @override
  String get tech_two_eight_name => '2-8';

  @override
  String get tech_two_eight_desc =>
      'Техника удлинённого выдоха с соотношением 1:4 — короткий вдох на 2 секунды и длинный выдох на 8. Соотношение фаз можно сохранять или менять независимо. Не требует задержек, проста в освоении.';

  @override
  String get tech_two_eight_benefit =>
      'Длинный выдох напрямую активирует парасимпатическую нервную систему, снимает физическое и эмоциональное напряжение, способствует расслаблению.';

  @override
  String get tech_two_ten_name => '2-10';

  @override
  String get tech_two_ten_desc =>
      'Более глубокая версия техники 2-8 с соотношением 1:5 — вдох на 2 секунды, выдох на 10. Выдох ещё более протяжный, что усиливает расслабляющий эффект. Соотношение фаз регулируется.';

  @override
  String get tech_two_ten_benefit =>
      'Выраженная активация парасимпатики и глубокое расслабление: подходит для снятия сильного стресса и подготовки ко сну.';

  @override
  String get tech_four_sixteen_eight_name => '4-16-8';

  @override
  String get tech_four_sixteen_eight_desc =>
      'Пранаяма-соотношение 1:4:2 — вдох 4, задержка 16, выдох 8. По умолчанию предлагается упрощённый режим 4-8-8; опытные практикующие могут перейти к полному паттерну. База масштабируется: например, 3-12-6 или 5-20-10. Рекомендуется для тех, кто уже освоил базовые техники. Новичкам — не более 4 циклов.';

  @override
  String get tech_four_sixteen_eight_benefit =>
      'Глубоко тренирует дыхательную систему, развивает задержку дыхания, усиливает концентрацию и энергетический тонус.';

  @override
  String get tech_coherent_name => 'Когерентное дыхание';

  @override
  String get tech_coherent_desc =>
      'Медленное дыхание в темпе около 5–6 циклов в минуту: вдох и выдох одинаковой длины (по умолчанию 5.5 секунды каждый), без задержек. Длительность фаз настраивается от 4 до 7 секунд. Техника мягкая и подходит для длительных сессий.';

  @override
  String get tech_coherent_benefit =>
      'Выравнивает вариабельность сердечного ритма (ВСР), снижает хронический стресс, улучшает баланс симпатической и парасимпатической нервной системы.';

  @override
  String get tech_diaphragmatic_name => 'Диафрагмальное дыхание';

  @override
  String get tech_diaphragmatic_desc =>
      'Свободное дыхание животом по таймеру: дышите глубоко, позволяя животу подниматься на вдохе и опускаться на выдохе — без счёта и задержек. В начале сессии воспроизводится голосовая инструкция. Можно включить мягкий фоновый звук для атмосферы.';

  @override
  String get tech_diaphragmatic_benefit =>
      'Снимает мышечное напряжение, улучшает оксигенацию, обучает правильному паттерну дыхания — основе всех остальных техник.';

  @override
  String get tech_nadi_shodhana_name => 'Нади Шодхана';

  @override
  String get tech_nadi_shodhana_desc =>
      'Попеременное дыхание ноздрями из традиции йоги: поочерёдно закрывая правую и левую ноздрю, вы синхронизируете полушария мозга. Практикуется по таймеру; доступны звуковые подсказки смены ноздри с настраиваемым интервалом или полностью свободный режим.';

  @override
  String get tech_nadi_shodhana_benefit =>
      'Успокаивает ум, улучшает концентрацию и баланс нервной системы, традиционно используется для подготовки к медитации.';

  @override
  String get tech_sound_breath_name => 'Дыхание со звуком';

  @override
  String get tech_sound_breath_desc =>
      'Техника осознанного дыхания с вокализацией (Уджайи) или гудением (Брамари «пчела»). Практикуется по таймеру; в начале — голосовая инструкция. Для Брамари доступны опциональные подсказки «вдох / гудите на выдохе».';

  @override
  String get tech_sound_breath_benefit =>
      'Глубоко успокаивает нервную систему через вибрацию и осознанный звук, снижает тревогу, улучшает фокус и помогает войти в медитативное состояние.';

  @override
  String get tech_wim_hof_name => 'Метод Вима Хофа';

  @override
  String get tech_wim_hof_desc =>
      'Интенсивная техника: раунд состоит из 30–40 глубоких активных дыханий, затем полного выдоха и задержки на пустых лёгких (до появления позыва), затем глубокого вдоха и 15-секундной задержки. Обычно 3–4 раунда. Число дыханий, темп, количество раундов и длительность задержки настраиваются. По завершении показывается время задержек по раундам.';

  @override
  String get tech_wim_hof_benefit =>
      'Повышает устойчивость к стрессу, увеличивает энергетический тонус, улучшает холодовую адаптацию и развивает осознанный контроль над дыхательной системой.';

  @override
  String get safety_low =>
      'Дышите в комфортном темпе. Если почувствуете головокружение или дискомфорт — прервите упражнение и дышите нормально.';

  @override
  String get safety_holds_generic =>
      'Техника содержит задержки дыхания. Небольшое покалывание в конечностях — нормально; головокружение или потемнение в глазах — сигнал остановиться и дышать свободно. Никогда не выполняйте эту технику в воде, за рулём или в любой ситуации, требующей концентрации внимания.';

  @override
  String get safety_intense =>
      'ВАЖНО: никогда не выполняйте эту технику в воде, за рулём, стоя или при управлении механизмами — возможна потеря сознания.\n\nПротивопоказания: беременность, эпилепсия, сердечно-сосудистые заболевания, гипертония, панические расстройства, недавние операции, глаукома. При наличии любого из этих состояний проконсультируйтесь с врачом перед практикой.\n\nНачинайте с 3–4 циклов, постепенно увеличивая нагрузку.';

  @override
  String get startSession => 'Начать';

  @override
  String get comingSoonStage2 => 'Появится в одном из следующих обновлений';

  @override
  String get comingSoonBadge => 'Скоро';

  @override
  String get sectionDescription => 'Описание';

  @override
  String get sectionBenefit => 'Польза';

  @override
  String get sectionSafety => 'Безопасность';

  @override
  String cyclesShort(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n цикла',
      many: '$n циклов',
      few: '$n цикла',
      one: '$n цикл',
    );
    return '$_temp0';
  }

  @override
  String minutesShort(int n) {
    return '$n мин';
  }

  @override
  String roundsShort(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n раунда',
      many: '$n раундов',
      few: '$n раунда',
      one: '$n раунд',
    );
    return '$_temp0';
  }

  @override
  String noviceCyclesHint(int n) {
    return 'Новичкам — не более $n циклов';
  }

  @override
  String get settingsTooltip => 'Настройки';

  @override
  String get setupTitle => 'Настройка';

  @override
  String get endModeCycles => 'Циклы';

  @override
  String get endModeTimer => 'Таймер';

  @override
  String get cyclesLabel => 'Количество циклов';

  @override
  String get timerLabel => 'Таймер, мин';

  @override
  String get phasesSection => 'Длительности фаз';

  @override
  String get keepRatioLabel => 'Держать пропорцию';

  @override
  String get simplifiedLabel => 'Упрощённый режим';

  @override
  String get tempoLabel => 'Темп';

  @override
  String get resetToClassic => 'Сбросить к классике';

  @override
  String get feedbackSection => 'Сопровождение';

  @override
  String get channelVoice => 'Голос';

  @override
  String get channelSound => 'Звук';

  @override
  String get channelMetronome => 'Метроном';

  @override
  String get channelVibration => 'Вибрация';

  @override
  String get channelVisual => 'Визуальный режим';

  @override
  String get prepLabel => 'Подготовка, с';

  @override
  String get phaseInhale => 'Вдох';

  @override
  String get phaseHoldIn => 'Задержка';

  @override
  String get phaseExhale => 'Выдох';

  @override
  String get phaseHoldOut => 'Задержка';

  @override
  String secondsShort(String n) {
    return '$n с';
  }

  @override
  String get accountSection => 'Аккаунт';

  @override
  String get signInGoogle => 'Войти через Google';

  @override
  String get signOutAction => 'Выйти';

  @override
  String get accountGuest => 'Гостевой режим';

  @override
  String get accountGuestNote =>
      'Практика и настройки работают без аккаунта. Вход понадобится для друзей и общей ленты.';

  @override
  String get authNotConfiguredNote =>
      'Вход через Google станет доступен в одном из ближайших обновлений.';

  @override
  String get statsTitle => 'Практика';

  @override
  String get statsTooltip => 'Календарь практик';

  @override
  String streakLabel(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'дня подряд',
      many: 'дней подряд',
      few: 'дня подряд',
      one: 'день подряд',
    );
    return '$_temp0';
  }

  @override
  String get monthMinutesLabel => 'минут за месяц';

  @override
  String monthSessionsLabel(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'сессии',
      many: 'сессий',
      few: 'сессии',
      one: 'сессия',
    );
    return '$_temp0';
  }

  @override
  String get statsEmpty =>
      'Пока нет ни одной практики. Начните с любой техники — здесь появится календарь.';

  @override
  String get byTechniqueLabel => 'По техникам';

  @override
  String get createGuestProfile => 'Создать профиль (без регистрации)';

  @override
  String get guestProfileLabel => 'Гостевой профиль';

  @override
  String get nicknameDialogTitle => 'Имя в челленджах';

  @override
  String get signOutAnonWarning =>
      'Гостевой профиль нельзя восстановить после выхода: челленджи и ник будут потеряны. Выйти?';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get linkGoogleAction =>
      'Привязать Google — сохранить профиль навсегда';

  @override
  String get challengesTitle => 'Челленджи';

  @override
  String get challengesTooltip => 'Челленджи с друзьями';

  @override
  String get challengesSignInHint =>
      'Челленджи — соревнование с друзьями: кто больше практикует. Создайте профиль или войдите, чтобы начать.';

  @override
  String get challengesEmpty =>
      'Пока нет челленджей. Создайте свой и пришлите код друзьям — или введите код друга.';

  @override
  String get createChallengeAction => 'Создать челлендж';

  @override
  String get joinByCodeAction => 'Ввести код';

  @override
  String get challengeTitleLabel => 'Название';

  @override
  String get challengeTitleDefault => 'Дышим вместе';

  @override
  String get metricLabel => 'Метрика';

  @override
  String get metricSessions => 'Сессии';

  @override
  String get metricMinutes => 'Минуты';

  @override
  String get metricStreak => 'Дни подряд';

  @override
  String get targetLabel => 'Цель';

  @override
  String get durationLabel => 'Длительность, дней';

  @override
  String get codeFieldLabel => 'Код приглашения';

  @override
  String get codeNotFound => 'Челлендж с таким кодом не найден';

  @override
  String joinedChallenge(String title) {
    return 'Вы присоединились: $title';
  }

  @override
  String challengeCodeShare(String code) {
    return 'Код для друзей: $code';
  }

  @override
  String get codeCopied => 'Код скопирован';

  @override
  String challengeUntil(String date) {
    return 'до $date';
  }

  @override
  String get challengeFinished => 'Завершён';

  @override
  String get commonCreate => 'Создать';

  @override
  String get commonJoin => 'Присоединиться';
}
