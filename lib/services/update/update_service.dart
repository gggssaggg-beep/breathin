import 'app_version.dart';
import 'update_manifest.dart';

/// Результат проверки обновлений.
enum UpdateAvailability { upToDate, available, checkFailed }

class UpdateCheckResult {
  final UpdateAvailability availability;
  final UpdateInfo? info; // непусто только при [UpdateAvailability.available]
  final Object? error; // при checkFailed

  const UpdateCheckResult(this.availability, {this.info, this.error});

  static const upToDate = UpdateCheckResult(UpdateAvailability.upToDate);
}

/// Загрузчик текста по URL (внедряется → тесты без сети). Реальная реализация
/// (dart:io HttpClient с User-Agent для GitHub API) подключается в приложении.
typedef JsonFetcher = Future<String> Function(Uri url);

/// Клиентское ядро OTA-обновлений через GitHub Releases (Android-таргет; на iOS
/// установка бинарника невозможна — там вызывающий код делает no-op).
///
/// Ответственность сервиса — только РЕШЕНИЕ «есть ли обновление и какое».
/// Скачивание и запуск установки APK (+ разрешение REQUEST_INSTALL_PACKAGES)
/// живут в платформенном слое и подключаются на устройстве.
class UpdateService {
  final Version currentVersion;
  final Uri releasesLatestUrl;
  final JsonFetcher fetchJson;

  const UpdateService({
    required this.currentVersion,
    required this.releasesLatestUrl,
    required this.fetchJson,
  });

  /// Собрать URL `releases/latest` из owner/repo.
  static Uri githubLatest(String owner, String repo) => Uri.parse(
      'https://api.github.com/repos/$owner/$repo/releases/latest');

  Future<UpdateCheckResult> check() async {
    try {
      final body = await fetchJson(releasesLatestUrl);
      final info = parseGithubRelease(body);
      if (info == null || info.version <= currentVersion) {
        return UpdateCheckResult.upToDate;
      }
      return UpdateCheckResult(UpdateAvailability.available, info: info);
    } catch (e) {
      // Тихий режим: сбой проверки не мешает пользоваться приложением офлайн.
      return UpdateCheckResult(UpdateAvailability.checkFailed, error: e);
    }
  }
}
