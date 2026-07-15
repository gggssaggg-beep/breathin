import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/bolt_repository.dart';
import '../../data/difficulty_store.dart';
import '../../domain/difficulty/difficulty.dart';
import '../../features/onboarding/coach_controller.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/locale/locale_store.dart';
import '../../services/update/update_preferences.dart';
import 'difficulty_section.dart';
import '../../services/update/update_runtime.dart';
import '../../services/update/update_service.dart';
import '../../ui/icons/breathin_icon.dart';
import '../../ui/icons/breathin_icons.dart';
import 'account_section.dart';
import 'update_section.dart';

/// Экран настроек (ТЗ §6.8): аккаунт, обновления, версия. Голос, звуки,
/// вибрация, тема, язык и напоминания добавляются в партии настроек (П12).
class SettingsScreen extends StatefulWidget {
  /// Отключается в тестах (сетевой запрос к GitHub API не нужен).
  final bool checkUpdates;
  const SettingsScreen({super.key, this.checkUpdates = true});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UpdatePreferences _prefs = const UpdatePreferences();
  UpdateCheckResult _update = UpdateCheckResult.upToDate;
  DifficultyPreset _difficulty = DifficultyPreset.breeze;
  AppLanguage _language = AppLanguage.system;
  bool _hasBoltResult = false;
  String? _version;

  @override
  void initState() {
    super.initState();
    // Персист настроек обновлений: поднимаем сохранённое значение галочки.
    UpdatePreferencesStore().load().then((p) {
      if (mounted) setState(() => _prefs = p);
    });
    DifficultyStore().load().then((p) {
      if (mounted) setState(() => _difficulty = p);
    });
    LocaleStore().load().then((lang) {
      if (mounted) setState(() => _language = lang);
    });
    BoltRepository().all().then((r) {
      if (mounted) setState(() => _hasBoltResult = r.isNotEmpty);
    });
    currentAppVersion().then((v) {
      if (mounted && v != null) setState(() => _version = v.toString());
    });
    if (widget.checkUpdates) {
      checkForUpdate().then((r) {
        if (mounted) setState(() => _update = r);
      });
    }
  }

  void _downloadUpdate() {
    final info = _update.info;
    if (info == null) return;
    launchUrl(Uri.parse(info.downloadUrl),
        mode: LaunchMode.externalApplication);
  }

  void _onAutoUpdateChanged(bool v) {
    setState(() => _prefs = _prefs.copyWith(autoUpdate: v));
    // Сохраняем fire-and-forget — UI не ждёт записи в prefs.
    UpdatePreferencesStore().save(_prefs);
  }

  void _onDifficultyChanged(DifficultyPreset p) {
    setState(() => _difficulty = p);
    DifficultyStore().save(p);
  }

  void _onLanguageChanged(AppLanguage lang) {
    setState(() => _language = lang);
    LocaleStore().save(lang);
    localeNotifier.value = localeFor(lang);
  }

  /// Открывает внешнюю ссылку (Telegram) в браузере/приложении.
  void _openUrl(String url) {
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  /// Сбрасывает все подсказки и приветствие через [CoachController].
  /// Показывает SnackBar с подтверждением.
  Future<void> _resetOnboarding(BuildContext context) async {
    final l = AppLocalizations.of(context);
    // Захватываем messenger до async-зазора (use_build_context_synchronously).
    final messenger = ScaffoldMessenger.of(context);
    // CoachScope может отсутствовать в тестах — обрабатываем аккуратно.
    try {
      final controller = CoachScope.of(context);
      await controller.resetAll();
    } catch (_) {}
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(l.onboardingReset)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.accountSection, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          const AccountSection(),
          const SizedBox(height: 24),
          Text(l.updatesSection,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          UpdateSection(
            result: _update,
            autoUpdate: _prefs.autoUpdate,
            onAutoUpdateChanged: _onAutoUpdateChanged,
            onUpdateNow: _downloadUpdate,
          ),
          const SizedBox(height: 24),
          // --- Язык ---
          Text(l.languageSection,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<AppLanguage>(
            segments: [
              ButtonSegment(
                value: AppLanguage.system,
                label: Text(l.languageSystem),
              ),
              const ButtonSegment(
                value: AppLanguage.ru,
                label: Text('Русский'),
              ),
              const ButtonSegment(
                value: AppLanguage.en,
                label: Text('English'),
              ),
            ],
            selected: {_language},
            onSelectionChanged: (v) => _onLanguageChanged(v.first),
          ),
          const SizedBox(height: 24),
          // --- Сложность: глобальный пресет длительностей (эпик §4–5) ---
          Text(l.difficultySection,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          DifficultySection(
            preset: _difficulty,
            hasBoltResult: _hasBoltResult,
            onChanged: _onDifficultyChanged,
          ),
          const SizedBox(height: 24),
          // --- Сообщество: обратная связь и чат (внешние ссылки Telegram) ---
          Text(l.communitySection,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const BreathinIcon(BreathinIcons.send),
            title: Text(l.feedbackAction),
            trailing: const BreathinIcon(BreathinIcons.chevronRight, size: 20),
            onTap: () => _openUrl('https://t.me/U314159'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const BreathinIcon(BreathinIcons.send),
            title: Text(l.communityChatAction),
            trailing: const BreathinIcon(BreathinIcons.chevronRight, size: 20),
            // Ссылка на конкретное сообщение в телеграм-канале (так задумано).
            onTap: () => _openUrl('https://t.me/Hant_Live/257'),
          ),
          const SizedBox(height: 24),
          // --- Обучение: сброс подсказок и приветствия ---
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const BreathinIcon(BreathinIcons.refresh),
            title: Text(l.replayOnboarding),
            trailing: const BreathinIcon(BreathinIcons.chevronRight, size: 20),
            onTap: () => _resetOnboarding(context),
          ),
          if (_version != null) ...[
            const SizedBox(height: 24),
            Center(
              child: Text(
                l.appVersionLabel(_version!),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
