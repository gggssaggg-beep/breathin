import 'dart:async';

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
  StreamSubscription<AppUser?>? _sub;

  @override
  void initState() {
    super.initState();
    _user = widget.auth.currentUser;
    // Вход завершается ВНЕ экрана (возврат из браузера deep link'ом) —
    // подписка держит карточку актуальной; onError ловит сбой обмена PKCE,
    // который иначе тонет молча (ревью К1).
    _sub = widget.auth.onAuthStateChange.listen(
      (user) {
        if (!mounted) return;
        setState(() => _user = user);
        if (user != null) _loadName();
      },
      onError: (_) => _showError(),
    );
    _loadName();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _showError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).authActionFailed)),
    );
  }

  /// Обёртка auth-действий: сетевые сбои → снекбар вместо тихого «ничего».
  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      _showError();
    }
  }

  Future<void> _loadName() async {
    try {
      final name = await widget.auth.fetchDisplayName();
      if (mounted) setState(() => _displayName = name);
    } catch (_) {
      // Офлайн: остаёмся на имени из метаданных пользователя.
    }
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
    await _guard(() => widget.auth.updateDisplayName(name));
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
    await _guard(widget.auth.signOut);
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

    final user = _user;
    if (user == null) return _signedOutCard(l);
    return _signedInCard(l, user);
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
                onPressed: () => _guard(widget.auth.signInAnonymously),
              ),
            ),
            if (googleAuthEnabled) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const BreathinIcon(BreathinIcons.login, size: 20),
                  label: Text(l.signInGoogle),
                  onPressed: () => _guard(widget.auth.signInWithGoogle),
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
                  onPressed: () => _guard(widget.auth.linkGoogleIdentity),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
