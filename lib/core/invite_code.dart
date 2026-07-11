import 'dart:math';

/// Алфавит кода-приглашения: без визуально путающихся символов (0/O, 1/I/L).
const String inviteCodeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

/// Генерирует код приглашения в челлендж (по умолчанию 6 символов,
/// ~31⁶ ≈ 887 млн комбинаций — достаточно против перебора при уникальном
/// индексе на стороне БД). [random] — для тестируемости.
String generateInviteCode({int length = 6, Random? random}) {
  final rng = random ?? Random.secure();
  return String.fromCharCodes(
    List.generate(
      length,
      (_) => inviteCodeAlphabet.codeUnitAt(rng.nextInt(inviteCodeAlphabet.length)),
    ),
  );
}
