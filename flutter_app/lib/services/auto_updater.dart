// Thaiprompt POS — Auto-update service
// Checks GitHub Releases, downloads APK, triggers PackageInstaller to overwrite.
// by xman studio

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String tag;
  final String apkUrl;
  final String releaseNotes;
  final int sizeBytes;
  final DateTime publishedAt;

  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.tag,
    required this.apkUrl,
    required this.releaseNotes,
    required this.sizeBytes,
    required this.publishedAt,
  });

  bool get hasUpdate => _isNewer(latestVersion, currentVersion);

  static bool _isNewer(String latest, String current) {
    final l = _parse(latest);
    final c = _parse(current);
    for (var i = 0; i < l.length; i++) {
      final cv = i < c.length ? c[i] : 0;
      if (l[i] > cv) return true;
      if (l[i] < cv) return false;
    }
    return false;
  }

  static List<int> _parse(String v) {
    final cleaned = v.replaceAll(RegExp(r'[^\d.]'), '');
    return cleaned.split('.').map(int.tryParse).whereType<int>().toList();
  }
}

/// Auto-updater service.
///
/// Usage:
/// ```dart
/// final updater = AutoUpdater(
///   owner: 'xjanova',
///   repo: 'posthaiprompt',
/// );
/// final info = await updater.checkForUpdate();
/// if (info != null && info.hasUpdate) {
///   await updater.downloadAndInstall(info, onProgress: (pct) {...});
/// }
/// ```
class AutoUpdater {
  final String owner;
  final String repo;
  final Dio _dio;

  AutoUpdater({
    required this.owner,
    required this.repo,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  /// Check GitHub Releases for latest version.
  /// Returns null if API unreachable or no releases yet.
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final pkg = await PackageInfo.fromPlatform();
      final url = 'https://api.github.com/repos/$owner/$repo/releases/latest';

      final res = await _dio.get<Map<String, dynamic>>(
        url,
        options: Options(headers: {
          'Accept': 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
        }),
      );

      final data = res.data;
      if (data == null) return null;

      final tag = data['tag_name'] as String? ?? '';
      final latestVersion = tag.replaceAll(RegExp(r'^v'), '');
      final notes = data['body'] as String? ?? '';
      final published = DateTime.tryParse(data['published_at'] as String? ?? '')
                       ?? DateTime.now();
      final assets = data['assets'] as List? ?? [];
      final apk = assets.cast<Map<String, dynamic>>().firstWhere(
        (a) => (a['name'] as String? ?? '').endsWith('.apk'),
        orElse: () => {},
      );
      if (apk.isEmpty) return null;

      return UpdateInfo(
        currentVersion: pkg.version,
        latestVersion: latestVersion,
        tag: tag,
        apkUrl: apk['browser_download_url'] as String? ?? '',
        releaseNotes: notes,
        sizeBytes: apk['size'] as int? ?? 0,
        publishedAt: published,
      );
    } catch (e) {
      debugPrint('AutoUpdater.checkForUpdate failed: $e');
      return null;
    }
  }

  /// Download APK and trigger Android's PackageInstaller.
  /// Same signing key → overwrites existing app, keeps user data.
  Future<void> downloadAndInstall(
    UpdateInfo info, {
    void Function(double percent, String status)? onProgress,
    void Function(String error)? onError,
    void Function()? onComplete,
  }) async {
    // Android 8+ requires REQUEST_INSTALL_PACKAGES + user-granted "install unknown apps".
    final installPerm = await Permission.requestInstallPackages.status;
    if (!installPerm.isGranted) {
      final asked = await Permission.requestInstallPackages.request();
      if (!asked.isGranted) {
        onError?.call('ผู้ใช้ปฏิเสธสิทธิ์ติดตั้งแอพ — ไม่สามารถอัปเดตอัตโนมัติได้');
        return;
      }
    }

    try {
      OtaUpdate().execute(info.apkUrl, destinationFilename: 'posthaiprompt-${info.tag}.apk').listen(
        (event) {
          final pct = double.tryParse(event.value ?? '0') ?? 0.0;
          // Use a non-exhaustive switch via name comparison — robust to new
          // OtaStatus enum values added by future ota_update versions.
          final s = event.status.toString().split('.').last;
          if (s == 'DOWNLOADING') {
            onProgress?.call(pct, 'กำลังดาวน์โหลด ${pct.toStringAsFixed(0)}%');
          } else if (s == 'INSTALLING') {
            onProgress?.call(100, 'กำลังติดตั้ง...');
          } else if (s == 'INSTALLATION_DONE') {
            onProgress?.call(100, '✓ ติดตั้งเสร็จ — กำลังเปิดแอพใหม่');
          } else if (s == 'ALREADY_RUNNING_ERROR') {
            onError?.call('การอัปเดตกำลังทำงานอยู่');
          } else if (s == 'PERMISSION_NOT_GRANTED_ERROR') {
            onError?.call('ไม่ได้รับสิทธิ์ติดตั้งแอพ');
          } else if (s == 'INTERNAL_ERROR' || s == 'INSTALLATION_ERROR') {
            onError?.call('เกิดข้อผิดพลาดภายใน — ${event.value ?? ""}');
          } else if (s == 'DOWNLOAD_ERROR') {
            onError?.call('ดาวน์โหลดล้มเหลว — ตรวจสอบเครือข่าย');
          } else if (s == 'CHECKSUM_ERROR') {
            onError?.call('Checksum ไม่ตรง — ไฟล์อาจเสียหาย');
          }
        },
        onDone: () => onComplete?.call(),
        onError: (e) => onError?.call(e.toString()),
      );
    } catch (e) {
      onError?.call(e.toString());
    }
  }
}
