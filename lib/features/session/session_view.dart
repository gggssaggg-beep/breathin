import 'package:flutter/material.dart';

import '../../app/hant_theme.dart';
import '../../domain/engine/phase_engine.dart';
import '../../domain/models/technique.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../ui/hant/hant_backdrop.dart';
import '../../ui/icons/breathin_icon.dart';
import '../../ui/icons/breathin_icons.dart';
import '../../ui/widgets/session_finish.dart';
import 'breathing_painter.dart';
import 'phase_labels.dart';
import 'segment_labels.dart';
import 'tap_pause_hint.dart';

/// Презентационный экран сессии: чистая функция от [SessionState]. Не знает про
/// аудио, плеер и таймеры — состояние подаёт контроллер. Поэтому тестируется
/// обычным виджет-тестом (ПЛАН §7, ТЗ §6.5).
///
/// Дыхательная фигура — CustomPainter [BreathingPainter] (партия П9):
/// круг, квадрат или треугольник по [shape].
///
/// Управление (ТЗ §6.5, корректировки владельца №9, №14 и 2026-07-16):
/// пауза/продолжение — тапом по любому месту экрана (в начале сессии —
/// растворяющаяся подсказка, на паузе — пилюля «тап — продолжить»); кнопка
/// одна — «Стоп». На финише кнопки исчезают, круг заливается приятным
/// цветом, тап по нему закрывает экран.
class SessionView extends StatelessWidget {
  final SessionState state;
  final VisualShape shape;
  final bool paused;
  final VoidCallback? onPauseResume;
  final VoidCallback? onStop;

  /// Текущий сегмент элементной техники; null — обычная техника без сегментов.
  final BreathSegment? segment;

  /// Тексты фраз фикра (№10): вдох и выдох уже резолвлены; null — техника
  /// без фраз. Показывается в том же слоте, что метка элемента (техники
  /// с сегментами и с фразами не пересекаются).
  final ({String inhale, String exhale})? phraseTexts;

  const SessionView({
    super.key,
    required this.state,
    required this.shape,
    this.paused = false,
    this.onPauseResume,
    this.onStop,
    this.segment,
    this.phraseTexts,
  });

  /// Фраза текущей фазы: вдох/выдох; на задержках и вне дыхания — null
  /// (у фикра задержек нет, но защищаемся от чужих конфигураций).
  String? _phraseFor() {
    final p = phraseTexts;
    if (p == null) return null;
    switch (state.phase) {
      case PhaseKind.inhale:
        return p.inhale;
      case PhaseKind.exhale:
        return p.exhale;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final finished = state.isFinished;
    final body = Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _CycleHeader(
                cycleIndex: state.cycleIndex,
                totalCycles: state.totalCycles,
              ),
              // Метка текущего элемента (только для элементных техник с сегментами).
              if (segment != null) ...[
                const SizedBox(height: 8),
                Text(
                  segmentLabel(l, segment!.id),
                  textAlign: TextAlign.center,
                  // Длинные метки («Вдох левой · выдох правой») и крупный
                  // шрифт: 2 строки максимум, не растягивают шапку (аудит F8).
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: elementColor(segment!.id),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
                SizedBox(
                  width: double.infinity,
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
        );
    return Scaffold(
      // В HANT под сессией — фон-«чертёж» (в классике HantBackdrop прозрачен).
      body: HantBackdrop(
          child: SafeArea(
        // Пауза — тапом по любому месту экрана (кнопка «Стоп» перехватывает
        // свой тап сама); на финише внешний детектор не нужен — там свой
        // тап-закрыть на круге.
        child: finished
            ? body
            : GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onPauseResume,
                child: body,
              ),
      )),
    );
  }

  /// Финиш (влад. §14): единый [SessionFinish]; подсказку тапа рисует сам
  /// экран в слоте кнопок, поэтому tapHint здесь не передаётся.
  Widget _finishedFigure(ThemeData theme, AppLocalizations l) {
    return SessionFinish(title: l.sessionDone, onClose: onStop);
  }

  Widget _breathingFigure(ThemeData theme, AppLocalizations l) {
    final (title, number) = _titleAndNumber(l);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Аффирмация (фраза фикра) — сразу над кругом (влад. 2026-07-18:
        // под шапкой экрана она выпадала из поля зрения). AnimatedSwitcher
        // мягко меняет текст на границе вдох/выдох (№10).
        if (phraseTexts != null) ...[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Text(
                _phraseFor() ?? '',
                key: ValueKey(_phraseFor() ?? ''),
                textAlign: TextAlign.center,
                // Свои (кастомные) фразы фикра длину не ограничивают —
                // 3 строки покрывают штатные пары и большинство своих
                // (дизайн-аудит F7: раньше 2 строки обрезали «…»).
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          height: 260,
          width: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Дыхательная фигура (CustomPainter); цвет — элемент или тема.
              CustomPaint(
                size: const Size(260, 260),
                painter: BreathingPainter(
                  shape: shape,
                  state: state,
                  primary: segment != null
                      ? elementColor(segment!.id)
                      : theme.colorScheme.primary,
                  outline: theme.colorScheme.outline,
                  // HANT: фигура — калибровочный прицел с ядром-«источником».
                  hant: theme.extension<HantStyle>(),
                ),
              ),
              // Подпись фазы и отсчёт секунд — в центре фигуры («центр
              // дисплея» — влад. 2026-07-18: раньше подпись жила под кругом
              // и терялась).
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Слот фиксированной высоты + FittedBox(scaleDown): длинные
                  // подписи («Exhale through the mouth», «Выдох правой
                  // ноздрёй») и крупный системный шрифт УМЕНЬШАЮТСЯ, а не
                  // теряют слова (дизайн-аудит F6: раньше maxLines:2 отрезал
                  // «ноздрёй»).
                  SizedBox(
                    width: 216,
                    height: 64,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: Text(
                          title,
                          style: theme.textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    number,
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
              // Подсказки тапа — поверх нижней части круга, чтобы попадали
              // в поле зрения (влад. 2026-07-18): сначала растворяющаяся
              // «тап — пауза», на паузе — постоянная «тап — продолжить».
              Align(
                alignment: const Alignment(0, 0.72),
                child: paused
                    ? SessionHintPill(text: l.pausedTapHint)
                    : const TapPauseHint(),
              ),
            ],
          ),
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
        // С сегментом — подпись маршрута; без — стандартная подпись фазы.
        final label = segment != null
            ? routedPhaseLabel(l, segment!, state.phase!)
            : phaseLabel(l, state.phase!);
        return (label, '${state.phaseRemainingSec}');
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
