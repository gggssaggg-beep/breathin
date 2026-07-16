import 'package:flutter/material.dart';

import 'hant_theme.dart';

/// Тема приложения: спокойная сине-бирюзовая палитра, Material 3, светлый и
/// тёмный варианты (ТЗ §7). Один seed-цвет → согласованные схемы.
class AppTheme {
  static const _seed = Color(0xFF3E7C86); // приглушённый бирюзовый

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  /// Амбер-пара «внимание» для medium-предупреждений безопасности
  /// (ТЗ §2.4; красный errorContainer остаётся только для high).
  static Color warningContainer(Brightness b) =>
      b == Brightness.light ? const Color(0xFFF8E1A0) : const Color(0xFF4E3B00);
  static Color onWarningContainer(Brightness b) =>
      b == Brightness.light ? const Color(0xFF4E3B00) : const Color(0xFFF8E1A0);

  /// Контекстный вариант warningContainer: в HANT возвращает тёмный янтарный
  /// из палитры bg (`0xFF2A1F0C`), иначе — прежнее значение по Brightness.
  static Color warningContainerOf(BuildContext context) {
    if (Theme.of(context).extension<HantStyle>() != null) {
      return const Color(0xFF2A1F0C); // тёмный янтарный фон, в палитре HANT bg
    }
    return warningContainer(Theme.of(context).brightness);
  }

  /// Контекстный вариант onWarningContainer: в HANT — amberGlow (`0xFFFFC875`),
  /// иначе — прежнее значение по Brightness.
  static Color onWarningContainerOf(BuildContext context) {
    if (Theme.of(context).extension<HantStyle>() != null) {
      return const Color(0xFFFFC875); // amberGlow — светлый янтарь для читаемости
    }
    return onWarningContainer(Theme.of(context).brightness);
  }

  static ThemeData _base(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: true,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          // НЕ Size.fromHeight: он задаёт minWidth=infinity, и кнопка в Row
          // отжимает всю ширину (текст соседей ложится по букве в строку).
          // Полноширинные CTA оборачиваются в SizedBox(width: double.infinity).
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
