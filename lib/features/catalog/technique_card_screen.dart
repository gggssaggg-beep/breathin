import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../domain/models/technique.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../l10n/technique_texts.dart';
import '../../ui/icons/breathin_icon.dart';
import '../../ui/icons/breathin_icons.dart';
import '../session_setup/session_setup_screen.dart';
import 'technique_icons.dart';
import 'technique_subtitle.dart';

/// Цвет метки-солнышка бодрящих техник (влад. §10) — мягкий амбер.
const _energizingSun = Color(0xFFF9A825);

/// Экран «Описание техники» (ТЗ §6.3).
///
/// Отображает крупную иконку, подпись-паттерн, три секции
/// (описание / польза / безопасность) и круглую кнопку старта в стиле
/// «ряби» иконки приложения (влад. §5). Для counted-техник кнопка активна
/// и запускает [SessionRunner]; для timer, wimHof и stage2-техник — disabled
/// с подписью comingSoonStage2. У бодрящих техник рядом с названием — солнышко.
class TechniqueCardScreen extends StatelessWidget {
  final Technique technique;

  const TechniqueCardScreen({super.key, required this.technique});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final t = technique;

    final bool canStart =
        t.type == TechniqueType.counted && !t.stage2 && t.phases != null;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(l.techniqueName(t))),
            // Солнышко бодрящих техник рядом с названием (влад. §10).
            if (t.energizing) ...[
              const SizedBox(width: 8),
              const BreathinIcon(
                BreathinIcons.sun,
                size: 18,
                color: _energizingSun,
              ),
            ],
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Прокручиваемое тело
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                children: [
                  // Крупная иконка
                  Center(
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: BreathinIcon(
                        iconDataFor(t.icon),
                        size: 48,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Подпись-паттерн
                  Center(
                    child: Text(
                      techniqueSubtitle(l, t),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  // Бейдж «скоро» для stage2-техник
                  if (t.stage2) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Chip(
                        label: Text(l.comingSoonStage2),
                        labelStyle: theme.textTheme.labelSmall,
                        backgroundColor:
                            theme.colorScheme.secondaryContainer,
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 0),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Секция: Описание
                  _SectionHeader(title: l.sectionDescription),
                  const SizedBox(height: 8),
                  Text(
                    l.techniqueDescription(t),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),

                  // Секция: Польза
                  _SectionHeader(title: l.sectionBenefit),
                  const SizedBox(height: 8),
                  Text(
                    l.techniqueBenefit(t),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),

                  // Секция: Безопасность
                  _SectionHeader(title: l.sectionSafety),
                  const SizedBox(height: 8),
                  _SafetySection(technique: t),
                  const SizedBox(height: 20),

                  // Подсказка новичкам
                  if (t.recommendedMaxCyclesNovice != null) ...[
                    _NoviceHint(n: t.recommendedMaxCyclesNovice!),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),

            // Круглая кнопка старта в стиле «ряби» иконки приложения (влад. §5)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StartRippleButton(
                    enabled: canStart,
                    label: l.startSession,
                    onTap: canStart ? () => _startSession(context) : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.startSession,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (!canStart) ...[
                    const SizedBox(height: 8),
                    Text(
                      l.comingSoonStage2,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startSession(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionSetupScreen(technique: technique),
      ),
    );
  }
}

/// Заголовок секции.
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// Секция безопасности: high — Card с красным errorContainer, medium — Card
/// с мягким амбером (красный слишком ярок; корректировка владельца), low —
/// обычный текст.
class _SafetySection extends StatelessWidget {
  final Technique technique;
  const _SafetySection({required this.technique});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final text = l.safetyText(technique);

    if (technique.safetyLevel == SafetyLevel.high) {
      return Card(
        color: theme.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
        ),
      );
    }

    if (technique.safetyLevel == SafetyLevel.medium) {
      final b = theme.brightness;
      return Card(
        color: AppTheme.warningContainer(b),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.onWarningContainer(b),
            ),
          ),
        ),
      );
    }

    return Text(text, style: theme.textTheme.bodyMedium);
  }
}

/// Подсказка для новичков о максимальном числе циклов.
class _NoviceHint extends StatelessWidget {
  final int n;
  const _NoviceHint({required this.n});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Text(
      l.noviceCyclesHint(n),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

/// Диаметр круглой кнопки старта (влад. §5).
const double _startButtonSize = 72;

/// Круглая кнопка старта с рисунком-рябью по мотиву иконки приложения
/// (точка в центре + два затухающих кольца, см. assets/icon/icon.svg).
/// Активная — цвета primary/onPrimary; отключённая (canStart=false) —
/// приглушённая surfaceContainerHighest/onSurfaceVariant, тап игнорируется.
class _StartRippleButton extends StatelessWidget {
  final bool enabled;
  final String label;
  final VoidCallback? onTap;

  const _StartRippleButton({
    required this.enabled,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = enabled
        ? scheme.primary
        : scheme.surfaceContainerHighest;
    final fg = enabled
        ? scheme.onPrimary
        : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: bg,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const ValueKey('start_button'),
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: _startButtonSize,
            height: _startButtonSize,
            child: CustomPaint(
              painter: _StartRipplePainter(color: fg),
            ),
          ),
        ),
      ),
    );
  }
}

/// Рисует «рябь» поверх круглой кнопки: точка r≈6 в центре и два
/// концентрических кольца (штрих 2) с затуханием прозрачности 0.6 → 0.3.
class _StartRipplePainter extends CustomPainter {
  final Color color;

  const _StartRipplePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Центральная точка-«я».
    final dot = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(center, 6, dot);

    // Два затухающих кольца ряби.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..isAntiAlias = true;
    canvas
      ..drawCircle(center, 14, ring..color = color.withValues(alpha: 0.6))
      ..drawCircle(center, 22, ring..color = color.withValues(alpha: 0.3));
  }

  @override
  bool shouldRepaint(_StartRipplePainter oldDelegate) =>
      oldDelegate.color != color;
}
