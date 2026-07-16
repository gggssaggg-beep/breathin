import 'package:flutter/material.dart';

import '../../app/hant_theme.dart';
import '../icons/breathin_icon.dart';
import '../icons/breathin_icons.dart';

/// Галочка Tabler «check» — ЛОКАЛЬНАЯ, не в общем наборе [BreathinIcons]:
/// глиф нужен только финишу, а счётчики набора в тестах не трогаем.
const _check = BreathinIconData(['M5 12l5 5l10 -10']);

/// Единый финиш сессии (аудит 2026-07-16 §3 High: раньше counted, таймер и
/// Вим Хоф завершались тремя разными экранами). Дофаминовая точка (влад. §14):
/// круг приятного цвета с галочкой, никаких кнопок, тап — закрыть.
///
/// [body] — опциональные результаты под заголовком (ВХ: задержки раундов).
/// [tapHint] — подсказка «тап — закрыть»; null, если экран-хозяин рисует её
/// сам в слоте кнопок (counted-сессия).
///
/// В HANT круг рисуется «источником»: янтарное свечение + циановое кольцо,
/// в рифму с прицелом дыхательной фигуры.
class SessionFinish extends StatelessWidget {
  final String title;
  final Widget? body;
  final String? tapHint;
  final VoidCallback? onClose;

  const SessionFinish({
    super.key,
    required this.title,
    this.body,
    this.tapHint,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hant = theme.extension<HantStyle>();
    // С телом (результаты ВХ) круг меньше — экран делится с таблицей.
    final diameter = body == null ? 220.0 : 140.0;

    final circle = Container(
      width: diameter,
      height: diameter,
      decoration: hant == null
          ? BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primaryContainer,
            )
          : BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  hant.sourceGlow.withValues(alpha: 0.5),
                  hant.source.withValues(alpha: 0.15),
                  hant.source.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
              border: Border.all(color: hant.wire, width: 1.5),
            ),
      alignment: Alignment.center,
      child: BreathinIcon(
        _check,
        size: diameter * 0.42,
        color: hant?.sourceGlow ?? theme.colorScheme.onPrimaryContainer,
      ),
    );

    return Semantics(
      button: true,
      label: tapHint ?? title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onClose,
        child: Center(
          // Низкие экраны: связка круг+заголовок+результаты сжимается,
          // не увеличиваясь сверх натурального (урок отзыва №4).
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                circle,
                const SizedBox(height: 28),
                Text(title, style: theme.textTheme.headlineSmall),
                if (body != null) ...[
                  const SizedBox(height: 20),
                  body!,
                ],
                if (tapHint != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    tapHint!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
