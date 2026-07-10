/// Пользовательские настройки обновлений. `autoUpdate` включён по умолчанию
/// (галочка «Автообновление» — по запросу пользователя стоит по умолчанию).
///
/// Персистентность (drift `app_settings` / prefs) подключается в партии
/// настроек; здесь — только модель значения.
library;

class UpdatePreferences {
  final bool autoUpdate;

  /// Скачивать тихо только по Wi-Fi (бережём мобильный трафик; APK крупный).
  final bool wifiOnly;

  const UpdatePreferences({
    this.autoUpdate = true,
    this.wifiOnly = true,
  });

  UpdatePreferences copyWith({bool? autoUpdate, bool? wifiOnly}) =>
      UpdatePreferences(
        autoUpdate: autoUpdate ?? this.autoUpdate,
        wifiOnly: wifiOnly ?? this.wifiOnly,
      );
}
