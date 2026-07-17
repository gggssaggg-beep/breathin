import 'package:flutter/material.dart';

import '../icons/breathin_icon.dart';
import '../icons/breathin_icons.dart';
import '../../app/hant_theme.dart';

/// Иконка в круге. Единая замена всем CircleAvatar+BreathinIcon.
///
/// Классика (нет HantStyle): CircleAvatar-заливка — точно как раньше:
///   - [primary] = true  → фон primary, иконка onPrimary (быстрый старт).
///   - [dimmed]  = true  → фон surfaceContainerHighest, иконка onSurfaceVariant.
///   - [background] задан → указанный цвет фона; иконка onPrimaryContainer.
///   - иначе             → фон primaryContainer, иконка onPrimaryContainer.
///
/// HANT (есть HantStyle): «HUD-чип» — прозрачный фон, тонкое кольцо [wireDim],
/// иконка цветом [wire]. Исключения:
///   - [dimmed] → иконка onSurfaceVariant, кольцо wireDim с alpha 0.4.
///   - [primary] → иконка source (янтарь), кольцо source.
///   - [background] задан → цвет кольца и иконки = [background].
///
/// Размер иконки ≈ radius (сохраняет пропорции классических потребителей:
/// radius 22 → size 22, radius 28 → size 28, radius 36 → size 36, radius 48 → size 48).
class IconBadge extends StatelessWidget {
  final BreathinIconData icon;
  final double radius;
  final bool dimmed;
  final bool primary;
  final Color? background;

  const IconBadge(
    this.icon, {
    super.key,
    this.radius = 24,
    this.dimmed = false,
    this.primary = false,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hant = Theme.of(context).extension<HantStyle>();

    if (hant != null) {
      // HANT: «HUD-чип» — прозрачный фон, тонкое кольцо, иконка wire/source.
      final Color ringColor;
      final Color iconColor;

      if (dimmed) {
        ringColor = hant.wireDim.withValues(alpha: 0.4);
        iconColor = scheme.onSurfaceVariant;
      } else if (primary) {
        ringColor = hant.source;
        iconColor = hant.source;
      } else if (background != null) {
        ringColor = background!;
        iconColor = background!;
      } else {
        ringColor = hant.wireDim;
        iconColor = hant.wire;
      }

      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ringColor, width: 1),
          color: Colors.transparent,
        ),
        child: Center(
          child: BreathinIcon(icon, size: radius, color: iconColor),
        ),
      );
    }

    // Классика: CircleAvatar с нужной цветовой веткой.
    final Color bgColor;
    final Color fgColor;

    if (primary) {
      bgColor = scheme.primary;
      fgColor = scheme.onPrimary;
    } else if (dimmed) {
      bgColor = scheme.surfaceContainerHighest;
      fgColor = scheme.onSurfaceVariant;
    } else if (background != null) {
      bgColor = background!;
      fgColor = scheme.onPrimaryContainer;
    } else {
      bgColor = scheme.primaryContainer;
      fgColor = scheme.onPrimaryContainer;
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: BreathinIcon(icon, size: radius, color: fgColor),
    );
  }
}
