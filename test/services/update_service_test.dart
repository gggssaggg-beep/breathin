import 'package:flutter_test/flutter_test.dart';

import 'package:breathin/services/update/app_version.dart';
import 'package:breathin/services/update/update_manifest.dart';
import 'package:breathin/services/update/update_preferences.dart';
import 'package:breathin/services/update/update_service.dart';

/// Реальная форма ответа GitHub `releases/latest` (урезанная).
String releaseJson({
  String tag = 'v1.2.0',
  bool draft = false,
  bool prerelease = false,
  int apkSize = 25411234,
  bool withApk = true,
}) {
  final assets = <String>[
    if (withApk)
      '{"name":"app-release.apk","size":$apkSize,'
          '"browser_download_url":"https://github.com/o/r/releases/download/$tag/app-release.apk"}',
    '{"name":"app-release.aab","size":123,'
        '"browser_download_url":"https://github.com/o/r/releases/download/$tag/app-release.aab"}',
  ];
  return '''
{
  "tag_name": "$tag",
  "name": "$tag",
  "body": "Исправления и улучшения",
  "draft": $draft,
  "prerelease": $prerelease,
  "assets": [${assets.join(',')}]
}''';
}

UpdateService service(String current, String Function() body) => UpdateService(
      currentVersion: Version.parse(current),
      releasesLatestUrl: UpdateService.githubLatest('o', 'r'),
      fetchJson: (_) async => body(),
    );

void main() {
  group('Version', () {
    test('parse снимает v и метаданные сборки/пререлиза', () {
      expect(Version.parse('v1.2.3').toString(), '1.2.3');
      expect(Version.parse('1.0.0+7'), const Version(1, 0, 0));
      expect(Version.parse('2.1').toString(), '2.1.0');
      expect(Version.parse('1.2.3-beta.1'), const Version(1, 2, 3));
    });

    test('сравнение по major/minor/patch', () {
      expect(Version.parse('1.2.0') > Version.parse('1.1.9'), isTrue);
      expect(Version.parse('1.2.0') > Version.parse('1.2.0'), isFalse);
      expect(Version.parse('2.0.0') > Version.parse('1.9.9'), isTrue);
      expect(Version.parse('1.0.10') > Version.parse('1.0.9'), isTrue);
    });

    test('мусор → FormatException', () {
      expect(() => Version.parse('abc'), throwsFormatException);
      expect(() => Version.parse(''), throwsFormatException);
    });
  });

  group('parseGithubRelease', () {
    test('извлекает версию, APK-ассет и размер', () {
      final info = parseGithubRelease(releaseJson())!;
      expect(info.version, const Version(1, 2, 0));
      expect(info.downloadUrl, endsWith('app-release.apk'));
      expect(info.sizeBytes, 25411234);
      expect(info.notes, 'Исправления и улучшения');
    });

    test('draft/prerelease игнорируются', () {
      expect(parseGithubRelease(releaseJson(draft: true)), isNull);
      expect(parseGithubRelease(releaseJson(prerelease: true)), isNull);
    });

    test('нет .apk среди ассетов → null', () {
      expect(parseGithubRelease(releaseJson(withApk: false)), isNull);
    });
  });

  group('formatBytes', () {
    test('человекочитаемый размер', () {
      expect(formatBytes(0), '≈ 0 Б');
      expect(formatBytes(2048), '≈ 2.0 КБ');
      expect(formatBytes(25411234), '≈ 24.2 МБ');
    });
  });

  group('UpdateService.check', () {
    test('новее текущей → available с info и размером', () async {
      final r = await service('1.1.0', () => releaseJson(tag: 'v1.2.0')).check();
      expect(r.availability, UpdateAvailability.available);
      expect(r.info!.version, const Version(1, 2, 0));
      expect(r.info!.humanSize, '≈ 24.2 МБ');
    });

    test('та же/старее версия → upToDate', () async {
      final same =
          await service('1.2.0', () => releaseJson(tag: 'v1.2.0')).check();
      expect(same.availability, UpdateAvailability.upToDate);
      final older =
          await service('1.3.0', () => releaseJson(tag: 'v1.2.0')).check();
      expect(older.availability, UpdateAvailability.upToDate);
    });

    test('сетевой сбой → checkFailed, без исключения (тихий режим)', () async {
      final svc = UpdateService(
        currentVersion: Version.parse('1.0.0'),
        releasesLatestUrl: UpdateService.githubLatest('o', 'r'),
        fetchJson: (_) async => throw Exception('нет сети'),
      );
      final r = await svc.check();
      expect(r.availability, UpdateAvailability.checkFailed);
      expect(r.info, isNull);
    });

    test('githubLatest строит корректный URL', () {
      expect(UpdateService.githubLatest('acme', 'dyshi').toString(),
          'https://api.github.com/repos/acme/dyshi/releases/latest');
    });
  });

  group('UpdatePreferences', () {
    test('автообновление включено по умолчанию', () {
      const p = UpdatePreferences();
      expect(p.autoUpdate, isTrue);
      expect(p.wifiOnly, isTrue);
      expect(p.copyWith(autoUpdate: false).autoUpdate, isFalse);
    });
  });
}
