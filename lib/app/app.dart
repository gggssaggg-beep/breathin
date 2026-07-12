import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/home/home_screen.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/permissions/notification_permission.dart';
import '../services/update/update_runtime.dart';
import '../services/update/update_service.dart';
import 'theme.dart';

/// Корень приложения «Дыши». Тема светлая/тёмная по системной настройке
/// (ТЗ §7). Навигация — Navigator (go_router подключим в партии маршрутов).
/// Локализация подключена через flutter gen-l10n (lib/l10n/app_ru.arb + app_en.arb).
class BreathinApp extends StatefulWidget {
  /// Отключается в тестах: проверка обновлений при старте не нужна.
  final bool checkUpdates;
  const BreathinApp({super.key, this.checkUpdates = true});

  @override
  State<BreathinApp> createState() => _BreathinAppState();
}

class _BreathinAppState extends State<BreathinApp> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    if (widget.checkUpdates) _checkUpdatesOnStart();
    // Разрешение на уведомления (Android 13+, медиа-уведомление сессии) —
    // после первого кадра, чтобы системный диалог лёг поверх готового UI.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => NotificationPermission.ensureRequestedOnce(),
    );
  }

  /// Тихая OTA-проверка при запуске (запрос пользователя): если на GitHub
  /// есть релиз новее — SnackBar с кнопкой скачивания APK. Ошибки сети
  /// молча игнорируются.
  Future<void> _checkUpdatesOnStart() async {
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
          ' · ${info.humanSize}',
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
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
