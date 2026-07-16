import 'package:flutter/material.dart';

/// Токены HUD-графики темы HANT для CustomPainter-декораций (сетка-чертёж,
/// звёзды, прицел-ретикул дыхательной фигуры). Виджеты берут их через
/// `Theme.of(context).extension<HantStyle>()`: null → классическая тема,
/// декорации не рисуются.
class HantStyle extends ThemeExtension<HantStyle> {
  /// Циановая «проволочная» графика: кольца, скобки, активные метки.
  final Color wire;

  /// Приглушённый циан: статичные контуры, деления шкал, рамки карточек.
  final Color wireDim;

  /// Янтарь «источника»: ядро фигуры, акценты, CTA.
  final Color source;

  /// Светлый янтарь свечения вокруг ядра.
  final Color sourceGlow;

  /// Линии фоновой сетки-чертежа (едва различимые).
  final Color grid;

  const HantStyle({
    required this.wire,
    required this.wireDim,
    required this.source,
    required this.sourceGlow,
    required this.grid,
  });

  @override
  HantStyle copyWith({
    Color? wire,
    Color? wireDim,
    Color? source,
    Color? sourceGlow,
    Color? grid,
  }) {
    return HantStyle(
      wire: wire ?? this.wire,
      wireDim: wireDim ?? this.wireDim,
      source: source ?? this.source,
      sourceGlow: sourceGlow ?? this.sourceGlow,
      grid: grid ?? this.grid,
    );
  }

  @override
  HantStyle lerp(HantStyle? other, double t) {
    if (other == null) return this;
    return HantStyle(
      wire: Color.lerp(wire, other.wire, t)!,
      wireDim: Color.lerp(wireDim, other.wireDim, t)!,
      source: Color.lerp(source, other.source, t)!,
      sourceGlow: Color.lerp(sourceGlow, other.sourceGlow, t)!,
      grid: Color.lerp(grid, other.grid, t)!,
    );
  }
}

/// Тема HANT: техно-мистика по референсам VOZZRENYE — глубокий космический
/// тёмно-синий, светящийся циановый «wireframe», янтарный «источник»,
/// HUD-рамки. Только тёмный вариант (это часть стиля, не ограничение).
///
/// Шрифты: Golos Text (заголовки/текст, кириллица нативная) +
/// JetBrains Mono (разреженный капс HUD-надписей и цифры). Оба OFL,
/// статические веса в assets/fonts.
class HantTheme {
  // Палитра (снята с референсов pic/):
  static const bg = Color(0xFF070C16); // космический фон
  static const surface = Color(0xFF0C1424); // карточки
  static const surfaceHigh = Color(0xFF13203A); // приподнятые элементы
  static const cyan = Color(0xFF3FC9E8); // wireframe-акцент
  static const cyanDim = Color(0xFF29607D); // статичные контуры
  static const amber = Color(0xFFF0A63C); // «источник», CTA
  static const amberGlow = Color(0xFFFFC875); // свечение ядра
  static const text = Color(0xFFE9EFF8);
  static const textDim = Color(0xFF8DA2BE);
  static const grid = Color(0xFF16263F); // сетка-чертёж

  static const style = HantStyle(
    wire: cyan,
    wireDim: cyanDim,
    source: amber,
    sourceGlow: amberGlow,
    grid: grid,
  );

  /// Разреженный моно-капс HUD-надписей (только короткие подписи и цифры —
  /// НЕ основной текст: кириллица в моно для длинных строк читается плохо).
  static TextStyle _mono(double size,
      {FontWeight weight = FontWeight.w400,
      double spacing = 2,
      Color color = text}) {
    return TextStyle(
      fontFamily: 'JetBrainsMono',
      fontSize: size,
      fontWeight: weight,
      letterSpacing: spacing,
      color: color,
    );
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: amber,
      onPrimary: Color(0xFF221503),
      primaryContainer: Color(0xFF33250E),
      onPrimaryContainer: Color(0xFFFFD9A0),
      secondary: cyan,
      onSecondary: Color(0xFF04222B),
      secondaryContainer: Color(0xFF0F3444),
      onSecondaryContainer: Color(0xFFBFEAF6),
      error: Color(0xFFCF6679),
      onError: Color(0xFF140C0D),
      errorContainer: Color(0xFF3D1418),
      onErrorContainer: Color(0xFFF2B8BF),
      surface: surface,
      onSurface: text,
      surfaceContainerHighest: surfaceHigh,
      onSurfaceVariant: textDim,
      outline: cyanDim,
      outlineVariant: Color(0xFF1B3A52),
      inverseSurface: text,
      onInverseSurface: bg,
      shadow: Colors.black,
      scrim: Colors.black,
    );
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: 'GolosText',
      scaffoldBackgroundColor: bg,
    );
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        // Цифры сессии/таймера — моно, как показания прибора.
        displayMedium: _mono(45, spacing: 1),
        headlineMedium: base.textTheme.headlineMedium
            ?.copyWith(fontWeight: FontWeight.w600),
        headlineSmall: base.textTheme.headlineSmall
            ?.copyWith(fontWeight: FontWeight.w600),
        labelLarge: _mono(13.5, weight: FontWeight.w500, spacing: 1.2),
        labelMedium: _mono(12, spacing: 2, color: textDim),
        labelSmall: _mono(11, spacing: 2.5, color: textDim),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: _mono(15, weight: FontWeight.w500, spacing: 3.5,
            color: cyan),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          // Size(64, H), НЕ Size.fromHeight — тот отжимает Row (см. theme.dart).
          minimumSize: const Size(64, 52),
          textStyle: _mono(13.5, weight: FontWeight.w500, spacing: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          foregroundColor: cyan,
          side: const BorderSide(color: cyanDim),
          textStyle: _mono(13.5, weight: FontWeight.w500, spacing: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: cyanDim.withValues(alpha: 0.35)),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF1B3A52)),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceHigh,
        contentTextStyle: const TextStyle(
          fontFamily: 'GolosText',
          color: text,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: cyanDim.withValues(alpha: 0.5)),
        ),
      ),
      extensions: const [style],
    );
  }
}
