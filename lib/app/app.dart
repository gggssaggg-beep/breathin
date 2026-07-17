import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/home/home_screen.dart';
import '../features/onboarding/coach_controller.dart';
import '../features/onboarding/welcome_screen.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/locale/locale_store.dart';
import '../services/onboarding/coach_store.dart';
import '../services/permissions/notification_permission.dart';
import '../services/update/update_preferences.dart';
import '../services/update/update_runtime.dart';
import '../services/update/update_service.dart';
import 'hant_theme.dart';

/// Корень приложения «Дыши». Тема светлая/тёмная по системной настройке
/// (ТЗ §7). Навигация — Navigator (go_router подключим в партии маршрутов).
/// Локализация подключена через flutter gen-l10n (lib/l10n/app_ru.arb + app_en.arb).
class BreathinApp extends StatefulWidget {
  /// Отключается в тестах: проверка обновлений при старте не нужна.
  final bool checkUpdates;

  /// Отключается в тестах: приветственный экран и коучмарки не нужны.
  final bool showOnboarding;

  const BreathinApp({
    super.key,
    this.checkUpdates = true,
    this.showOnboarding = true,
  });

  @override
  State<BreathinApp> createState() => _BreathinAppState();
}

class _BreathinAppState extends State<BreathinApp> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  // Ключ Navigator'а: приветствие показываем через showDialog из контекста
  // ПОД Navigator. Контекст ScaffoldMessenger выше него — оттуда Navigator
  // не находится, и диалог не открылся бы.
  final _navKey = GlobalKey<NavigatorState>();
  final _store = CoachStore();
  late final CoachController _coachController;

  @override
  void initState() {
    super.initState();
    _coachController = CoachController(store: _store);
    if (widget.showOnboarding) {
      // Загружаем данные контроллера подсказок.
      _coachController.init();
    }
    if (widget.checkUpdates) _checkUpdatesOnStart();
    // Разрешение на уведомления (Android 13+, медиа-уведомление сессии) —
    // после первого кадра, чтобы системный диалог лёг поверх готового UI.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationPermission.ensureRequestedOnce();
      if (widget.showOnboarding) _maybeShowWelcome();
    });
  }

  @override
  void dispose() {
    _coachController.dispose();
    super.dispose();
  }

  /// Показывает приветственный экран, если пользователь ещё его не видел.
  /// Вызывается после первого кадра через addPostFrameCallback — безопасно.
  Future<void> _maybeShowWelcome() async {
    final seen = await _store.welcomeSeen();
    if (seen) return;
    if (!mounted) return;
    final ctx = _navKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    await showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => WelcomeScreen(store: _store),
    );
  }

  /// Тихая OTA-проверка при запуске (запрос пользователя): если на GitHub
  /// есть релиз новее — SnackBar с кнопкой скачивания APK. Ошибки сети
  /// молча игнорируются.
  Future<void> _checkUpdatesOnStart() async {
    // Уважаем галочку «Автообновление»: если выключена — не проверяем.
    // В тестах prefs-плагина нет — тогда считаем включённым (дефолт).
    bool auto = true;
    try {
      auto = (await UpdatePreferencesStore().load()).autoUpdate;
    } catch (_) {}
    if (!auto) return;
    final result = await checkForUpdate();
    final info = result.info;
    if (result.availability != UpdateAvailability.available || info == null) {
      return;
    }
    if (!mounted) return;
    final messenger = _messengerKey.currentState;
    final messengerContext = _messengerKey.currentContext;
    if (messenger == null ||
        messengerContext == null ||
        !messengerContext.mounted) {
      return;
    }
    final l = AppLocalizations.of(messengerContext);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${l.updateAvailableSnack(info.version.toString())}'
          ' · ${info.humanSizeWith(l.sizeUnitsCsv)}',
        ),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: l.updateDownloadAction,
          onPressed: () => launchUrl(
            Uri.parse(info.downloadUrl),
            mode: LaunchMode.externalApplication,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // HANT — единственный интерфейс (решение владельца 2026-07-17):
    // классическая тема скрыта из UI, код остаётся в проекте (AppTheme
    // держит контекстные хелперы), удалить из приложения в следующей сборке.
    return ValueListenableBuilder<Locale?>(
        valueListenable: localeNotifier,
        builder: (context, locale, _) => MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          navigatorKey: _navKey,
          scaffoldMessengerKey: _messengerKey,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          theme: HantTheme.dark(),
          darkTheme: HantTheme.dark(),
          themeMode: ThemeMode.dark,
          // CoachScope вставляется через builder ВНУТРЬ MaterialApp (после
          // локализаций и темы), но ВЫШЕ Navigator — так он доступен всем
          // экранам через CoachScope.of(context) и не вызывает бесконечный
          // rebuild самого MaterialApp.
          builder: (context, child) => CoachScope(
            controller: _coachController,
            child: child!,
          ),
          home: HomeScreen(),
        ));
  }
}
