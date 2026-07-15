import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../ui/icons/breathin_icon.dart';
import '../../ui/icons/breathin_icons.dart';

/// Форма e-mail-входа/привязки (magic-link): поле адреса + кнопка. После
/// успешной отправки показывает «проверьте почту» вместо формы — вход
/// завершается вне экрана (тап по ссылке в письме → deep link), карточку
/// аккаунта обновит подписка на onAuthStateChange.
class EmailAuthForm extends StatefulWidget {
  final String actionLabel;

  /// Возвращает успех отправки (false — сеть не прошла; валидацию делает форма).
  final Future<bool> Function(String email) onSubmit;

  const EmailAuthForm({
    super.key,
    required this.actionLabel,
    required this.onSubmit,
  });

  @override
  State<EmailAuthForm> createState() => _EmailAuthFormState();
}

class _EmailAuthFormState extends State<EmailAuthForm> {
  final _controller = TextEditingController();
  bool _sending = false;
  bool _sent = false;
  String? _sentTo;
  String? _error;

  // Простая валидация: локальная часть, @, домен с точкой. Строгую проверку
  // делает сервер — здесь только отсекаем очевидные опечатки.
  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit(AppLocalizations l) async {
    final email = _controller.text.trim();
    if (!_emailRe.hasMatch(email)) {
      setState(() => _error = l.emailInvalidNote);
      return;
    }
    setState(() {
      _error = null;
      _sending = true;
    });
    final ok = await widget.onSubmit(email);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = ok;
      _sentTo = ok ? email : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (_sent) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BreathinIcon(BreathinIcons.send,
              size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l.emailLinkSentNote(_sentTo ?? ''),
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          enabled: !_sending,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l.emailFieldLabel,
            errorText: _error,
            isDense: true,
          ),
          onSubmitted: (_) => _submit(l),
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          icon: _sending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const BreathinIcon(BreathinIcons.send, size: 20),
          label: Text(widget.actionLabel),
          onPressed: _sending ? null : () => _submit(l),
        ),
      ],
    );
  }
}
