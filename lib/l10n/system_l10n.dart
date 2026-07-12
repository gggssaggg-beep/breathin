import 'dart:ui';

import 'generated/app_localizations.dart';

/// Локализация ВНЕ дерева виджетов — для сервисов без BuildContext
/// (имя аудио-канала уведомлений, титул медиа-сессии). Локаль — системная
/// (PlatformDispatcher: работает и в вебе, где dart:io Platform недоступен).
/// Неподдерживаемая локаль → en (как у резолюции MaterialApp).
AppLocalizations systemL10n() {
  try {
    final code = PlatformDispatcher.instance.locale.languageCode;
    return lookupAppLocalizations(Locale(code));
  } catch (_) {
    return lookupAppLocalizations(const Locale('en'));
  }
}
