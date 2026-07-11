import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_config.dart';

/// Профиль вошедшего пользователя — минимум, нужный UI.
/// Изолирует виджеты от типов Supabase.
class AppUser {
  final String id;
  final String? email;
  final String? displayName;
  final String? avatarUrl;

  const AppUser({
    required this.id,
    this.email,
    this.displayName,
    this.avatarUrl,
  });

  factory AppUser.fromSupabase(User u) {
    final meta = u.userMetadata ?? const <String, dynamic>{};
    return AppUser(
      id: u.id,
      email: u.email,
      displayName: (meta['full_name'] ?? meta['name']) as String?,
      avatarUrl: (meta['avatar_url'] ?? meta['picture']) as String?,
    );
  }
}

/// Тонкая обёртка над Supabase Auth (вход через Google, ТЗ §4).
///
/// Схема входа — как в Astra, но средствами supabase_flutter: PKCE-код
/// возвращается deep link'ом [authRedirectUrl], пакет сам ловит ссылку и
/// обменивает код на сессию (в Astra это делалось вручную через
/// exchangeCodeForSession). Google-вход НЕ требует SHA-1/keystore —
/// браузерный OAuth, поэтому работает и до настройки подписи APK.
///
/// Пока [isReady] == false (нет конфигурации ИЛИ [init] не вызывался —
/// например, в виджет-тестах), все методы — безопасные no-op: приложение
/// живёт в гостевом режиме (ТЗ §4: практика без входа).
class AuthService {
  const AuthService();

  static bool _initialized = false;

  /// Инициализация Supabase; вызывать из main() ДО runApp.
  /// Без конфигурации — no-op (ни одного сетевого вызова).
  static Future<void> init() async {
    if (!authConfigured || _initialized) return;
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
    _initialized = true;
  }

  /// Auth доступен: сконфигурирован И инициализирован.
  bool get isReady => authConfigured && _initialized;

  AppUser? get currentUser {
    if (!isReady) return null;
    final u = Supabase.instance.client.auth.currentUser;
    return u == null ? null : AppUser.fromSupabase(u);
  }

  /// Изменения сессии (вход/выход) в терминах [AppUser].
  Stream<AppUser?> get onAuthStateChange {
    if (!isReady) return const Stream.empty();
    return Supabase.instance.client.auth.onAuthStateChange.map(
      (s) {
        final u = s.session?.user;
        return u == null ? null : AppUser.fromSupabase(u);
      },
    );
  }

  /// Google-вход: системный браузер (WebView Google не пускает —
  /// disallowed_useragent, урок Astra) + возврат deep link'ом.
  Future<void> signInWithGoogle() async {
    if (!isReady) return;
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: authRedirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<void> signOut() async {
    if (!isReady) return;
    await Supabase.instance.client.auth.signOut();
  }
}
