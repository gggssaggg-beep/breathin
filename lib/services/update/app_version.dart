/// Семантическая версия major.minor.patch. Чистый Dart, тестируется без
/// устройства. Метаданные сборки (`+N`) и пререлиза (`-beta`) отбрасываются
/// при сравнении — сравниваем только тройку чисел.
library;

class Version implements Comparable<Version> {
  final int major;
  final int minor;
  final int patch;

  const Version(this.major, this.minor, this.patch);

  /// Разобрать строку вида `v1.2.3`, `1.2.3+7`, `1.2` (недостающие → 0).
  /// Бросает [FormatException] на мусоре.
  static Version parse(String raw) {
    var s = raw.trim();
    if (s.isNotEmpty && (s[0] == 'v' || s[0] == 'V')) s = s.substring(1);
    for (final sep in ['+', '-', ' ']) {
      final i = s.indexOf(sep);
      if (i >= 0) s = s.substring(0, i);
    }
    if (s.isEmpty) throw FormatException('Пустая версия: "$raw"');
    final parts = s.split('.');
    int at(int i) => i < parts.length ? int.parse(parts[i]) : 0;
    return Version(at(0), at(1), at(2));
  }

  @override
  int compareTo(Version other) {
    if (major != other.major) return major - other.major;
    if (minor != other.minor) return minor - other.minor;
    return patch - other.patch;
  }

  bool operator >(Version other) => compareTo(other) > 0;
  bool operator <(Version other) => compareTo(other) < 0;
  bool operator >=(Version other) => compareTo(other) >= 0;
  bool operator <=(Version other) => compareTo(other) <= 0;

  @override
  bool operator ==(Object other) =>
      other is Version &&
      other.major == major &&
      other.minor == minor &&
      other.patch == patch;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}
