import 'package:shared_preferences/shared_preferences.dart';

import '../core/prefs_changes.dart';

/// Персист избранных техник (prefs ключ 'favorites.v1', список id).
/// Операции редкие — конкурентная очередь не нужна.
class FavoritesStore {
  static const _key = 'favorites.v1';

  Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.toSet();
  }

  Future<void> toggle(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_key) ?? []).toSet();
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    await prefs.setStringList(_key, current.toList());
    PrefsChanges.notify();
  }
}
