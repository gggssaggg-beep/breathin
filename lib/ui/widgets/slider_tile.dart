import 'package:flutter/material.dart';

/// Строка «метка — значение — слайдер».
///
/// Использовалась дословным дублем в timer_setup_screen.dart и
/// wim_hof_setup_screen.dart (комментарий в коде признавал дубль явно).
class SliderTile extends StatelessWidget {
  final String label;
  final String value;
  final Slider slider;

  const SliderTile({
    super.key,
    required this.label,
    required this.value,
    required this.slider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(value, style: theme.textTheme.bodyMedium),
          ],
        ),
        slider,
      ],
    );
  }
}
