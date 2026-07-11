import 'dart:convert';
import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

import 'app_version.dart';
import 'update_service.dart';

/// Привязка OTA к репозиторию релизов (см. README, ПЛАН: GitHub Releases OTA).
const String updateOwner = 'gggssaggg-beep';
const String updateRepo = 'breathin';

/// Реальный загрузчик JSON для GitHub API (dart:io). GitHub требует
/// User-Agent; ответ не-200 — исключение (UpdateService вернёт checkFailed).
Future<String> fetchGithubJson(Uri url) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(url);
    request.headers.set(HttpHeaders.userAgentHeader, 'breathin-app');
    request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) {
      throw HttpException('GitHub API ${response.statusCode}', uri: url);
    }
    return body;
  } finally {
    client.close();
  }
}

/// Текущая версия приложения из платформенных метаданных (pubspec version).
/// null — плагин недоступен (юнит-тесты без моков): проверку пропускаем.
Future<Version?> currentAppVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    return Version.parse(info.version);
  } catch (_) {
    return null;
  }
}

/// Проверка обновления с дефолтной обвязкой (GitHub + текущая версия).
/// Тихая: любая проблема → upToDate/checkFailed, никаких исключений наружу.
Future<UpdateCheckResult> checkForUpdate() async {
  final current = await currentAppVersion();
  if (current == null) return UpdateCheckResult.upToDate;
  final service = UpdateService(
    currentVersion: current,
    releasesLatestUrl: UpdateService.githubLatest(updateOwner, updateRepo),
    fetchJson: fetchGithubJson,
  );
  return service.check();
}
