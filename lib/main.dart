import 'dart:async';

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/prefs_changes.dart';
import 'services/audio/audio_bootstrap.dart';
import 'services/auth/auth_service.dart';
import 'services/locale/locale_store.dart';
import 'services/sync/prefs_sync_service.dart';
import 'services/sync/session_sync_service.dart';
import 'services/theme/ui_theme_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.init();
  // Гидрируем локаль и интерфейс ДО runApp, чтобы первый кадр уже был
  // правильным (durable-источник — prefs, не localStorage).
  localeNotifier.value = localeFor(await LocaleStore().load());
  uiThemeNotifier.value = await UiThemeStore().load();
  // Аудио-подсистема сессий (foreground service, локскрин-контролы).
  await initSessionAudio();
  // Облачный синк настроек: сторы сообщают об изменениях через шину.
  PrefsChanges.onChanged = PrefsSyncService.instance.onLocalChange;
  // Синк истории практик и настроек: срабатывает и на восстановленную при
  // старте сессию (initialSession), и на каждый новый вход — в т.ч. возврат
  // из Google-браузера deep link'ом. Дедуп по uid: токен-рефреши не гоняют
  // сеть.
  String? syncedUid;
  const AuthService().onAuthStateChange.listen((user) {
    if (user == null) {
      syncedUid = null;
      unawaited(PrefsSyncService.instance.onSignedOut());
      return;
    }
    if (user.id == syncedUid) return;
    syncedUid = user.id;
    unawaited(SessionSyncService().syncNow());
    unawaited(PrefsSyncService.instance.syncNow());
  });
  runApp(const BreathinApp());
}
