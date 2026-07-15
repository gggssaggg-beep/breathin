import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/onboarding/coach_store.dart';
import '../../ui/icons/breathin_icon.dart';
import '../../ui/icons/breathin_icons.dart';

/// Приветственный экран первого запуска.
///
/// Показывается один раз поверх главного экрана (модально). По кнопке
/// [AppLocalizations.welcomeStart] помечает приветствие как просмотренное
/// через [CoachStore] и закрывает диалог.
///
/// Дизайн: спокойный, в тему приложения — круг primaryContainer с иконкой
/// ряби (та же, что на кнопке «Начать» в [TechniqueCardScreen]).
class WelcomeScreen extends StatelessWidget {
  final CoachStore store;

  const WelcomeScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Иконка приложения — «рябь» в круге primaryContainer
            CircleAvatar(
              radius: 36,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: BreathinIcon(
                BreathinIcons.ripple,
                size: 36,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            // Название приложения
            Text(
              l.appTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Краткое описание
            Text(
              l.welcomeBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            // Кнопка «Начать»
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  await store.markWelcomeSeen();
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: Text(l.welcomeStart),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
