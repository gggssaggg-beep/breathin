import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/auth/auth_config.dart';
import '../../services/auth/auth_service.dart';
import '../../ui/icons/breathin_icon.dart';
import '../../ui/icons/breathin_icons.dart';

/// Секция «Аккаунт» экрана настроек (ТЗ §4).
///
/// Состояния:
/// * auth не готов ([AuthService.isReady] == false — например, тесты) —
///   карточка гостевого режима без кнопок;
/// * не вошёл — «Создать профиль (без регистрации)» (анонимный вход) и,
///   когда включим провайдер, «Войти через Google» ([googleAuthEnabled]);
/// * вошёл — ник (тап — изменить), тип профиля и «Выйти» (для гостевого —
///   с предупреждением о невосстановимости).
class AccountSection extends StatefulWidget {
  final AuthService auth;
  const AccountSection({super.key, this.auth = const AuthService()});

  @override
  State<AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends State<AccountSection> {
  AppUser? _user;
  String? _displayName;

  @override
  void initState() {
    super.initState();
    _user = widget.auth.currentUser;
    _loadName();
  }

  Future<void> _loadName() async {
    final name = await widget.auth.fetchDisplayName();
    if (mounted) setState(() => _displayName = name);
  }

  Future<void> _editNickname() async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController(text: _displayName ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.nicknameDialogTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 24,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim()),
            child: Text(l.commonSave),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await widget.auth.updateDisplayName(name);
    if (mounted) setState(() => _displayName = name);
  }

  Future<void> _signOut(AppUser user) async {
    final l = AppLocalizations.of(context);
    if (user.isAnonymous) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(l.signOutAnonWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l.signOutAction),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await widget.auth.signOut();
    if (mounted) setState(() => _displayName = null);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    if (!widget.auth.isReady) {
      return Card(
        child: ListTile(
          leading: const BreathinIcon(BreathinIcons.user),
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
        if (user == null) return _signedOutCard(l);
        return _signedInCard(l, user);
      },
    );
  }

  Widget _signedOutCard(AppLocalizations l) {
    final theme = Theme.of(context);
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
                icon: const BreathinIcon(BreathinIcons.user, size: 20),
                label: Text(l.createGuestProfile),
                onPressed: () async {
                  await widget.auth.signInAnonymously();
                  _loadName();
                },
              ),
            ),
            if (googleAuthEnabled) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const BreathinIcon(BreathinIcons.login, size: 20),
                  label: Text(l.signInGoogle),
                  onPressed: () => widget.auth.signInWithGoogle(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _signedInCard(AppLocalizations l, AppUser user) {
    final title = _displayName ?? user.displayName ?? user.email ?? '…';
    final subtitle = user.isAnonymous
        ? l.guestProfileLabel
        : (user.email ?? l.guestProfileLabel);
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              child: Text(
                  title.isEmpty ? '?' : title.characters.first.toUpperCase()),
            ),
            title: Text(title),
            subtitle: Text(subtitle),
            onTap: _editNickname, // тап по строке — сменить ник
            trailing: TextButton(
              onPressed: () => _signOut(user),
              child: Text(l.signOutAction),
            ),
          ),
          // Гостю предлагаем сделать профиль постоянным (id сохраняется —
          // челленджи/ник/история не теряются).
          if (user.isAnonymous && googleAuthEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const BreathinIcon(BreathinIcons.login, size: 20),
                  label: Text(l.linkGoogleAction),
                  onPressed: () => widget.auth.linkGoogleIdentity(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
