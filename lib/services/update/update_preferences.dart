/// Пользовательские настройки обновлений. `autoUpdate` включён по умолчанию
/// (галочка «Автообновление» — по запросу пользователя стоит по умолчанию).
library;

import 'package:shared_preferences/shared_preferences.dart';

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

/// Персист настроек обновлений (prefs: ключи update.autoUpdate/update.wifiOnly).
class UpdatePreferencesStore {
  static const _autoKey = 'update.autoUpdate';
  static const _wifiKey = 'update.wifiOnly';

  Future<UpdatePreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    const defaults = UpdatePreferences();
    return UpdatePreferences(
      autoUpdate: prefs.getBool(_autoKey) ?? defaults.autoUpdate,
      wifiOnly: prefs.getBool(_wifiKey) ?? defaults.wifiOnly,
    );
  }

  Future<void> save(UpdatePreferences p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoKey, p.autoUpdate);
    await prefs.setBool(_wifiKey, p.wifiOnly);
  }
}
