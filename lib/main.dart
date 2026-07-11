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
  // Фоновый синк истории практик (no-op без входа/сети) — не задерживает UI.
  unawaited(SessionSyncService().syncNow());
  runApp(const BreathinApp());
}
