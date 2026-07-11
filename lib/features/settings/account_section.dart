import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/auth/auth_service.dart';

/// Секция «Аккаунт» экрана настроек (ТЗ §4: гостевой режим + вход).
///
/// Три состояния:
/// * Supabase не сконфигурирован ([AuthService.isConfigured] == false) —
///   карточка гостевого режима с пояснением, без кнопки входа;
/// * гость — кнопка «Войти через Google»;
/// * вошёл — имя/e-mail и «Выйти».
class AccountSection extends StatefulWidget {
  final AuthService auth;
  const AccountSection({super.key, this.auth = const AuthService()});

  @override
  State<AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends State<AccountSection> {
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    _user = widget.auth.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (!widget.auth.isConfigured) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text(l.accountGuest),
          subtitle: Text('${l.accountGuestNote}\n${l.authNotConfiguredNote}'),
          isThreeLine: true,
        ),
      );
    }

    return StreamBuilder<AppUser?>(
      stream: widget.auth.onAuthStateChange,
      initialData: _user,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.accountGuestNote, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      icon: const Icon(Icons.login_rounded),
                      label: Text(l.signInGoogle),
                      onPressed: () => widget.auth.signInWithGoogle(),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        final title = user.displayName ?? user.email ?? user.id;
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(title.characters.first.toUpperCase()),
            ),
            title: Text(title),
            subtitle: user.email != null && user.displayName != null
                ? Text(user.email!)
                : null,
            trailing: TextButton(
              onPressed: () => widget.auth.signOut(),
              child: Text(l.signOutAction),
            ),
          ),
        );
      },
    );
  }
}
