import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/update/update_service.dart';
import '../../ui/icons/breathin_icon.dart';
import '../../ui/icons/breathin_icons.dart';

/// Секция настроек «Обновления» (ТЗ §6.8 + запрос пользователя): галочка
/// «Автообновление» (вкл по умолчанию) и карточка доступного обновления с
/// показом размера файла. Презентационный виджет — состояние подаёт контроллер.
class UpdateSection extends StatelessWidget {
  final UpdateCheckResult result;
  final bool autoUpdate;
  final ValueChanged<bool> onAutoUpdateChanged;
  final VoidCallback? onUpdateNow;

  const UpdateSection({
    super.key,
    required this.result,
    required this.autoUpdate,
    required this.onAutoUpdateChanged,
    this.onUpdateNow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          value: autoUpdate,
          onChanged: onAutoUpdateChanged,
          title: Text(l.autoUpdateLabel),
          subtitle: Text(l.autoUpdateSubtitle),
          contentPadding: EdgeInsets.zero,
        ),
        if (result.availability == UpdateAvailability.available)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  BreathinIcon(BreathinIcons.download,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            l.updateAvailableTitle(
                                result.info!.version.toString()),
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(result.info!.humanSizeWith(l.sizeUnitsCsv),
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: onUpdateNow,
                    child: Text(l.updateNowAction),
                  ),
                ],
              ),
            ),
          )
        else
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const BreathinIcon(BreathinIcons.circleCheck),
            title: Text(
              result.availability == UpdateAvailability.checkFailed
                  ? l.updateCheckFailedNote
                  : l.upToDateNote,
            ),
          ),
      ],
    );
  }
}
