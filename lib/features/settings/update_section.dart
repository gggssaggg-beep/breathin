import 'package:flutter/material.dart';

import '../../services/update/update_service.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          value: autoUpdate,
          onChanged: onAutoUpdateChanged,
          title: const Text('Автообновление'),
          subtitle: const Text('Тихо загружать обновления при открытии'),
          contentPadding: EdgeInsets.zero,
        ),
        if (result.availability == UpdateAvailability.available)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.system_update_rounded,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Доступно обновление ${result.info!.version}',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(result.info!.humanSize,
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: onUpdateNow,
                    child: const Text('Обновить'),
                  ),
                ],
              ),
            ),
          )
        else
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.check_circle_outline_rounded),
            title: Text(
              result.availability == UpdateAvailability.checkFailed
                  ? 'Не удалось проверить обновления'
                  : 'Установлена последняя версия',
            ),
          ),
      ],
    );
  }
}
