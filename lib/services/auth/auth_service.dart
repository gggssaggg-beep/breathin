import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_config.dart';

/// Режим открытия страницы Google-входа.
/// Веб: ТОЛЬКО та же вкладка (platformDefault) — externalApplication делает
/// window.open после await, активация клика теряется, и блокировщик попапов
/// молча съедает окно («кнопка не нажимается», баг сайта 2026-07-17).
/// Мобилки: системный браузер (WebView Google не пускает — disallowed_useragent).
LaunchMode get _oauthLaunchMode =>
    kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication;

/// Профиль вошедшего пользователя — минимум, нужный UI.
/// Изолирует виджеты от типов Supabase.
class AppUser {
  final String id;
  final String? email;
  final String? displayName;
  final String? avatarUrl;

  /// Гостевой (анонимный) профиль: без почты; при выходе не восстановим.
  final bool isAnonymous;

  const AppUser({
    required this.id,
    this.email,
    this.displayName,
    this.avatarUrl,
    this.isAnonymous = false,
  });

  factory AppUser.fromSupabase(User u) {
    final meta = u.userMetadata ?? const <String, dynamic>{};
    return AppUser(
      id: u.id,
      email: u.email,
      displayName: (meta['full_name'] ?? meta['name']) as String?,
      avatarUrl: (meta['avatar_url'] ?? meta['picture']) as String?,
      isAnonymous: u.isAnonymous,
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
      authScreenLaunchMode: _oauthLaunchMode,
    );
  }

  /// E-mail-вход (magic-link): Supabase шлёт письмо со ссылкой, тап по ней
  /// возвращает в приложение deep link'ом [authRedirectUrl] и `supabase_flutter`
  /// устанавливает сессию (тот же PKCE-механизм, что у Google). Пароля/SHA-1
  /// не требуется. `shouldCreateUser: true` — новый адрес создаёт аккаунт.
  Future<void> signInWithEmail(String email) async {
    if (!isReady) return;
    await Supabase.instance.client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: authRedirectUrl,
    );
  }

  /// Привязка почты к гостевому профилю: как [linkGoogleIdentity], но по
  /// e-mail. `updateUser` шлёт письмо подтверждения; после клика uid НЕ
  /// меняется — челленджи/ник/история сохраняются, профиль становится
  /// постоянным (вход по почте с любого устройства).
  Future<void> linkEmailIdentity(String email) async {
    if (!isReady) return;
    await Supabase.instance.client.auth.updateUser(
      UserAttributes(email: email),
      emailRedirectTo: authRedirectUrl,
    );
  }

  /// Гостевой профиль (анонимный вход): аккаунт без почты и пароля —
  /// достаточно для челленджей. Провайдер включён в проекте Supabase.
  /// Профиль в public.profiles создаёт триггер (display_name = 'Гость').
  Future<void> signInAnonymously() async {
    if (!isReady) return;
    await Supabase.instance.client.auth.signInAnonymously();
  }

  /// Имя для отображения в челленджах — из public.profiles (источник
  /// правды: чужие имена другим участникам видны только через эту таблицу).
  Future<String?> fetchDisplayName() async {
    final user = currentUser;
    if (user == null) return null;
    final row = await Supabase.instance.client
        .from('profiles')
        .select('display_name')
        .eq('id', user.id)
        .maybeSingle();
    return row?['display_name'] as String?;
  }

  Future<void> updateDisplayName(String name) async {
    final user = currentUser;
    if (user == null) return;
    await Supabase.instance.client
        .from('profiles')
        .update({'display_name': name}).eq('id', user.id);
  }

  /// Привязка Google к гостевому профилю (identity linking): user id
  /// НЕ меняется — челленджи, ник и облачная история сохраняются, а профиль
  /// становится постоянным (вход с любого устройства). Ключевой механизм
  /// «без потери данных» при старте с анонимного входа.
  Future<void> linkGoogleIdentity() async {
    if (!isReady) return;
    await Supabase.instance.client.auth.linkIdentity(
      OAuthProvider.google,
      redirectTo: authRedirectUrl,
      authScreenLaunchMode: _oauthLaunchMode,
    );
  }

  Future<void> signOut() async {
    if (!isReady) return;
    await Supabase.instance.client.auth.signOut();
  }
}
