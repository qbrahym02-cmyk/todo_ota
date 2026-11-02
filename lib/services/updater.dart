import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../app_config.dart';
import 'apk_installer_stub.dart'
    if (dart.library.io) 'apk_installer_io.dart' as installer;

class ReleaseInfo {
  final String versionName;
  final int build;
  final String notes;
  final String? apkUrl;
  ReleaseInfo(this.versionName, this.build, this.notes, this.apkUrl);
}

/// يفحص GitHub Releases عن نسخة أحدث، ويحمّلها ويثبّتها من داخل التطبيق.
class Updater {
  static Future<int> currentBuild() async {
    final info = await PackageInfo.fromPlatform();
    return int.tryParse(info.buildNumber) ?? 0;
  }

  static Future<String> currentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  }

  /// يرجع معلومات الإصدار إذا كان أحدث من المثبّت، وإلا null.
  static Future<ReleaseInfo?> checkForUpdate() async {
    if (kIsWeb) return null; // الويب يتحدث تلقائياً
    try {
      final res = await http.get(Uri.parse(AppConfig.latestReleaseApi),
          headers: {'Accept': 'application/vnd.github+json'}).timeout(
          const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final tag = (j['tag_name'] as String? ?? '').replaceFirst('v', '');
      final build = int.tryParse(tag.split('.').last) ?? 0;
      String? apk;
      for (final a in (j['assets'] as List<dynamic>? ?? [])) {
        final name = a['name'] as String? ?? '';
        if (name.endsWith('.apk')) {
          apk = a['browser_download_url'] as String?;
          break;
        }
      }
      final latest = ReleaseInfo(tag, build, j['body'] as String? ?? '', apk);
      return build > await currentBuild() && apk != null ? latest : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> downloadAndInstall(
    ReleaseInfo r,
    void Function(double progress) onProgress,
  ) =>
      installer.downloadAndInstall(r.apkUrl!, onProgress);
}
