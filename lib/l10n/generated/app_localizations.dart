import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'Дыши'**
  String get appTitle;

  /// No description provided for @tech_box_name.
  ///
  /// In ru, this message translates to:
  /// **'Квадратное дыхание'**
  String get tech_box_name;

  /// No description provided for @tech_box_desc.
  ///
  /// In ru, this message translates to:
  /// **'Классическая техника: вдох, задержка, выдох и повторная задержка — каждая фаза одинаковой длины, по умолчанию 4 секунды. Визуально образует квадрат: мысленно «обходите» его углы, удерживая ритм. Подходит для начинающих и регулярной практики в любой обстановке.'**
  String get tech_box_desc;

  /// No description provided for @tech_box_benefit.
  ///
  /// In ru, this message translates to:
  /// **'Быстро снижает стресс и тревогу, восстанавливает концентрацию, успокаивает нервную систему за счёт равномерного ритма дыхания.'**
  String get tech_box_benefit;

  /// No description provided for @tech_triangle_name.
  ///
  /// In ru, this message translates to:
  /// **'Треугольное дыхание'**
  String get tech_triangle_name;

  /// No description provided for @tech_triangle_desc.
  ///
  /// In ru, this message translates to:
  /// **'Трёхфазная техника: вдох — задержка — выдох без второй паузы. Паттерн образует треугольник: плавный, но с элементом задержки. Длительность каждой фазы настраивается от 2 до 10 секунд.'**
  String get tech_triangle_desc;

  /// No description provided for @tech_triangle_benefit.
  ///
  /// In ru, this message translates to:
  /// **'Мягко успокаивает ум и снимает напряжение, является хорошей подготовкой перед более продвинутыми практиками с задержками.'**
  String get tech_triangle_benefit;

  /// No description provided for @tech_four_seven_eight_name.
  ///
  /// In ru, this message translates to:
  /// **'4-7-8'**
  String get tech_four_seven_eight_name;

  /// No description provided for @tech_four_seven_eight_desc.
  ///
  /// In ru, this message translates to:
  /// **'Техника Эндрю Вейла: вдох на 4 счёта, задержка на 7, медленный выдох на 8. Пропорция фаз фиксирована; доступен выбор множителя темпа (×0.5 / ×0.75 / ×1 / ×1.25) для замедления или ускорения цикла. Новичкам рекомендуется начинать с 4 циклов.'**
  String get tech_four_seven_eight_desc;

  /// No description provided for @tech_four_seven_eight_benefit.
  ///
  /// In ru, this message translates to:
  /// **'Эффективно снижает тревогу и помогает заснуть: длинная задержка и протяжный выдох активируют парасимпатическую нервную систему.'**
  String get tech_four_seven_eight_benefit;

  /// No description provided for @tech_four_two_four_name.
  ///
  /// In ru, this message translates to:
  /// **'4-2-4'**
  String get tech_four_two_four_name;

  /// No description provided for @tech_four_two_four_desc.
  ///
  /// In ru, this message translates to:
  /// **'Мягкая балансирующая техника: вдох на 4 счёта, короткая задержка на 2, выдох на 4. Все фазы можно настраивать в диапазоне 2–10 секунд. Доступна и расслабляющая, и тонизирующая акцентировка в зависимости от темпа.'**
  String get tech_four_two_four_desc;

  /// No description provided for @tech_four_two_four_benefit.
  ///
  /// In ru, this message translates to:
  /// **'Балансирует нервную систему, устраняет лёгкое напряжение, подходит для дневной практики в паузах между делами.'**
  String get tech_four_two_four_benefit;

  /// No description provided for @tech_two_eight_name.
  ///
  /// In ru, this message translates to:
  /// **'2-8'**
  String get tech_two_eight_name;

  /// No description provided for @tech_two_eight_desc.
  ///
  /// In ru, this message translates to:
  /// **'Техника удлинённого выдоха с соотношением 1:4 — короткий вдох на 2 секунды и длинный выдох на 8. Соотношение фаз можно сохранять или менять независимо. Не требует задержек, проста в освоении.'**
  String get tech_two_eight_desc;

  /// No description provided for @tech_two_eight_benefit.
  ///
  /// In ru, this message translates to:
  /// **'Длинный выдох напрямую активирует парасимпатическую нервную систему, снимает физическое и эмоциональное напряжение, способствует расслаблению.'**
  String get tech_two_eight_benefit;

  /// No description provided for @tech_two_ten_name.
  ///
  /// In ru, this message translates to:
  /// **'2-10'**
  String get tech_two_ten_name;

  /// No description provided for @tech_two_ten_desc.
  ///
  /// In ru, this message translates to:
  /// **'Более глубокая версия техники 2-8 с соотношением 1:5 — вдох на 2 секунды, выдох на 10. Выдох ещё более протяжный, что усиливает расслабляющий эффект. Соотношение фаз регулируется.'**
  String get tech_two_ten_desc;

  /// No description provided for @tech_two_ten_benefit.
  ///
  /// In ru, this message translates to:
  /// **'Выраженная активация парасимпатики и глубокое расслабление: подходит для снятия сильного стресса и подготовки ко сну.'**
  String get tech_two_ten_benefit;

  /// No description provided for @tech_four_sixteen_eight_name.
  ///
  /// In ru, this message translates to:
  /// **'4-16-8'**
  String get tech_four_sixteen_eight_name;

  /// No description provided for @tech_four_sixteen_eight_desc.
  ///
  /// In ru, this message translates to:
  /// **'Пранаяма-соотношение 1:4:2 — вдох 4, задержка 16, выдох 8. По умолчанию предлагается упрощённый режим 4-8-8; опытные практикующие могут перейти к полному паттерну. База масштабируется: например, 3-12-6 или 5-20-10. Рекомендуется для тех, кто уже освоил базовые техники. Новичкам — не более 4 циклов.'**
  String get tech_four_sixteen_eight_desc;

  /// No description provided for @tech_four_sixteen_eight_benefit.
  ///
  /// In ru, this message translates to:
  /// **'Глубоко тренирует дыхательную систему, развивает задержку дыхания, усиливает концентрацию и энергетический тонус.'**
  String get tech_four_sixteen_eight_benefit;

  /// No description provided for @tech_coherent_name.
  ///
  /// In ru, this message translates to:
  /// **'Когерентное дыхание'**
  String get tech_coherent_name;

  /// No description provided for @tech_coherent_desc.
  ///
  /// In ru, this message translates to:
  /// **'Медленное дыхание в темпе около 5–6 циклов в минуту: вдох и выдох одинаковой длины (по умолчанию 5.5 секунды каждый), без задержек. Длительность фаз настраивается от 4 до 7 секунд. Техника мягкая и подходит для длительных сессий.'**
  String get tech_coherent_desc;

  /// No description provided for @tech_coherent_benefit.
  ///
  /// In ru, this message translates to:
  /// **'Выравнивает вариабельность сердечного ритма (ВСР), снижает хронический стресс, улучшает баланс симпатической и парасимпатической нервной системы.'**
  String get tech_coherent_benefit;

  /// No description provided for @tech_diaphragmatic_name.
  ///
  /// In ru, this message translates to:
  /// **'Диафрагмальное дыхание'**
  String get tech_diaphragmatic_name;

  /// No description provided for @tech_diaphragmatic_desc.
  ///
  /// In ru, this message translates to:
  /// **'Свободное дыхание животом по таймеру: дышите глубоко, позволяя животу подниматься на вдохе и опускаться на выдохе — без счёта и задержек. В начале сессии воспроизводится голосовая инструкция. Можно включить мягкий фоновый звук для атмосферы.'**
  String get tech_diaphragmatic_desc;

  /// No description provided for @tech_diaphragmatic_benefit.
  ///
  /// In ru, this message translates to:
  /// **'Снимает мышечное напряжение, улучшает оксигенацию, обучает правильному паттерну дыхания — основе всех остальных техник.'**
  String get tech_diaphragmatic_benefit;

  /// No description provided for @tech_nadi_shodhana_name.
  ///
  /// In ru, this message translates to:
  /// **'Нади Шодхана'**
  String get tech_nadi_shodhana_name;

  /// No description provided for @tech_nadi_shodhana_desc.
  ///
  /// In ru, this message translates to:
  /// **'Попеременное дыхание ноздрями из традиции йоги: поочерёдно закрывая правую и левую ноздрю, вы синхронизируете полушария мозга. Практикуется по таймеру; доступны звуковые подсказки смены ноздри с настраиваемым интервалом или полностью свободный режим.'**
  String get tech_nadi_shodhana_desc;

  /// No description provided for @tech_nadi_shodhana_benefit.
  ///
  /// In ru, this message translates to:
  /// **'Успокаивает ум, улучшает концентрацию и баланс нервной системы, традиционно используется для подготовки к медитации.'**
  String get tech_nadi_shodhana_benefit;

  /// No description provided for @tech_sound_breath_name.
  ///
  /// In ru, this message translates to:
  /// **'Дыхание со звуком'**
  String get tech_sound_breath_name;

  /// No description provided for @tech_sound_breath_desc.
  ///
  /// In ru, this message translates to:
  /// **'Техника осознанного дыхания с вокализацией (Уджайи) или гудением (Брамари «пчела»). Практикуется по таймеру; в начале — голосовая инструкция. Для Брамари доступны опциональные подсказки «вдох / гудите на выдохе».'**
  String get tech_sound_breath_desc;

  /// No description provided for @tech_sound_breath_benefit.
  ///
  /// In ru, this message translates to:
  /// **'Глубоко успокаивает нервную систему через вибрацию и осознанный звук, снижает тревогу, улучшает фокус и помогает войти в медитативное состояние.'**
  String get tech_sound_breath_benefit;

  /// No description provided for @tech_wim_hof_name.
  ///
  /// In ru, this message translates to:
  /// **'Метод Вима Хофа'**
  String get tech_wim_hof_name;

  /// No description provided for @tech_wim_hof_desc.
  ///
  /// In ru, this message translates to:
  /// **'Интенсивная техника: раунд состоит из 30–40 глубоких активных дыханий, затем полного выдоха и задержки на пустых лёгких (до появления позыва), затем глубокого вдоха и 15-секундной задержки. Обычно 3–4 раунда. Число дыханий, темп, количество раундов и длительность задержки настраиваются. По завершении показывается время задержек по раундам.'**
  String get tech_wim_hof_desc;

  /// No description provided for @tech_wim_hof_benefit.
  ///
  /// In ru, this message translates to:
  /// **'Повышает устойчивость к стрессу, увеличивает энергетический тонус, улучшает холодовую адаптацию и развивает осознанный контроль над дыхательной системой.'**
  String get tech_wim_hof_benefit;

  /// No description provided for @safety_low.
  ///
  /// In ru, this message translates to:
  /// **'Дышите в комфортном темпе. Если почувствуете головокружение или дискомфорт — прервите упражнение и дышите нормально.'**
  String get safety_low;

  /// No description provided for @safety_holds_generic.
  ///
  /// In ru, this message translates to:
  /// **'Техника содержит задержки дыхания. Небольшое покалывание в конечностях — нормально; головокружение или потемнение в глазах — сигнал остановиться и дышать свободно. Никогда не выполняйте эту технику в воде, за рулём или в любой ситуации, требующей концентрации внимания.'**
  String get safety_holds_generic;

  /// No description provided for @safety_intense.
  ///
  /// In ru, this message translates to:
  /// **'ВАЖНО: никогда не выполняйте эту технику в воде, за рулём, стоя или при управлении механизмами — возможна потеря сознания.\n\nПротивопоказания: беременность, эпилепсия, сердечно-сосудистые заболевания, гипертония, панические расстройства, недавние операции, глаукома. При наличии любого из этих состояний проконсультируйтесь с врачом перед практикой.\n\nНачинайте с 3–4 циклов, постепенно увеличивая нагрузку.'**
  String get safety_intense;

  /// No description provided for @startSession.
  ///
  /// In ru, this message translates to:
  /// **'Начать'**
  String get startSession;

  /// No description provided for @comingSoonStage2.
  ///
  /// In ru, this message translates to:
  /// **'Появится в одном из следующих обновлений'**
  String get comingSoonStage2;

  /// No description provided for @comingSoonBadge.
  ///
  /// In ru, this message translates to:
  /// **'Скоро'**
  String get comingSoonBadge;

  /// No description provided for @sectionDescription.
  ///
  /// In ru, this message translates to:
  /// **'Описание'**
  String get sectionDescription;

  /// No description provided for @sectionBenefit.
  ///
  /// In ru, this message translates to:
  /// **'Польза'**
  String get sectionBenefit;

  /// No description provided for @sectionSafety.
  ///
  /// In ru, this message translates to:
  /// **'Безопасность'**
  String get sectionSafety;

  /// No description provided for @cyclesShort.
  ///
  /// In ru, this message translates to:
  /// **'{n, plural, one {{n} цикл} few {{n} цикла} many {{n} циклов} other {{n} цикла}}'**
  String cyclesShort(int n);

  /// No description provided for @minutesShort.
  ///
  /// In ru, this message translates to:
  /// **'{n} мин'**
  String minutesShort(int n);

  /// No description provided for @roundsShort.
  ///
  /// In ru, this message translates to:
  /// **'{n, plural, one {{n} раунд} few {{n} раунда} many {{n} раундов} other {{n} раунда}}'**
  String roundsShort(int n);

  /// No description provided for @noviceCyclesHint.
  ///
  /// In ru, this message translates to:
  /// **'Новичкам — не более {n} циклов'**
  String noviceCyclesHint(int n);

  /// No description provided for @settingsTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settingsTooltip;

  /// No description provided for @setupTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройка'**
  String get setupTitle;

  /// No description provided for @endModeCycles.
  ///
  /// In ru, this message translates to:
  /// **'Циклы'**
  String get endModeCycles;

  /// No description provided for @endModeTimer.
  ///
  /// In ru, this message translates to:
  /// **'Таймер'**
  String get endModeTimer;

  /// No description provided for @cyclesLabel.
  ///
  /// In ru, this message translates to:
  /// **'Количество циклов'**
  String get cyclesLabel;

  /// No description provided for @timerLabel.
  ///
  /// In ru, this message translates to:
  /// **'Таймер, мин'**
  String get timerLabel;

  /// No description provided for @phasesSection.
  ///
  /// In ru, this message translates to:
  /// **'Длительности фаз'**
  String get phasesSection;

  /// No description provided for @keepRatioLabel.
  ///
  /// In ru, this message translates to:
  /// **'Держать пропорцию'**
  String get keepRatioLabel;

  /// No description provided for @simplifiedLabel.
  ///
  /// In ru, this message translates to:
  /// **'Упрощённый режим'**
  String get simplifiedLabel;

  /// No description provided for @tempoLabel.
  ///
  /// In ru, this message translates to:
  /// **'Темп'**
  String get tempoLabel;

  /// No description provided for @resetToClassic.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить к классике'**
  String get resetToClassic;

  /// No description provided for @feedbackSection.
  ///
  /// In ru, this message translates to:
  /// **'Сопровождение'**
  String get feedbackSection;

  /// No description provided for @channelVoice.
  ///
  /// In ru, this message translates to:
  /// **'Голос'**
  String get channelVoice;

  /// No description provided for @channelSound.
  ///
  /// In ru, this message translates to:
  /// **'Звук'**
  String get channelSound;

  /// No description provided for @channelMetronome.
  ///
  /// In ru, this message translates to:
  /// **'Метроном'**
  String get channelMetronome;

  /// No description provided for @channelVibration.
  ///
  /// In ru, this message translates to:
  /// **'Вибрация'**
  String get channelVibration;

  /// No description provided for @channelVisual.
  ///
  /// In ru, this message translates to:
  /// **'Визуальный режим'**
  String get channelVisual;

  /// No description provided for @prepLabel.
  ///
  /// In ru, this message translates to:
  /// **'Подготовка, с'**
  String get prepLabel;

  /// No description provided for @phaseInhale.
  ///
  /// In ru, this message translates to:
  /// **'Вдох'**
  String get phaseInhale;

  /// No description provided for @phaseHoldIn.
  ///
  /// In ru, this message translates to:
  /// **'Задержка'**
  String get phaseHoldIn;

  /// No description provided for @phaseExhale.
  ///
  /// In ru, this message translates to:
  /// **'Выдох'**
  String get phaseExhale;

  /// No description provided for @phaseHoldOut.
  ///
  /// In ru, this message translates to:
  /// **'Задержка'**
  String get phaseHoldOut;

  /// No description provided for @secondsShort.
  ///
  /// In ru, this message translates to:
  /// **'{n} с'**
  String secondsShort(String n);

  /// No description provided for @accountSection.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт'**
  String get accountSection;

  /// No description provided for @signInGoogle.
  ///
  /// In ru, this message translates to:
  /// **'Войти через Google'**
  String get signInGoogle;

  /// No description provided for @signOutAction.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get signOutAction;

  /// No description provided for @accountGuest.
  ///
  /// In ru, this message translates to:
  /// **'Гостевой режим'**
  String get accountGuest;

  /// No description provided for @accountGuestNote.
  ///
  /// In ru, this message translates to:
  /// **'Практика и настройки работают без аккаунта. Вход понадобится для друзей и общей ленты.'**
  String get accountGuestNote;

  /// No description provided for @authNotConfiguredNote.
  ///
  /// In ru, this message translates to:
  /// **'Вход через Google станет доступен в одном из ближайших обновлений.'**
  String get authNotConfiguredNote;

  /// No description provided for @statsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Практика'**
  String get statsTitle;

  /// No description provided for @statsTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Календарь практик'**
  String get statsTooltip;

  /// No description provided for @streakLabel.
  ///
  /// In ru, this message translates to:
  /// **'{n, plural, one {день подряд} few {дня подряд} many {дней подряд} other {дня подряд}}'**
  String streakLabel(int n);

  /// No description provided for @monthMinutesLabel.
  ///
  /// In ru, this message translates to:
  /// **'минут за месяц'**
  String get monthMinutesLabel;

  /// No description provided for @monthSessionsLabel.
  ///
  /// In ru, this message translates to:
  /// **'{n, plural, one {сессия} few {сессии} many {сессий} other {сессии}}'**
  String monthSessionsLabel(int n);

  /// No description provided for @statsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет ни одной практики. Начните с любой техники — здесь появится календарь.'**
  String get statsEmpty;

  /// No description provided for @byTechniqueLabel.
  ///
  /// In ru, this message translates to:
  /// **'По техникам'**
  String get byTechniqueLabel;

  /// No description provided for @createGuestProfile.
  ///
  /// In ru, this message translates to:
  /// **'Создать профиль (без регистрации)'**
  String get createGuestProfile;

  /// No description provided for @guestProfileLabel.
  ///
  /// In ru, this message translates to:
  /// **'Гостевой профиль'**
  String get guestProfileLabel;

  /// No description provided for @nicknameDialogTitle.
  ///
  /// In ru, this message translates to:
  /// **'Имя в челленджах'**
  String get nicknameDialogTitle;

  /// No description provided for @signOutAnonWarning.
  ///
  /// In ru, this message translates to:
  /// **'Гостевой профиль нельзя восстановить после выхода: челленджи и ник будут потеряны. Выйти?'**
  String get signOutAnonWarning;

  /// No description provided for @commonCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get commonSave;

  /// No description provided for @linkGoogleAction.
  ///
  /// In ru, this message translates to:
  /// **'Привязать Google — сохранить профиль навсегда'**
  String get linkGoogleAction;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
