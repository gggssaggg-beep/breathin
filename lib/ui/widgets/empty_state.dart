import 'package:flutter/material.dart';

import '../icons/breathin_icon.dart';
import '../icons/breathin_icons.dart';

/// Заглушка/гейт-состояние: крупная иконка + сообщение + 0..2 действия.
///
/// Иконка 56, цвет outline/onSurfaceVariant (приглушённый). Текст по центру.
/// [actions] — уже собранные кнопки (SizedBox.expand/FilledButton/Outlined).
/// Виджет сам оборачивает каждое действие в [SizedBox(width: double.infinity)],
/// поэтому кнопки передаются без ширины.
class EmptyState extends StatelessWidget {
  final BreathinIconData icon;
  final String message;
  final List<Widget> actions;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BreathinIcon(
              icon,
              size: 56,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            for (final action in actions) ...[
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: action),
            ],
          ],
        ),
      ),
    );
  }
}
