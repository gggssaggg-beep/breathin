import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'coach_controller.dart';

/// Инлайн-подсказка-«облачко» (coachmark).
///
/// Если контроллер говорит, что подсказку с данным [id] ещё не видели —
/// рисует пузырёк с уголком-указателем вниз над [child] (или отдельно,
/// если [child] == null). Тап по пузырьку закрывает его и помечает как
/// просмотренный в персисте. Появляется с лёгкой анимацией opacity + translateY.
///
/// Когда подсказка не нужна — возвращает [child] или [SizedBox.shrink()].
class CoachMark extends StatefulWidget {
  /// Уникальный идентификатор подсказки (например, 'home.pick').
  final String id;

  /// Текст подсказки.
  final String message;

  /// Виджет под пузырьком (необязателен).
  final Widget? child;

  const CoachMark({
    super.key,
    required this.id,
    required this.message,
    this.child,
  });

  @override
  State<CoachMark> createState() => _CoachMarkState();
}

class _CoachMarkState extends State<CoachMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _opacity;
  late final Animation<double> _translateY;

  /// Кешированное значение shouldShow — обновляем через didChangeDependencies,
  /// чтобы не вызывать CoachScope.of внутри build AnimatedBuilder (→ цикл).
  bool _shouldShow = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _opacity = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _translateY = Tween<double>(begin: 6, end: 0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Читаем shouldShow здесь (а не в build), чтобы AnimatedBuilder не
    // регистрировал зависимость от CoachScope и не создавал цикл перестроения.
    final newShow = CoachScope.of(context).shouldShow(widget.id);
    if (newShow != _shouldShow) {
      _shouldShow = newShow;
      if (_shouldShow) {
        // Запускаем появление после текущего кадра
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _shouldShow) _animCtrl.forward();
        });
      } else {
        _animCtrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  /// Закрыть подсказку с анимацией.
  Future<void> _dismiss() async {
    await _animCtrl.reverse();
    if (!mounted) return;
    // Читаем контроллер синхронно — mounted гарантирует безопасность.
    await CoachScope.of(context).dismiss(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    // Когда не нужно показывать и анимация завершена — отдаём только child.
    if (!_shouldShow && _animCtrl.isDismissed) {
      return widget.child ?? const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    final bubble = AnimatedBuilder(
      animation: _animCtrl,
      builder: (_, __) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0, _translateY.value),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Пузырёк
                GestureDetector(
                  onTap: _dismiss,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Текст подсказки
                        Flexible(
                          child: Text(
                            widget.message,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Кнопка закрытия
                        Text(
                          '${l.coachDismiss} ✕',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer
                                .withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Уголок-указатель вниз
                CustomPaint(
                  size: const Size(14, 7),
                  painter: _DownArrowPainter(
                    color: theme.colorScheme.secondaryContainer,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (widget.child == null) return bubble;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        bubble,
        widget.child!,
      ],
    );
  }
}

/// Рисует маленький треугольник-стрелку, указывающий вниз.
/// Используется как «уголок» под пузырьком подсказки.
class _DownArrowPainter extends CustomPainter {
  final Color color;

  const _DownArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DownArrowPainter old) => old.color != color;
}
