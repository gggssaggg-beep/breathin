import 'package:flutter/material.dart';

import '../../data/session_log_repository.dart';
import '../../domain/engine/timer_session.dart';
import '../../domain/models/technique.dart';
import '../../l10n/generated/app_localizations.dart';

/// Экран таймер-сессии (свободное дыхание по времени, ПЛАН §10).
///
/// STUB (партия T3 наполнит реализацией): контракт конструктора зафиксирован,
/// чтобы setup-экран (партия T2) мог маршрутизировать сюда и компилироваться.
/// Каналы: [sound] — фоновый луп + подсказки + гонг; [vibration] — вибро на
/// подсказках/гонге. [config] несёт минуты/подготовку/интервал подсказок.
class TimerSessionScreen extends StatefulWidget {
  final Technique technique;
  final TimerSessionConfig config;
  final bool sound;
  final bool vibration;
  final SessionLogRepository? log;

  const TimerSessionScreen({
    super.key,
    required this.technique,
    required this.config,
    required this.sound,
    required this.vibration,
    this.log,
  });

  @override
  State<TimerSessionScreen> createState() => _TimerSessionScreenState();
}

class _TimerSessionScreenState extends State<TimerSessionScreen> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Заглушка до партии T3.
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Text('${l.prepGetReady} · ${widget.config.minutes}'),
        ),
      ),
    );
  }
}
