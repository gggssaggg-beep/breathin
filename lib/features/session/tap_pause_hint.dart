import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// Растворяющаяся подсказка «Тап по экрану — пауза» (влад. 2026-07-16):
/// видна первые секунды сессии, затем плавно исчезает. Класть в Stack —
/// после исчезновения места не занимает и тапы не перехватывает.
class TapPauseHint extends StatefulWidget {
  const TapPauseHint({super.key});

  @override
  State<TapPauseHint> createState() => _TapPauseHintState();
}

class _TapPauseHintState extends State<TapPauseHint> {
  bool _visible = true;
  bool _gone = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_gone) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 900),
        onEnd: () {
          if (!_visible && mounted) setState(() => _gone = true);
        },
        child: SessionHintPill(text: AppLocalizations.of(context).tapPauseHint),
      ),
    );
  }
}

/// Пилюля-подсказка сессии (общая для растворяющейся и «Пауза · тап —
/// продолжить»).
class SessionHintPill extends StatelessWidget {
  final String text;

  const SessionHintPill({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
