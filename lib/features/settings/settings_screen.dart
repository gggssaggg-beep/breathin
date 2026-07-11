import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/update/update_preferences.dart';
import '../../services/update/update_service.dart';
import 'account_section.dart';
import 'update_section.dart';

/// Экран настроек (ТЗ §6.8). Пока — только секция обновлений; голос, звуки,
/// вибрация, тема, язык и напоминания добавляются в партии настроек (П12).
///
/// Реальная проверка обновлений подключится, когда появится GitHub-репозиторий
/// с релизами (owner/repo + вызов [UpdateService.check] в initState). Сейчас
/// показываем состояние по умолчанию и рабочую галочку «Автообновление».
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UpdatePreferences _prefs = const UpdatePreferences();
  final UpdateCheckResult _update = UpdateCheckResult.upToDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(AppLocalizations.of(context).accountSection,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          const AccountSection(),
          const SizedBox(height: 24),
          Text('Обновления', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          UpdateSection(
            result: _update,
            autoUpdate: _prefs.autoUpdate,
            onAutoUpdateChanged: (v) =>
                setState(() => _prefs = _prefs.copyWith(autoUpdate: v)),
            onUpdateNow: () {
              // TODO(update): запустить скачивание+установку APK (Android).
            },
          ),
        ],
      ),
    );
  }
}
