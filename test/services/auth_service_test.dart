import 'package:breathin/services/auth/auth_config.dart';
import 'package:breathin/services/auth/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AuthService без конфигурации (гостевой режим)', () {
    test('константы пока пустые — auth выключен', () {
      expect(authConfigured, isFalse);
    });

    test('все методы — безопасные no-op', () async {
      const auth = AuthService();
      expect(auth.isConfigured, isFalse);
      expect(auth.currentUser, isNull);
      await expectLater(auth.onAuthStateChange, emitsDone);
      // Не бросают и не ходят в сеть (Supabase.initialize не вызывался —
      // при попытке обращения был бы AssertionError изнутри пакета).
      await auth.signInWithGoogle();
      await auth.signOut();
    });
  });

  group('AppUser.fromSupabase', () {
    User makeUser(Map<String, dynamic> meta) => User(
          id: 'uid-1',
          appMetadata: const {},
          userMetadata: meta,
          aud: 'authenticated',
          email: 'user@example.com',
          createdAt: '2026-07-11T00:00:00Z',
        );

    test('берёт full_name/avatar_url из метаданных Google', () {
      final u = AppUser.fromSupabase(makeUser({
        'full_name': 'Аня П.',
        'avatar_url': 'https://example.com/a.png',
      }));
      expect(u.id, 'uid-1');
      expect(u.email, 'user@example.com');
      expect(u.displayName, 'Аня П.');
      expect(u.avatarUrl, 'https://example.com/a.png');
    });

    test('фолбэки name/picture; пустые метаданные не роняют', () {
      final u = AppUser.fromSupabase(makeUser({
        'name': 'B',
        'picture': 'p.png',
      }));
      expect(u.displayName, 'B');
      expect(u.avatarUrl, 'p.png');

      final empty = AppUser.fromSupabase(makeUser({}));
      expect(empty.displayName, isNull);
      expect(empty.avatarUrl, isNull);
    });
  });
}
