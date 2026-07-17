import 'package:flutter/material.dart';

import 'hant_theme.dart';

/// Контекстные цветовые хелперы приложения.
///
/// Сама классическая тема (Material из seed-цвета, светлый/тёмный варианты)
/// УДАЛЕНА 2026-07-17 по решению владельца — интерфейс один, HANT
/// (см. hant_theme.dart). Хелперы остались: их ветки «без HantStyle»
/// покрывают виджет-тесты, пампающие голый MaterialApp без темы.
class AppTheme {
  /// Амбер-пара «внимание» единой плашки безопасности (ТЗ §2.4).
  static Color warningContainer(Brightness b) =>
      b == Brightness.light ? const Color(0xFFF8E1A0) : const Color(0xFF4E3B00);
  static Color onWarningContainer(Brightness b) =>
      b == Brightness.light ? const Color(0xFF4E3B00) : const Color(0xFFF8E1A0);

  /// Контекстный вариант warningContainer: в HANT — тёмный янтарный
  /// из палитры bg (`0xFF2A1F0C`), иначе — по Brightness.
  static Color warningContainerOf(BuildContext context) {
    if (Theme.of(context).extension<HantStyle>() != null) {
      return const Color(0xFF2A1F0C); // тёмный янтарный фон, в палитре HANT bg
    }
    return warningContainer(Theme.of(context).brightness);
  }

  /// Контекстный вариант onWarningContainer: в HANT — amberGlow (`0xFFFFC875`),
  /// иначе — по Brightness.
  static Color onWarningContainerOf(BuildContext context) {
    if (Theme.of(context).extension<HantStyle>() != null) {
      return const Color(0xFFFFC875); // amberGlow — светлый янтарь
    }
    return onWarningContainer(Theme.of(context).brightness);
  }

  /// Акцент «солнышко/звезда/пламя» бодрящих техник и избранного:
  /// в HANT — HantStyle.source (янтарь), без темы — тёплый янтарь.
  static Color accentSunColor(BuildContext context) {
    return Theme.of(context).extension<HantStyle>()?.source ??
        const Color(0xFFF9A825);
  }
}
