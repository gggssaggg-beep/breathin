import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Единая плашка «Безопасность» (решение владельца 2026-07-17: одна на все
/// уровни риска — раньше high был красным, medium янтарным, low голым
/// текстом). Мягкая янтарная пара «внимание» в обеих темах; серьёзность
/// доносит сам текст, а у интенсивных техник (ВХ) остаётся отдельный
/// полноэкранный гейт с явным принятием рисков.
class SafetyCard extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry padding;

  const SafetyCard(this.text, {super.key, this.padding = const EdgeInsets.all(12)});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: AppTheme.warningContainerOf(context),
      child: Padding(
        padding: padding,
        child: Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.onWarningContainerOf(context),
          ),
        ),
      ),
    );
  }
}
