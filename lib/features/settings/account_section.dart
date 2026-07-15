import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/auth/auth_config.dart';
import '../../services/auth/auth_service.dart';
import '../../ui/icons/breathin_icon.dart';
import '../../ui/icons/breathin_icons.dart';
import 'email_auth_form.dart';

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
      onError: _showError,
    );
    _loadName();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _showError([Object? error]) {
    if (!mounted) return;
    // Текст реальной ошибки — иначе «не получилось» недиагностируемо
    // (живой отзыв v0.3.0: Google-вход падал без деталей).
    var detail = error?.toString() ?? '';
    if (detail.length > 160) detail = '${detail.substring(0, 160)}…';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          detail.isEmpty
              ? AppLocalizations.of(context).authActionFailed
              : '${AppLocalizations.of(context).authActionFailed}\n$detail',
        ),
        duration: const Duration(seconds: 8),
      ),
    );
  }

  /// Обёртка auth-действий: сетевые сбои → снекбар вместо тихого «ничего».
  /// Возвращает успех — вызывающие обновляют локальный стейт только по нему
  /// (пост-мерж ревью П1: ник не должен рисоваться новым при офлайн-ошибке).
  Future<bool> _guard(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } catch (e) {
      _showError(e);
      return false;
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
    final ok = await _guard(() => widget.auth.updateDisplayName(name));
    if (ok && mounted) setState(() => _displayName = name);
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
    final ok = await _guard(widget.auth.signOut);
    if (ok && mounted) setState(() => _displayName = null);
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
            if (emailAuthEnabled) ...[
              const SizedBox(height: 12),
              EmailAuthForm(
                actionLabel: l.emailSignInAction,
                onSubmit: (email) => _guard(() => widget.auth.signInWithEmail(email)),
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
          if (user.isAnonymous && emailAuthEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: EmailAuthForm(
                actionLabel: l.linkEmailAction,
                onSubmit: (email) =>
                    _guard(() => widget.auth.linkEmailIdentity(email)),
              ),
            ),
        ],
      ),
    );
  }
}
