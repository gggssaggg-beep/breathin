import 'package:flutter/material.dart';

import '../../domain/catalog/techniques.dart';
import '../../domain/engine/session_plan_compiler.dart';
import '../../domain/models/session_config.dart';
import '../session/session_runner.dart';
import '../settings/settings_screen.dart';

/// Главный экран: список техник (ТЗ §6.2). Пока одна запись — box (срез №1);
/// полная сетка и поиск — партия П6.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Дыши'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Настройки',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TechniqueCard(
            title: 'Квадратное дыхание',
            subtitle: '4-4-4-4 · ${boxBreathing.defaultCycles} циклов',
            icon: Icons.crop_square_rounded,
            onTap: () => _startBox(context),
          ),
        ],
      ),
    );
  }

  void _startBox(BuildContext context) {
    final plan = const SessionPlanCompiler()
        .compile(boxBreathing, SessionConfig.classic(boxBreathing));
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SessionRunner(plan: plan)),
    );
  }
}

class _TechniqueCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _TechniqueCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(icon,
                    color: theme.colorScheme.onPrimaryContainer, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
