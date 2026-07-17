import 'package:flutter/material.dart';

/// Единый заголовок секции во всех экранах приложения.
/// Стиль: titleSmall + colorScheme.primary + FontWeight.w600.
class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
