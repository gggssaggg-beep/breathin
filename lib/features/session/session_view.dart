import 'package:flutter/material.dart';

import '../../domain/engine/phase_engine.dart';
import '../../domain/models/technique.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../ui/icons/breathin_icon.dart';
import '../../ui/icons/breathin_icons.dart';
import 'breathing_painter.dart';
import 'phase_labels.dart';

/// Презентационный экран сессии: чистая функция от [SessionState]. Не знает про
/// аудио, плеер и таймеры — состояние подаёт контроллер. Поэтому тестируется
/// обычным виджет-тестом (ПЛАН §7, ТЗ §6.5).
///
/// Дыхательная фигура — CustomPainter [BreathingPainter] (партия П9):
/// круг, квадрат или треугольник по [shape].
///
/// Управление (ТЗ §6.5, корректировки владельца №9 и №14): во время сессии —
/// отдельные «Пауза/Продолжить» и «Стоп»; на финише кнопки исчезают, круг
/// заливается приятным цветом, тап по нему закрывает экран.
class SessionView extends StatelessWidget {
  final SessionState state;
  final VisualShape shape;
  final bool paused;
  final VoidCallback? onPauseResume;
  final VoidCallback? onStop;

  const SessionView({
    super.key,
    required this.state,
    required this.shape,
    this.paused = false,
    this.onPauseResume,
    this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final finished = state.isFinished;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _CycleHeader(
                cycleIndex: state.cycleIndex,
                totalCycles: state.totalCycles,
              ),
              Expanded(
                // На невысоких экранах (iPhone) фигура вместе с подписью под
                // ней раньше вылезала за пределы области и накрывалась
                // прогрессом и кнопками (отзыв №4). FittedBox сжимает всю
                // связку под доступную высоту, не увеличивая сверх натурального
                // размера, — подпись «Вдох/Выдох» больше не перекрывается.
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: finished
                        ? _finishedFigure(theme, l)
                        : _breathingFigure(theme, l),
                  ),
                ),
              ),
              _SessionProgress(
                elapsedMs: state.sessionElapsedMs,
                durationMs: state.sessionDurationMs,
              ),
              const SizedBox(height: 16),
              if (finished)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    l.sessionDoneTapHint,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: onPauseResume,
                        icon: BreathinIcon(
                          paused
                              ? BreathinIcons.playerPlay
                              : BreathinIcons.playerPause,
                          size: 20,
                        ),
                        label:
                            Text(paused ? l.resumeAction : l.pauseAction),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: onStop,
                        icon: const BreathinIcon(
                          BreathinIcons.playerStop,
                          size: 20,
                        ),
                        label: Text(l.stopAction),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Финиш (влад. §14): круг приятного цвета с галочкой; тап — закрыть.
  /// Дофаминовая точка: сессия завершена, никаких кнопок.
  Widget _finishedFigure(ThemeData theme, AppLocalizations l) {
    return Semantics(
      button: true,
      label: l.sessionDoneTapHint,
      child: GestureDetector(
        onTap: onStop,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primaryContainer,
              ),
              alignment: Alignment.center,
              child: Text(
                // Текстовый глиф, не эмодзи: эмодзи ОС-зависимы (RESOURCES_ICONS).
                '✓',
                style: theme.textTheme.displayLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(l.sessionDone, style: theme.textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }

  Widget _breathingFigure(ThemeData theme, AppLocalizations l) {
    final (title, number) = _titleAndNumber(l);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 260,
          width: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Дыхательная фигура (CustomPainter)
              CustomPaint(
                size: const Size(260, 260),
                painter: BreathingPainter(
                  shape: shape,
                  state: state,
                  primary: theme.colorScheme.primary,
                  outline: theme.colorScheme.outline,
                ),
              ),
              // Число секунд поверх фигуры
              Text(
                number,
                style: theme.textTheme.displayMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        // Заголовок фазы под фигурой
        Text(
          title,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Заголовок и крупное число для текущей стадии (финиш — отдельный виджет).
  (String, String) _titleAndNumber(AppLocalizations l) {
    switch (state.stage) {
      case SessionStage.prep:
        final sec = (state.prepRemainingMs / 1000).ceil();
        return (l.prepGetReady, '$sec');
      case SessionStage.finished:
        return (l.sessionDone, '✓'); // недостижимо: финиш рисуется отдельно
      case SessionStage.breathing:
        return (
          phaseLabel(l, state.phase!),
          '${state.phaseRemainingSec}',
        );
    }
  }
}

class _CycleHeader extends StatelessWidget {
  final int cycleIndex;
  final int totalCycles;
  const _CycleHeader({required this.cycleIndex, required this.totalCycles});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // cycleIndex 0-based; показываем 1-based, во время подготовки — тире.
    final label =
        cycleIndex < 0 ? '—' : '${cycleIndex + 1} / $totalCycles';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('${l.cycleLabel} ', style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _SessionProgress extends StatelessWidget {
  final int elapsedMs;
  final int durationMs;
  const _SessionProgress({required this.elapsedMs, required this.durationMs});

  @override
  Widget build(BuildContext context) {
    final value = durationMs <= 0 ? 0.0 : (elapsedMs / durationMs).clamp(0, 1);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(value: value.toDouble(), minHeight: 8),
    );
  }
}
