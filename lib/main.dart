import 'dart:async';

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'services/audio/audio_bootstrap.dart';
import 'services/auth/auth_service.dart';
import 'services/sync/session_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.init();
  // Аудио-подсистема сессий (foreground service, локскрин-контролы).
  await initSessionAudio();
  // Синк истории практик: срабатывает и на восстановленную при старте сессию
  // (initialSession), и на каждый новый вход — в т.ч. возврат из
  // Google-браузера deep link'ом. Дедуп по uid: токен-рефреши не гоняют сеть.
  String? syncedUid;
  const AuthService().onAuthStateChange.listen((user) {
    if (user == null) {
      syncedUid = null;
      return;
    }
    if (user.id == syncedUid) return;
    syncedUid = user.id;
    unawaited(SessionSyncService().syncNow());
  });
  runApp(const BreathinApp());
}
