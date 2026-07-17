import 'package:flutter/material.dart';

import '../../app/hant_theme.dart';
import '../icons/breathin_icon.dart';
import '../icons/breathin_icons.dart';

/// Тап-карточка: leading + title + subtitle + trailing.
///
/// Основа — [Card] + [InkWell] со скруглением из [CardTheme]. Отступы
/// внутри — horizontal 16, vertical 12 (как в _QuickStartCard).
///
/// [leading]  — любой виджет (обычно [IconBadge]).
/// [label]    — надпись НАД заголовком (bodySmall, onSurfaceVariant);
///              применяется только если указан (паттерн «быстрый старт»).
/// [title]    — основной текст (titleSmall).
/// [subtitle] — мелкий текст под заголовком (bodySmall, onSurfaceVariant);
///              null → не рендерится.
/// [trailing] — виджет справа; null → шеврон chevronRight 20 onSurfaceVariant.
/// [onTap]    — колбэк нажатия (null → карточка не интерактивна).
/// [color]    — переопределение фона карточки (напр. primaryContainer, secondaryContainer);
///              null → цвет из [CardTheme].
///
/// HANT: в режиме HANT-темы поверх [color] рисуется тонкий контур [wireDim],
/// чтобы карточки вписывались в «приборную» эстетику без сложной вёрстки.
class ListActionCard extends StatelessWidget {
  final Widget leading;
  final String? label;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? color;

  const ListActionCard({
    super.key,
    required this.leading,
    this.label,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hant = theme.extension<HantStyle>();

    // В HANT-теме добавляем контур wireDim поверх фона карточки.
    final ShapeBorder? hantShape = hant != null
        ? RoundedRectangleBorder(
            borderRadius:
                (theme.cardTheme.shape as RoundedRectangleBorder?)?.borderRadius
                    ?? BorderRadius.circular(12),
            side: BorderSide(color: hant.wireDim, width: 1),
          )
        : null;

    final Widget trailingWidget = trailing ??
        BreathinIcon(
          BreathinIcons.chevronRight,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        );

    return Card(
      color: color,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      shape: hantShape,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: (label != null || subtitle != null)
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (label != null)
                            Text(
                              label!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          Text(
                            title,
                            style: theme.textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              // 2 строки: подписи вроде «Оцените, как дыхание
                              // переносит паузу» раньше переносились —
                              // обрезка в 1 строку теряла смысл.
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      )
                    : Text(
                        title,
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              const SizedBox(width: 8),
              trailingWidget,
            ],
          ),
        ),
      ),
    );
  }
}
