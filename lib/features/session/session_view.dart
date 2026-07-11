import 'package:flutter/material.dart';

import '../../domain/engine/phase_engine.dart';
import '../../domain/models/technique.dart';
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
class SessionView extends StatelessWidget {
  final SessionState state;
  final VisualShape shape;
  final VoidCallback? onPauseStop;

  const SessionView({
    super.key,
    required this.state,
    required this.shape,
    this.onPauseStop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              Expanded(child: Center(child: _breathingFigure(theme))),
              _SessionProgress(
                elapsedMs: state.sessionElapsedMs,
                durationMs: state.sessionDurationMs,
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: onPauseStop,
                icon: const BreathinIcon(BreathinIcons.playerStop, size: 20),
                label: const Text('Пауза / стоп'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _breathingFigure(ThemeData theme) {
    final (title, number) = _titleAndNumber();
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

  /// Заголовок и крупное число для текущей стадии.
  (String, String) _titleAndNumber() {
    switch (state.stage) {
      case SessionStage.prep:
        final sec = (state.prepRemainingMs / 1000).ceil();
        return ('Приготовьтесь', '$sec');
      case SessionStage.finished:
        // Текстовый глиф, не эмодзи: эмодзи ОС-зависимы (RESOURCES_ICONS).
        return ('Готово', '✓');
      case SessionStage.breathing:
        return (phaseLabelRu(state.phase!), '${state.phaseRemainingSec}');
    }
  }
}

class _CycleHeader extends StatelessWidget {
  final int cycleIndex;
  final int totalCycles;
  const _CycleHeader({required this.cycleIndex, required this.totalCycles});

  @override
  Widget build(BuildContext context) {
    // cycleIndex 0-based; показываем 1-based, во время подготовки — тире.
    final label =
        cycleIndex < 0 ? '—' : '${cycleIndex + 1} / $totalCycles';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Цикл ', style: Theme.of(context).textTheme.titleMedium),
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
