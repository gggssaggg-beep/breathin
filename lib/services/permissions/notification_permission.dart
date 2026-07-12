import 'dart:io';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Runtime-запрос POST_NOTIFICATIONS (Android 13+) — без него медиа-уведомление
/// сессии (audio_service, локскрин-контролы) не показывается. Нативный канал
/// вместо permission_handler: одно разрешение не стоит зависимости (бюджет APK).
///
/// Диалог показывается один раз при первом запуске (флаг в prefs); дальше
/// решение пользователя уважается — повторный запрос только вручную из
/// системных настроек. Любой сбой (тесты, iOS, старый Android) — тихий no-op:
/// без разрешения приложение полностью работает, нет только уведомления.
class NotificationPermission {
  static const _channel = MethodChannel('app.dyshi.breathin/permissions');
  static const _askedKey = 'notification_permission.asked';

  /// Вызывать после первого кадра (диалог поверх готового UI, не сплэша).
  static Future<void> ensureRequestedOnce() async {
    try {
      if (!Platform.isAndroid) return;
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_askedKey) ?? false) return;
      await prefs.setBool(_askedKey, true);
      await _channel.invokeMethod<bool>('requestNotifications');
    } catch (_) {
      // Платформа без канала/prefs (тесты) — работаем дальше без уведомлений.
    }
  }
}
