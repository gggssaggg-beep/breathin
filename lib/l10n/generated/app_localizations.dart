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
  /// **'Классическая техника: вдох, задержка, выдох и повторная задержка — каждая фаза одинаковой длины, по умолчанию 4 секунды. Визуально образует квадрат: мысленно «обходите» его углы, удерживая ритм. Подходит для начинающих и регулярной практики в любой обстановке. Дышите через нос — и на вдохе, и на выдохе.'**
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
  /// **'Трёхфазная техника: вдох — задержка — выдох без второй паузы. Паттерн образует треугольник: плавный, но с элементом задержки. Длительность каждой фазы настраивается от 2 до 10 секунд. Дышите через нос — и на вдохе, и на выдохе.'**
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
  /// **'Техника Эндрю Вейла: вдох на 4 счёта, задержка на 7, медленный выдох на 8. Пропорция фаз фиксирована; доступен выбор множителя темпа (×0.5 / ×0.75 / ×1 / ×1.25) для замедления или ускорения цикла. Вдох — тихо через нос, выдох — со звуком через рот, слегка сжав губы. Новичкам рекомендуется начинать с 4 циклов.'**
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
  /// **'Мягкая балансирующая техника: вдох на 4 счёта, короткая задержка на 2, выдох на 4. Все фазы можно настраивать в диапазоне 2–10 секунд. Доступна и расслабляющая, и тонизирующая акцентировка в зависимости от темпа. Дышите через нос — и на вдохе, и на выдохе.'**
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
  /// **'Техника удлинённого выдоха с соотношением 1:4 — короткий вдох на 2 секунды и длинный выдох на 8. Соотношение фаз можно сохранять или менять независимо. Вдох — через нос, выдох — плавно через рот, слегка сжав губы. Не требует задержек, проста в освоении.\n\nЭто же — быстрая разрядка любого возбуждения: гнева, влечения, тревоги, взбудораженности. Удлинённый выдох активирует парасимпатическую систему и возвращает управление за 1–3 минуты, можно незаметно, в любой обстановке. Вариант 4/8: вдох носом на 4 счёта без усилия, выдох носом или через слегка приоткрытые губы (как через трубочку) на 8 — настройте фазы слайдерами. Внимание: на вдохе — нейтрально, на выдохе — провожать ощущение вниз, от груди к животу и в опору (стопы, сиденье). 10–20 циклов.\n\nМаркер: плечи опустились, «поднимающаяся волна» в груди и голове стекает вниз, мысли замедлились. При головокружении сократить счёт (3/6).'**
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
  /// **'Более глубокая версия техники 2-8 с соотношением 1:5 — вдох на 2 секунды, выдох на 10. Выдох ещё более протяжный, что усиливает расслабляющий эффект. Вдох — через нос, выдох — плавно через рот, слегка сжав губы. Соотношение фаз регулируется.'**
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
  /// **'Пранаяма-соотношение 1:4:2 — вдох 4, задержка 16, выдох 8. По умолчанию предлагается упрощённый режим 4-8-8; опытные практикующие могут перейти к полному паттерну. База масштабируется: например, 3-12-6 или 5-20-10. Дыхание только через нос (пранаяма). Рекомендуется для тех, кто уже освоил базовые техники. Новичкам — не более 4 циклов.'**
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
  /// **'Медленное дыхание в темпе около 5–6 циклов в минуту: вдох и выдох одинаковой длины (по умолчанию 5.5 секунды каждый), без задержек. Длительность фаз настраивается от 4 до 7 секунд. Техника мягкая и подходит для длительных сессий. Дышите через нос — спокойно и бесшумно.'**
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
  /// **'Свободное дыхание животом по таймеру: дышите глубоко, позволяя животу подниматься на вдохе и опускаться на выдохе — без счёта и задержек. В начале сессии воспроизводится голосовая инструкция. Вдыхайте через нос, выдыхайте через рот, слегка сжав губы. Можно включить мягкий фоновый звук для атмосферы.'**
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
  /// **'Попеременное дыхание ноздрями из традиции йоги: поочерёдно закрывая правую и левую ноздрю, вы синхронизируете полушария мозга. Практикуется по таймеру; доступны звуковые подсказки смены ноздри с настраиваемым интервалом или полностью свободный режим. Дыхание — только через нос, поочерёдно через ноздри.\n\nБалансировка после эмоциональных качелей: когда состояние скачет между возбуждением и упадком, раздражением и апатией — выравнивает и успокаивает, не «выключая» энергию. Хорошо после конфликта, тяжёлого разговора, эмоционально заряженного дня, перед сном и перед медитацией.\n\nВариант со счётом: правая рука — большой палец закрывает правую ноздрю, безымянный — левую. Закрыть правую → вдох левой на 4 счёта; закрыть левую, открыть правую → выдох правой на 6–8; вдох правой на 4 → закрыть, выдох левой на 6–8 — это один цикл, всего 9–12. Дыхание плавное, беззвучное; внимание — на прохладе воздуха на вдохе и тепле на выдохе. Задержек в базовом варианте нет.\n\nМаркер: обе ноздри дышат ровнее, состояние ровное, ясное, спокойное. Если нос заложен — сначала прочистить или отложить.'**
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
  /// **'Техника осознанного дыхания с вокализацией (Уджайи) или гудением (Брамари «пчела»). Практикуется по таймеру; в начале — голосовая инструкция. Для Брамари доступны опциональные подсказки «вдох / гудите на выдохе». Дыхание — через нос.'**
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
  /// **'Интенсивная техника. Раунд: 30–40 глубоких дыханий — вдох полной грудью через нос или рот (живот наружу), выдох свободно через рот, без усилия («отпустить»). После последнего выдоха — длинная задержка на пустых лёгких, до появления позыва вдохнуть. Затем восстановительный вдох: глубокий вдох и задержка на вдохе 15 секунд. Обычно 3–4 раунда. Официально настраиваются только число дыханий, темп и количество раундов — сама механика (выдох ртом, длинная задержка на выдохе, короткая на вдохе) всегда одна, «утренней» и «вечерней» версий у метода нет. Лучшее время — утром натощак (бодрит сильнее кофе); перед сном не рекомендуется. По завершении показывается время задержек по раундам.'**
  String get tech_wim_hof_desc;

  /// No description provided for @tech_wim_hof_benefit.
  ///
  /// In ru, this message translates to:
  /// **'Повышает устойчивость к стрессу, увеличивает энергетический тонус, улучшает холодовую адаптацию и развивает осознанный контроль над дыхательной системой.'**
  String get tech_wim_hof_benefit;

  /// No description provided for @tech_stretch_name.
  ///
  /// In ru, this message translates to:
  /// **'Вытягивающее дыхание'**
  String get tech_stretch_name;

  /// No description provided for @tech_stretch_desc.
  ///
  /// In ru, this message translates to:
  /// **'Практика из Суфийского движения (учение Хазрата Инайят Хана). Вдох всегда одинаковой длины — 4 счёта через нос, а выдох через рот с каждым дыханием плавно удлиняется: 4, 6, 8 … до 28 счётов, затем так же плавно возвращается к 4. Всего около 25 дыханий.\n\nВ основе — философия отдачи. На вдохе мы всегда берём одинаково, а с каждым выдохом отдаём немного больше, чем взяли. Выдох — это движение расширения и отпускания: раз за разом отдавая больше, чем берёшь, воспитываешь в себе щедрость и лёгкость, а заодно тренируешь ёмкость и ровность дыхания. Держите выдох равномерным от начала до конца и не доводите себя до дискомфорта.'**
  String get tech_stretch_desc;

  /// No description provided for @tech_stretch_benefit.
  ///
  /// In ru, this message translates to:
  /// **'Увеличивает жизненную ёмкость лёгких, тренирует длинный ровный выдох и контроль над дыханием, помогает успокоиться и собрать внимание.'**
  String get tech_stretch_benefit;

  /// No description provided for @tech_elemental_name.
  ///
  /// In ru, this message translates to:
  /// **'Дыхание по элементам'**
  String get tech_elemental_name;

  /// No description provided for @tech_elemental_desc.
  ///
  /// In ru, this message translates to:
  /// **'Очистительная практика из Суфийского движения (учение Хазрата Инайят Хана). Пять последовательных сегментов — Земля, Вода, Огонь, Воздух и Эфир — по пять дыханий в каждом. У каждого элемента свой маршрут: Земля — вдох и выдох носом; Вода — вдох носом, выдох ртом; Огонь — вдох ртом, выдох носом; Воздух — вдох и выдох ртом; Эфир — тихое, едва заметное дыхание. Вдох на 4 счёта, выдох на 6. Экран подсказывает текущий элемент, его цвет и маршрут. Традиционно выполняется стоя, лучше на свежем воздухе.'**
  String get tech_elemental_desc;

  /// No description provided for @tech_elemental_benefit.
  ///
  /// In ru, this message translates to:
  /// **'Очищает и настраивает дыхание, помогает последовательно пройти пять качеств — устойчивость, текучесть, энергию, лёгкость и тишину — и собрать внимание перед началом дня.'**
  String get tech_elemental_benefit;

  /// No description provided for @tech_fikr_name.
  ///
  /// In ru, this message translates to:
  /// **'Фикр'**
  String get tech_fikr_name;

  /// No description provided for @tech_fikr_desc.
  ///
  /// In ru, this message translates to:
  /// **'Практика памятования из Суфийского движения (учение Хазрата Инайят Хана). Спокойное дыхание носом: вдох на 4 счёта, выдох на 6. С каждой фазой мысленно повторяется фраза — одна на вдохе, другая на выдохе; экран подсказывает её в такт дыханию.\n\nВыберите в настройке сессии фразу по душе. Смысл не в словах как таковых — фраза даёт вниманию мягкую опору, и дыхание само становится ровнее и глубже.'**
  String get tech_fikr_desc;

  /// No description provided for @tech_fikr_benefit.
  ///
  /// In ru, this message translates to:
  /// **'Успокаивает поток мыслей, тренирует устойчивое внимание и связывает дыхание с намерением. Хорошая опора в стрессе и перед сном.'**
  String get tech_fikr_benefit;

  /// No description provided for @tech_vessel_name.
  ///
  /// In ru, this message translates to:
  /// **'Дыхание сосуда'**
  String get tech_vessel_name;

  /// No description provided for @tech_vessel_desc.
  ///
  /// In ru, this message translates to:
  /// **'Собирает рассеянную или «бьющую вверх» энергию (возбуждение, вспышки эмоций) в устойчивый центр ниже пупка. Мягкий, безопасный вариант тибетского «кувшинного дыхания».\n\nКогда применять: когда энергия есть, но она хаотична — не можешь усидеть, «несёт», сильное влечение или гнев без выхода. Не для острого приступа паники (для него — удлинённый выдох 2-8).\n\nКак выполнять: сидя, спина прямая, руки на коленях или ладони на низе живота. Вдох носом, спокойный, направляя его «вниз» — живот мягко расширяется. В конце вдоха мягко (без напряжения горла!) задержать дыхание на 3–5 секунд, слегка опустив диафрагму и чуть подтянув низ живота навстречу — как будто воздух «сидит в сосуде» ниже пупка. Внимание всё время — на точке на 4 пальца ниже пупка; можно представлять там тёплую сферу. Выдох носом, медленный, оставляя внимание в той же точке. 7–15 циклов, не больше.\n\nМаркер: тепло или плотность внизу живота, ощущение «осевости» — энергия никуда не делась, но перестала дёргать вверх и наружу. Интенсивность осталась, вектор исчез.\n\nПротивопоказания: гипертония, болезни сердца, беременность, недавние операции на брюшной полости, склонность к паническим атакам, эпилепсия. Задержка всегда комфортная: никакого распирания в голове и горле. При любом давлении в голове — прекратить и перейти к удлинённому выдоху.'**
  String get tech_vessel_desc;

  /// No description provided for @tech_vessel_benefit.
  ///
  /// In ru, this message translates to:
  /// **'Собирает хаотичную энергию в устойчивый центр ниже пупка: интенсивность остаётся, но перестаёт дёргать вверх и наружу.'**
  String get tech_vessel_benefit;

  /// No description provided for @tech_axis_name.
  ///
  /// In ru, this message translates to:
  /// **'Дыхание по оси'**
  String get tech_axis_name;

  /// No description provided for @tech_axis_desc.
  ///
  /// In ru, this message translates to:
  /// **'Переводит внимание с объекта (человека, ситуации, картинки в голове) на собственную вертикаль. Классический принцип: энергия следует за вниманием — возвращаем внимание в своё тело, и энергия перестаёт утекать к объекту.\n\nКогда применять: навязчивые мысли о ком-то или о чём-то, «залипание», когда внимание снова и снова уходит к объекту.\n\nКак выполнять: сидя или стоя, макушка тянется вверх. Дыхание носом, естественное, без счёта. На вдохе внимание скользит по воображаемой оси внутри тела снизу вверх — от промежности вдоль позвоночника к макушке. На выдохе — сверху вниз по той же оси. Если внимание убежало к объекту — спокойно заметить («ушло») и на следующем вдохе вернуть на ось: само возвращение и есть упражнение. Глаза лучше прикрыть или расфокусировать.\n\nМаркер: ось ощущается как реальная линия тепла или покалывания; образ объекта тускнеет сам, без борьбы с ним. При лёгком головокружении дышать чуть поверхностнее.'**
  String get tech_axis_desc;

  /// No description provided for @tech_axis_benefit.
  ///
  /// In ru, this message translates to:
  /// **'Возвращает внимание с объекта в собственную вертикаль — навязчивые мысли и «залипание» тускнеют сами, без борьбы.'**
  String get tech_axis_benefit;

  /// No description provided for @tech_nine_breaths_name.
  ///
  /// In ru, this message translates to:
  /// **'Девять очищающих дыханий'**
  String get tech_nine_breaths_name;

  /// No description provided for @tech_nine_breaths_desc.
  ///
  /// In ru, this message translates to:
  /// **'Короткий «сброс» застоявшихся состояний: раздражения, вялости, мутности. Традиционно выполняется перед медитацией как очистка каналов.\n\nКогда применять: перед любой практикой или медитацией; когда нужно быстро «переключить» состояние.\n\nКак выполнять: сидя, спина прямая — ровно 9 дыханий, экран подсказывает текущую тройку. Первые 3: закрыть правую ноздрю пальцем, вдох левой; закрыть левую — резковатый, но не насильственный выдох правой; на выдохе представлять, что выходит серый дым раздражения и гнева. Следующие 3 — наоборот: вдох правой, выдох левой; выходит муть привязанности и «залипания». Последние 3: вдох и выдох обеими ноздрями, чуть с усилием; выходит тусклость и вялость. Вдохи мягкие и полные, выдохи — акцентированные, «выбрасывающие». Внимание — на образе выходящего с выдохом.\n\nМаркер: ощущение свежести и пустоты в голове, как после проветривания комнаты.\n\nПротивопоказания: гипертония, беременность, недавние травмы головы — резкие выдохи заменить на обычные плавные. При головокружении — пауза, дышать обычно.'**
  String get tech_nine_breaths_desc;

  /// No description provided for @tech_nine_breaths_benefit.
  ///
  /// In ru, this message translates to:
  /// **'За девять дыханий сбрасывает раздражение, «залипание» и вялость — свежесть, как после проветривания комнаты.'**
  String get tech_nine_breaths_benefit;

  /// No description provided for @segNineLeft.
  ///
  /// In ru, this message translates to:
  /// **'Вдох левой · выдох правой'**
  String get segNineLeft;

  /// No description provided for @segNineRight.
  ///
  /// In ru, this message translates to:
  /// **'Вдох правой · выдох левой'**
  String get segNineRight;

  /// No description provided for @segNineBoth.
  ///
  /// In ru, this message translates to:
  /// **'Обе ноздри'**
  String get segNineBoth;

  /// No description provided for @fikrPhrasesLabel.
  ///
  /// In ru, this message translates to:
  /// **'Фразы'**
  String get fikrPhrasesLabel;

  /// No description provided for @fikrCustomLabel.
  ///
  /// In ru, this message translates to:
  /// **'Своя фраза'**
  String get fikrCustomLabel;

  /// No description provided for @fikrCustomHint.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите, чтобы написать свою'**
  String get fikrCustomHint;

  /// No description provided for @fikrCustomInLabel.
  ///
  /// In ru, this message translates to:
  /// **'Фраза на вдохе'**
  String get fikrCustomInLabel;

  /// No description provided for @fikrCustomExLabel.
  ///
  /// In ru, this message translates to:
  /// **'Фраза на выдохе'**
  String get fikrCustomExLabel;

  /// No description provided for @fikr_calm_in.
  ///
  /// In ru, this message translates to:
  /// **'Вдыхаю покой'**
  String get fikr_calm_in;

  /// No description provided for @fikr_calm_ex.
  ///
  /// In ru, this message translates to:
  /// **'Отпускаю напряжение'**
  String get fikr_calm_ex;

  /// No description provided for @fikr_presence_in.
  ///
  /// In ru, this message translates to:
  /// **'Я здесь'**
  String get fikr_presence_in;

  /// No description provided for @fikr_presence_ex.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас'**
  String get fikr_presence_ex;

  /// No description provided for @fikr_light_in.
  ///
  /// In ru, this message translates to:
  /// **'Вдыхаю Свет и Жизнь'**
  String get fikr_light_in;

  /// No description provided for @fikr_light_ex.
  ///
  /// In ru, this message translates to:
  /// **'Излучаю Жизнь и Свет'**
  String get fikr_light_ex;

  /// No description provided for @fikr_first_light_in.
  ///
  /// In ru, this message translates to:
  /// **'В начале был Свет'**
  String get fikr_first_light_in;

  /// No description provided for @fikr_first_light_ex.
  ///
  /// In ru, this message translates to:
  /// **'И Пространство озарилось этим Светом'**
  String get fikr_first_light_ex;

  /// No description provided for @fikr_heart_waves_in.
  ///
  /// In ru, this message translates to:
  /// **'Моё сердце отражает вселенскую любовь'**
  String get fikr_heart_waves_in;

  /// No description provided for @fikr_heart_waves_ex.
  ///
  /// In ru, this message translates to:
  /// **'Как волны отражают солнечный свет'**
  String get fikr_heart_waves_ex;

  /// No description provided for @fikr_wave_ocean_in.
  ///
  /// In ru, this message translates to:
  /// **'Я — волна'**
  String get fikr_wave_ocean_in;

  /// No description provided for @fikr_wave_ocean_ex.
  ///
  /// In ru, this message translates to:
  /// **'Океан дышит мной'**
  String get fikr_wave_ocean_ex;

  /// No description provided for @fikr_shore_in.
  ///
  /// In ru, this message translates to:
  /// **'Волна приходит'**
  String get fikr_shore_in;

  /// No description provided for @fikr_shore_ex.
  ///
  /// In ru, this message translates to:
  /// **'Волна уходит'**
  String get fikr_shore_ex;

  /// No description provided for @fikr_gift_in.
  ///
  /// In ru, this message translates to:
  /// **'Принимаю вдох как дар'**
  String get fikr_gift_in;

  /// No description provided for @fikr_gift_ex.
  ///
  /// In ru, this message translates to:
  /// **'Возвращаю его миру'**
  String get fikr_gift_ex;

  /// No description provided for @fikr_stillness_in.
  ///
  /// In ru, this message translates to:
  /// **'В глубине — тишина'**
  String get fikr_stillness_in;

  /// No description provided for @fikr_stillness_ex.
  ///
  /// In ru, this message translates to:
  /// **'Я опускаюсь в неё'**
  String get fikr_stillness_ex;

  /// No description provided for @fikr_sky_mind_in.
  ///
  /// In ru, this message translates to:
  /// **'Во мне — небо'**
  String get fikr_sky_mind_in;

  /// No description provided for @fikr_sky_mind_ex.
  ///
  /// In ru, this message translates to:
  /// **'Мысли — облака, они проплывают'**
  String get fikr_sky_mind_ex;

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

  /// No description provided for @stretchPatternTitle.
  ///
  /// In ru, this message translates to:
  /// **'Рисунок дыхания'**
  String get stretchPatternTitle;

  /// No description provided for @stretchPatternDesc.
  ///
  /// In ru, this message translates to:
  /// **'Вдох 4 через нос, выдох через рот с плавным удлинением: 4 → 6 → … → 28 → … → 6 → 4. Всего 25 дыханий. Держите выдох ровным от начала до конца.'**
  String get stretchPatternDesc;

  /// No description provided for @elementalPatternDesc.
  ///
  /// In ru, this message translates to:
  /// **'Пять элементов по пять дыханий: Земля (нос→нос), Вода (нос→рот), Огонь (рот→нос), Воздух (рот→рот), Эфир — тихое дыхание. Вдох 4, выдох 6. Экран подскажет текущий элемент.'**
  String get elementalPatternDesc;

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

  /// No description provided for @segEarth.
  ///
  /// In ru, this message translates to:
  /// **'Земля'**
  String get segEarth;

  /// No description provided for @segWater.
  ///
  /// In ru, this message translates to:
  /// **'Вода'**
  String get segWater;

  /// No description provided for @segFire.
  ///
  /// In ru, this message translates to:
  /// **'Огонь'**
  String get segFire;

  /// No description provided for @segAir.
  ///
  /// In ru, this message translates to:
  /// **'Воздух'**
  String get segAir;

  /// No description provided for @segEther.
  ///
  /// In ru, this message translates to:
  /// **'Эфир'**
  String get segEther;

  /// No description provided for @segInhaleNose.
  ///
  /// In ru, this message translates to:
  /// **'Вдох носом'**
  String get segInhaleNose;

  /// No description provided for @segInhaleMouth.
  ///
  /// In ru, this message translates to:
  /// **'Вдох ртом'**
  String get segInhaleMouth;

  /// No description provided for @segExhaleNose.
  ///
  /// In ru, this message translates to:
  /// **'Выдох носом'**
  String get segExhaleNose;

  /// No description provided for @segExhaleMouth.
  ///
  /// In ru, this message translates to:
  /// **'Выдох ртом'**
  String get segExhaleMouth;

  /// No description provided for @segSilentBreath.
  ///
  /// In ru, this message translates to:
  /// **'Тихое, тонкое дыхание'**
  String get segSilentBreath;

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

  /// No description provided for @authActionFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не получилось. Проверьте интернет и попробуйте ещё раз.'**
  String get authActionFailed;

  /// No description provided for @emailFieldLabel.
  ///
  /// In ru, this message translates to:
  /// **'Почта'**
  String get emailFieldLabel;

  /// No description provided for @emailSignInAction.
  ///
  /// In ru, this message translates to:
  /// **'Войти по почте'**
  String get emailSignInAction;

  /// No description provided for @linkEmailAction.
  ///
  /// In ru, this message translates to:
  /// **'Привязать почту'**
  String get linkEmailAction;

  /// No description provided for @emailInvalidNote.
  ///
  /// In ru, this message translates to:
  /// **'Введите корректный адрес почты'**
  String get emailInvalidNote;

  /// No description provided for @emailLinkSentNote.
  ///
  /// In ru, this message translates to:
  /// **'Мы отправили ссылку для входа на {email}. Откройте письмо на этом устройстве и нажмите ссылку.'**
  String emailLinkSentNote(String email);

  /// No description provided for @emailOrDivider.
  ///
  /// In ru, this message translates to:
  /// **'или'**
  String get emailOrDivider;

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

  /// No description provided for @challengesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Челленджи'**
  String get challengesTitle;

  /// No description provided for @challengesTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Челленджи с друзьями'**
  String get challengesTooltip;

  /// No description provided for @challengesSignInHint.
  ///
  /// In ru, this message translates to:
  /// **'Челленджи — соревнование с друзьями: кто больше практикует. Создайте профиль или войдите, чтобы начать.'**
  String get challengesSignInHint;

  /// No description provided for @challengesEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет челленджей. Создайте свой и пришлите код друзьям — или введите код друга.'**
  String get challengesEmpty;

  /// No description provided for @createChallengeAction.
  ///
  /// In ru, this message translates to:
  /// **'Создать челлендж'**
  String get createChallengeAction;

  /// No description provided for @joinByCodeAction.
  ///
  /// In ru, this message translates to:
  /// **'Ввести код'**
  String get joinByCodeAction;

  /// No description provided for @challengeTitleLabel.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get challengeTitleLabel;

  /// No description provided for @challengeTitleDefault.
  ///
  /// In ru, this message translates to:
  /// **'Дышим вместе'**
  String get challengeTitleDefault;

  /// No description provided for @metricLabel.
  ///
  /// In ru, this message translates to:
  /// **'Метрика'**
  String get metricLabel;

  /// No description provided for @metricSessions.
  ///
  /// In ru, this message translates to:
  /// **'Сессии'**
  String get metricSessions;

  /// No description provided for @metricMinutes.
  ///
  /// In ru, this message translates to:
  /// **'Минуты'**
  String get metricMinutes;

  /// No description provided for @metricStreak.
  ///
  /// In ru, this message translates to:
  /// **'Дни подряд'**
  String get metricStreak;

  /// No description provided for @targetLabel.
  ///
  /// In ru, this message translates to:
  /// **'Цель'**
  String get targetLabel;

  /// No description provided for @durationLabel.
  ///
  /// In ru, this message translates to:
  /// **'Длительность, дней'**
  String get durationLabel;

  /// No description provided for @codeFieldLabel.
  ///
  /// In ru, this message translates to:
  /// **'Код приглашения'**
  String get codeFieldLabel;

  /// No description provided for @codeNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Челлендж с таким кодом не найден'**
  String get codeNotFound;

  /// No description provided for @joinedChallenge.
  ///
  /// In ru, this message translates to:
  /// **'Вы присоединились: {title}'**
  String joinedChallenge(String title);

  /// No description provided for @challengeCodeShare.
  ///
  /// In ru, this message translates to:
  /// **'Код для друзей: {code}'**
  String challengeCodeShare(String code);

  /// No description provided for @codeCopied.
  ///
  /// In ru, this message translates to:
  /// **'Код скопирован'**
  String get codeCopied;

  /// No description provided for @challengeUntil.
  ///
  /// In ru, this message translates to:
  /// **'до {date}'**
  String challengeUntil(String date);

  /// No description provided for @challengeFinished.
  ///
  /// In ru, this message translates to:
  /// **'Завершён'**
  String get challengeFinished;

  /// No description provided for @commonCreate.
  ///
  /// In ru, this message translates to:
  /// **'Создать'**
  String get commonCreate;

  /// No description provided for @commonJoin.
  ///
  /// In ru, this message translates to:
  /// **'Присоединиться'**
  String get commonJoin;

  /// No description provided for @updateAvailableSnack.
  ///
  /// In ru, this message translates to:
  /// **'Доступно обновление {version}'**
  String updateAvailableSnack(String version);

  /// No description provided for @updateDownloadAction.
  ///
  /// In ru, this message translates to:
  /// **'Скачать'**
  String get updateDownloadAction;

  /// No description provided for @appVersionLabel.
  ///
  /// In ru, this message translates to:
  /// **'Версия {version}'**
  String appVersionLabel(String version);

  /// No description provided for @challengesLoadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не получилось загрузить челленджи. Проверьте интернет.'**
  String get challengesLoadFailed;

  /// No description provided for @commonRetry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get commonRetry;

  /// No description provided for @settingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settingsTitle;

  /// No description provided for @updatesSection.
  ///
  /// In ru, this message translates to:
  /// **'Обновления'**
  String get updatesSection;

  /// No description provided for @autoUpdateLabel.
  ///
  /// In ru, this message translates to:
  /// **'Автообновление'**
  String get autoUpdateLabel;

  /// No description provided for @autoUpdateSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Проверять при запуске'**
  String get autoUpdateSubtitle;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In ru, this message translates to:
  /// **'Доступно обновление {version}'**
  String updateAvailableTitle(String version);

  /// No description provided for @updateNowAction.
  ///
  /// In ru, this message translates to:
  /// **'Обновить'**
  String get updateNowAction;

  /// No description provided for @updateCheckFailedNote.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось проверить обновления'**
  String get updateCheckFailedNote;

  /// No description provided for @upToDateNote.
  ///
  /// In ru, this message translates to:
  /// **'Установлена последняя версия'**
  String get upToDateNote;

  /// No description provided for @languageSection.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get languageSection;

  /// No description provided for @languageSystem.
  ///
  /// In ru, this message translates to:
  /// **'Как в системе'**
  String get languageSystem;

  /// No description provided for @favoriteTooltip.
  ///
  /// In ru, this message translates to:
  /// **'В избранное'**
  String get favoriteTooltip;

  /// No description provided for @difficultySection.
  ///
  /// In ru, this message translates to:
  /// **'Сложность'**
  String get difficultySection;

  /// No description provided for @difficultyNote.
  ///
  /// In ru, this message translates to:
  /// **'Пресет мягко меняет длительность фаз для новых техник. Уже настроенные вручную техники не трогаются.'**
  String get difficultyNote;

  /// No description provided for @difficultyCalm.
  ///
  /// In ru, this message translates to:
  /// **'Штиль'**
  String get difficultyCalm;

  /// No description provided for @difficultyBreeze.
  ///
  /// In ru, this message translates to:
  /// **'Бриз'**
  String get difficultyBreeze;

  /// No description provided for @difficultyWave.
  ///
  /// In ru, this message translates to:
  /// **'Волна'**
  String get difficultyWave;

  /// No description provided for @difficultyTide.
  ///
  /// In ru, this message translates to:
  /// **'Прибой'**
  String get difficultyTide;

  /// No description provided for @difficultyMine.
  ///
  /// In ru, this message translates to:
  /// **'Своё дыхание'**
  String get difficultyMine;

  /// No description provided for @difficultyMineNote.
  ///
  /// In ru, this message translates to:
  /// **'Подбирается по вашему дыхательному тесту'**
  String get difficultyMineNote;

  /// No description provided for @difficultyMineNoTest.
  ///
  /// In ru, this message translates to:
  /// **'Пройдите дыхательный тест в «Практике», чтобы подобрать своё дыхание. Пока используется «Бриз».'**
  String get difficultyMineNoTest;

  /// No description provided for @communitySection.
  ///
  /// In ru, this message translates to:
  /// **'Сообщество'**
  String get communitySection;

  /// No description provided for @feedbackAction.
  ///
  /// In ru, this message translates to:
  /// **'Обратная связь'**
  String get feedbackAction;

  /// No description provided for @communityChatAction.
  ///
  /// In ru, this message translates to:
  /// **'Чат нашего сообщества'**
  String get communityChatAction;

  /// No description provided for @welcomeBody.
  ///
  /// In ru, this message translates to:
  /// **'Простые дыхательные практики на каждый день — успокоиться, сосредоточиться или зарядиться энергией.'**
  String get welcomeBody;

  /// No description provided for @welcomeStart.
  ///
  /// In ru, this message translates to:
  /// **'Начать'**
  String get welcomeStart;

  /// No description provided for @coachHomePick.
  ///
  /// In ru, this message translates to:
  /// **'Выберите технику — их можно настроить под себя.'**
  String get coachHomePick;

  /// No description provided for @coachCardStart.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите, чтобы настроить длительность, звук и начать.'**
  String get coachCardStart;

  /// No description provided for @coachSetupFeedback.
  ///
  /// In ru, this message translates to:
  /// **'Включите звук, метроном или вибрацию — как удобно.'**
  String get coachSetupFeedback;

  /// No description provided for @coachDismiss.
  ///
  /// In ru, this message translates to:
  /// **'Понятно'**
  String get coachDismiss;

  /// No description provided for @replayOnboarding.
  ///
  /// In ru, this message translates to:
  /// **'Показать обучение заново'**
  String get replayOnboarding;

  /// No description provided for @onboardingReset.
  ///
  /// In ru, this message translates to:
  /// **'Подсказки будут показаны снова'**
  String get onboardingReset;

  /// No description provided for @pauseAction.
  ///
  /// In ru, this message translates to:
  /// **'Пауза'**
  String get pauseAction;

  /// No description provided for @resumeAction.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить'**
  String get resumeAction;

  /// No description provided for @stopAction.
  ///
  /// In ru, this message translates to:
  /// **'Стоп'**
  String get stopAction;

  /// No description provided for @prepGetReady.
  ///
  /// In ru, this message translates to:
  /// **'Приготовьтесь'**
  String get prepGetReady;

  /// No description provided for @cycleLabel.
  ///
  /// In ru, this message translates to:
  /// **'Цикл'**
  String get cycleLabel;

  /// No description provided for @sessionDone.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get sessionDone;

  /// No description provided for @sessionDoneTapHint.
  ///
  /// In ru, this message translates to:
  /// **'Коснитесь круга, чтобы закрыть'**
  String get sessionDoneTapHint;

  /// No description provided for @whBreathsLabel.
  ///
  /// In ru, this message translates to:
  /// **'Дыханий в раунде'**
  String get whBreathsLabel;

  /// No description provided for @whPaceLabel.
  ///
  /// In ru, this message translates to:
  /// **'Темп дыхания'**
  String get whPaceLabel;

  /// No description provided for @whPaceValue.
  ///
  /// In ru, this message translates to:
  /// **'{sec} с на дыхание'**
  String whPaceValue(String sec);

  /// No description provided for @whRoundsLabel.
  ///
  /// In ru, this message translates to:
  /// **'Раундов'**
  String get whRoundsLabel;

  /// No description provided for @whWarningTitle.
  ///
  /// In ru, this message translates to:
  /// **'Перед началом'**
  String get whWarningTitle;

  /// No description provided for @whAcceptStart.
  ///
  /// In ru, this message translates to:
  /// **'Понимаю риски — начать'**
  String get whAcceptStart;

  /// No description provided for @whBackAction.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get whBackAction;

  /// No description provided for @whRoundOf.
  ///
  /// In ru, this message translates to:
  /// **'Раунд {r} из {n}'**
  String whRoundOf(int r, int n);

  /// No description provided for @whBreathePrompt.
  ///
  /// In ru, this message translates to:
  /// **'Дышите глубоко и мощно — в ритме круга'**
  String get whBreathePrompt;

  /// No description provided for @whExhaleHold.
  ///
  /// In ru, this message translates to:
  /// **'Выдохните — и не дышите'**
  String get whExhaleHold;

  /// No description provided for @whTapWhenUrge.
  ///
  /// In ru, this message translates to:
  /// **'Коснитесь экрана, когда захочется вдохнуть'**
  String get whTapWhenUrge;

  /// No description provided for @whBreatheInStop.
  ///
  /// In ru, this message translates to:
  /// **'Вдох'**
  String get whBreatheInStop;

  /// No description provided for @whRecoveryPrompt.
  ///
  /// In ru, this message translates to:
  /// **'Глубокий вдох — и держите'**
  String get whRecoveryPrompt;

  /// No description provided for @whRetentionLabel.
  ///
  /// In ru, this message translates to:
  /// **'Задержка'**
  String get whRetentionLabel;

  /// No description provided for @whResultsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Задержки по раундам'**
  String get whResultsTitle;

  /// No description provided for @whRoundShort.
  ///
  /// In ru, this message translates to:
  /// **'Раунд {r}'**
  String whRoundShort(int r);

  /// No description provided for @sessionMediaTitle.
  ///
  /// In ru, this message translates to:
  /// **'Дыхательная сессия'**
  String get sessionMediaTitle;

  /// No description provided for @sizeUnitsCsv.
  ///
  /// In ru, this message translates to:
  /// **'Б,КБ,МБ,ГБ'**
  String get sizeUnitsCsv;

  /// No description provided for @boltTitle.
  ///
  /// In ru, this message translates to:
  /// **'Дыхательный тест'**
  String get boltTitle;

  /// No description provided for @boltEntrySubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Оцените, как дыхание переносит паузу'**
  String get boltEntrySubtitle;

  /// No description provided for @boltIntroHeading.
  ///
  /// In ru, this message translates to:
  /// **'Как это работает'**
  String get boltIntroHeading;

  /// No description provided for @boltIntro.
  ///
  /// In ru, this message translates to:
  /// **'BOLT — показатель того, насколько комфортно вы переносите накопление CO₂ после спокойного выдоха. Он отражает текущую чувствительность дыхания и обычно растёт при регулярной практике.\n\nИзмеряйте в покое, лучше утром и в одинаковых условиях — так число сравнимо со вчерашним.'**
  String get boltIntro;

  /// No description provided for @boltMethodHeading.
  ///
  /// In ru, this message translates to:
  /// **'Как измерять'**
  String get boltMethodHeading;

  /// No description provided for @boltMethod.
  ///
  /// In ru, this message translates to:
  /// **'Сядьте спокойно и сделайте несколько обычных вдохов-выдохов. Затем сделайте спокойный, НЕ максимальный выдох через нос, зажмите нос и засеките время.\n\nОстановитесь при первом непроизвольном позыве — подёргивание диафрагмы, желание сглотнуть, первое напряжение. Это не соревнование на терпение: первый вдох после теста должен быть спокойным.'**
  String get boltMethod;

  /// No description provided for @boltDisclaimer.
  ///
  /// In ru, this message translates to:
  /// **'BOLT не является клиническим диагностическим тестом. Результат отражает текущую чувствительность дыхания, а не медицинское состояние. При проблемах с дыханием обратитесь к врачу.'**
  String get boltDisclaimer;

  /// No description provided for @boltStartAction.
  ///
  /// In ru, this message translates to:
  /// **'Начать тест'**
  String get boltStartAction;

  /// No description provided for @boltPrepHint.
  ///
  /// In ru, this message translates to:
  /// **'Дышите спокойно и приготовьтесь'**
  String get boltPrepHint;

  /// No description provided for @boltHoldInstruction.
  ///
  /// In ru, this message translates to:
  /// **'Задержите дыхание после спокойного выдоха'**
  String get boltHoldInstruction;

  /// No description provided for @boltFirstUrgeHint.
  ///
  /// In ru, this message translates to:
  /// **'Коснитесь экрана при первом позыве вдохнуть'**
  String get boltFirstUrgeHint;

  /// No description provided for @boltStopAction.
  ///
  /// In ru, this message translates to:
  /// **'Первый позыв — стоп'**
  String get boltStopAction;

  /// No description provided for @boltResultHeading.
  ///
  /// In ru, this message translates to:
  /// **'Ваш результат'**
  String get boltResultHeading;

  /// No description provided for @boltSecondsValue.
  ///
  /// In ru, this message translates to:
  /// **'{seconds} с'**
  String boltSecondsValue(int seconds);

  /// No description provided for @boltRangeLabel.
  ///
  /// In ru, this message translates to:
  /// **'Диапазон {range} с'**
  String boltRangeLabel(String range);

  /// No description provided for @boltLevelLow.
  ///
  /// In ru, this message translates to:
  /// **'Низкая толерантность к CO₂'**
  String get boltLevelLow;

  /// No description provided for @boltLevelLowDesc.
  ///
  /// In ru, this message translates to:
  /// **'Дыхание сейчас чувствительно к CO₂ — это часто у тех, кто дышит часто и поверхностно. Хорошая новость: показатель тренируется. Помогут спокойные практики с удлинённым выдохом.'**
  String get boltLevelLowDesc;

  /// No description provided for @boltLevelMedium.
  ///
  /// In ru, this message translates to:
  /// **'Средняя толерантность'**
  String get boltLevelMedium;

  /// No description provided for @boltLevelMediumDesc.
  ///
  /// In ru, this message translates to:
  /// **'Обычная реактивность дыхания в покое. Регулярная спокойная практика мягко сдвигает результат вверх.'**
  String get boltLevelMediumDesc;

  /// No description provided for @boltLevelHigh.
  ///
  /// In ru, this message translates to:
  /// **'Высокая толерантность'**
  String get boltLevelHigh;

  /// No description provided for @boltLevelHighDesc.
  ///
  /// In ru, this message translates to:
  /// **'Дыхание спокойно переносит накопление CO₂. Так держать — поддерживайте ровный носовой ритм.'**
  String get boltLevelHighDesc;

  /// No description provided for @boltLevelVeryHigh.
  ///
  /// In ru, this message translates to:
  /// **'Очень высокая толерантность'**
  String get boltLevelVeryHigh;

  /// No description provided for @boltLevelVeryHighDesc.
  ///
  /// In ru, this message translates to:
  /// **'Такой результат обычно у тренированных. Не гонитесь за рекордом: важнее ровное комфортное дыхание в жизни.'**
  String get boltLevelVeryHighDesc;

  /// No description provided for @boltSaveAction.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить результат'**
  String get boltSaveAction;

  /// No description provided for @boltRetryAction.
  ///
  /// In ru, this message translates to:
  /// **'Ещё раз'**
  String get boltRetryAction;

  /// No description provided for @boltHistoryTitle.
  ///
  /// In ru, this message translates to:
  /// **'Динамика'**
  String get boltHistoryTitle;

  /// No description provided for @boltLatestLabel.
  ///
  /// In ru, this message translates to:
  /// **'Последний результат'**
  String get boltLatestLabel;

  /// No description provided for @boltHistoryEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет результатов — пройдите тест, чтобы отслеживать динамику.'**
  String get boltHistoryEmpty;

  /// No description provided for @boltProgressHint.
  ///
  /// In ru, this message translates to:
  /// **'Сравнивайте результаты в одинаковых условиях: разброс день ото дня — это норма, смотрите на тренд.'**
  String get boltProgressHint;
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
