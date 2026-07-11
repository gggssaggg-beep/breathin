import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/update/update_preferences.dart';
import '../../services/update/update_runtime.dart';
import '../../services/update/update_service.dart';
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
  String? _version;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.accountSection, style: Theme.of(context).textTheme.titleSmall),
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
            onUpdateNow: _downloadUpdate,
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
