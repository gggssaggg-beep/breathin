import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/prefs_changes.dart';
import '../domain/models/feedback_channels.dart';

/// Глобальный выбор каналов сопровождения для counted/scripted-сессий
/// (фидбек владельца 2026-07-19 №2): «если пользователь выбрал голос и
/// выключил остальные — повторить выбор во всех техниках».
///
/// Per-техника поле [TechniqueSettings.feedback] остаётся в модели для
/// совместимости сохранений, но источник правды для counted/scripted —
/// этот стор; Вим Хоф и таймер-режим используют собственные настройки.
class FeedbackChannelsStore {
  static const _key = 'app.feedback';

  /// Загружает глобальные каналы. При отсутствии ключа или битом JSON
  /// возвращает [const FeedbackChannels()] (дефолт).
  Future<FeedbackChannels> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const FeedbackChannels();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return FeedbackChannels.fromJson(map);
    } catch (_) {
      return const FeedbackChannels();
    }
  }

  /// Сохраняет глобальные каналы и уведомляет шину синка.
  Future<void> save(FeedbackChannels channels) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(channels.toJson()));
    PrefsChanges.notify();
  }
}
