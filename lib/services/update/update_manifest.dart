import 'dart:convert';

import 'app_version.dart';

/// Описание доступного обновления, полученное из GitHub Releases.
class UpdateInfo {
  final Version version;
  final String downloadUrl; // прямой URL APK-ассета
  final int sizeBytes;
  final String? notes; // changelog (тело релиза)

  const UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.sizeBytes,
    this.notes,
  });

  /// Человекочитаемый размер, например «≈ 24.2 МБ» (ТЗ-независимо; по запросу
  /// пользователя показываем средний размер файла обновления).
  String get humanSize => formatBytes(sizeBytes);
}

/// Форматирование байтов в КБ/МБ/ГБ с одним знаком и префиксом «≈».
String formatBytes(int bytes) {
  const units = ['Б', 'КБ', 'МБ', 'ГБ'];
  double v = bytes.toDouble();
  var u = 0;
  while (v >= 1024 && u < units.length - 1) {
    v /= 1024;
    u++;
  }
  final s = u == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  return '≈ $s ${units[u]}';
}

/// Разобрать JSON ответа GitHub `releases/latest`. Возвращает null, если это
/// draft/prerelease или в релизе нет APK-ассета.
///
/// При нескольких APK предпочитается arm64-v8a (наш релизный таргет с v0.3.0:
/// per-ABI сборка ради бюджета ≤30 МБ, ПЛАН §11.5); иначе — первый .apk
/// (совместимость с релизами v0.1–v0.2, где ассет один универсальный).
UpdateInfo? parseGithubRelease(String jsonBody) {
  final root = json.decode(jsonBody);
  if (root is! Map) throw const FormatException('Ожидался JSON-объект релиза');

  if (root['draft'] == true || root['prerelease'] == true) return null;

  final tag = root['tag_name'];
  if (tag is! String) throw const FormatException('Нет tag_name');
  final version = Version.parse(tag);

  final assets = root['assets'];
  if (assets is! List) return null;

  UpdateInfo? fromAsset(Object? a) {
    if (a is! Map) return null;
    final name = a['name'];
    final url = a['browser_download_url'];
    if (name is! String ||
        !name.toLowerCase().endsWith('.apk') ||
        url is! String) {
      return null;
    }
    final size = a['size'];
    return UpdateInfo(
      version: version,
      downloadUrl: url,
      sizeBytes: size is int ? size : 0,
      notes: root['body'] is String ? root['body'] as String : null,
    );
  }

  UpdateInfo? first;
  for (final a in assets) {
    final info = fromAsset(a);
    if (info == null) continue;
    if (info.downloadUrl.toLowerCase().contains('arm64-v8a')) return info;
    first ??= info;
  }
  return first; // нет .apk среди ассетов → null
}
