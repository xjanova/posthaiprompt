// Thaiprompt POS — Auto-update service (Android + Windows).
//
// Reads the latest published release of the POS (release feed of the project
// repository — never shown to users), picks the asset for this platform and
// installs it in place:
//   • Android  — download the .apk and hand it to the package installer
//                (same signing key → overwrites, keeps shop data).
//   • Windows  — download the windows .zip, then a small detached PowerShell
//                helper waits for the app to exit, extracts the files over the
//                install folder and relaunches the POS.
//   • iOS      — not self-installable (App Store / TestFlight).
//
// by xman studio

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String tag;

  /// Download URL of the installer for THIS platform ('' when none).
  final String assetUrl;
  final String assetName;
  final String releaseNotes; // already cleaned for display
  final int sizeBytes;
  final DateTime publishedAt;

  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.tag,
    required this.assetUrl,
    this.assetName = '',
    required this.releaseNotes,
    required this.sizeBytes,
    required this.publishedAt,
  });

  /// Back-compat for older callers.
  String get apkUrl => assetUrl;

  bool get hasUpdate => isNewer(latestVersion, currentVersion);
  bool get hasInstaller => assetUrl.isNotEmpty;

  static bool isNewer(String latest, String current) {
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
    final cleaned = v.split('+').first.replaceAll(RegExp(r'[^\d.]'), '');
    return cleaned.split('.').map(int.tryParse).whereType<int>().toList();
  }
}

/// Release notes shown in the app: drop hosting/build-system lines and URLs.
String cleanReleaseNotes(String raw) {
  final out = <String>[];
  for (final line in raw.split(RegExp(r'\r?\n'))) {
    final l = line.toLowerCase();
    if (l.contains('github') ||
        l.contains('http://') ||
        l.contains('https://') ||
        l.contains('built by') ||
        l.contains('full changelog') ||
        l.contains('built with')) {
      continue;
    }
    out.add(line.replaceAll('**', '').replaceAll(RegExp(r'^#+\s*'), '').trimRight());
  }
  return out.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}

class AutoUpdater {
  final String owner;
  final String repo;
  final Dio _dio;

  AutoUpdater({required this.owner, required this.repo, Dio? dio}) : _dio = dio ?? Dio();

  /// This platform can download + install updates by itself.
  static bool get canSelfInstall => !kIsWeb && (Platform.isAndroid || Platform.isWindows);

  static String get platformLabel {
    if (kIsWeb) return 'เว็บ';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isMacOS) return 'macOS';
    return Platform.operatingSystem;
  }

  /// Latest published release, or null if unreachable / none yet.
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final pkg = await PackageInfo.fromPlatform();
      final res = await _dio.get<Map<String, dynamic>>(
        'https://api.github.com/repos/$owner/$repo/releases/latest',
        options: Options(
          headers: const {'Accept': 'application/vnd.github+json'},
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
        ),
      );
      final data = res.data;
      if (data == null) return null;

      final tag = data['tag_name'] as String? ?? '';
      final published = DateTime.tryParse(data['published_at'] as String? ?? '') ?? DateTime.now();
      final assets = (data['assets'] as List? ?? const []).cast<Map<String, dynamic>>();

      bool wanted(String name) {
        final n = name.toLowerCase();
        if (kIsWeb) return false;
        if (Platform.isAndroid) return n.endsWith('.apk');
        if (Platform.isWindows) return n.endsWith('.zip') && n.contains('windows');
        return false;
      }

      final asset = assets.firstWhere((a) => wanted(a['name'] as String? ?? ''), orElse: () => const {});
      return UpdateInfo(
        currentVersion: pkg.version,
        latestVersion: tag.replaceAll(RegExp(r'^v'), ''),
        tag: tag,
        assetUrl: asset['browser_download_url'] as String? ?? '',
        assetName: asset['name'] as String? ?? '',
        releaseNotes: cleanReleaseNotes(data['body'] as String? ?? ''),
        sizeBytes: (asset['size'] as num?)?.toInt() ?? 0,
        publishedAt: published,
      );
    } catch (e) {
      debugPrint('AutoUpdater.checkForUpdate failed: $e');
      return null;
    }
  }

  /// Download + install for this platform. On Windows [onBeforeRestart] runs
  /// (e.g. flush the store to disk) right before the app exits to be replaced.
  Future<void> downloadAndInstall(
    UpdateInfo info, {
    void Function(double percent, String status)? onProgress,
    void Function(String error)? onError,
    void Function()? onComplete,
    Future<void> Function()? onBeforeRestart,
  }) async {
    if (!info.hasInstaller) {
      onError?.call('ยังไม่มีไฟล์ติดตั้งสำหรับ $platformLabel ในเวอร์ชันนี้');
      return;
    }
    if (!kIsWeb && Platform.isWindows) {
      await _installWindows(info, onProgress: onProgress, onError: onError, onBeforeRestart: onBeforeRestart);
      return;
    }
    if (!kIsWeb && Platform.isAndroid) {
      await _installAndroid(info, onProgress: onProgress, onError: onError, onComplete: onComplete);
      return;
    }
    onError?.call('$platformLabel ต้องติดตั้งเวอร์ชันใหม่ผ่านร้านค้าแอป');
  }

  Future<void> _installAndroid(
    UpdateInfo info, {
    void Function(double percent, String status)? onProgress,
    void Function(String error)? onError,
    void Function()? onComplete,
  }) async {
    // Android 8+: REQUEST_INSTALL_PACKAGES + user-granted "install unknown apps".
    final installPerm = await Permission.requestInstallPackages.status;
    if (!installPerm.isGranted) {
      final asked = await Permission.requestInstallPackages.request();
      if (!asked.isGranted) {
        onError?.call('ยังไม่ได้อนุญาตให้ติดตั้งแอป — เปิดสิทธิ์ "ติดตั้งแอปที่ไม่รู้จัก" ให้ Thai Prompt POS แล้วลองอีกครั้ง');
        return;
      }
    }
    final done = Completer<void>();
    try {
      OtaUpdate().execute(info.assetUrl, destinationFilename: 'thaiprompt-pos-${info.tag}.apk').listen(
        (event) {
          final pct = double.tryParse(event.value ?? '0') ?? 0.0;
          final s = event.status.toString().split('.').last;
          if (s == 'DOWNLOADING') {
            onProgress?.call(pct, 'กำลังดาวน์โหลด ${pct.toStringAsFixed(0)}%');
          } else if (s == 'INSTALLING') {
            onProgress?.call(100, 'กำลังติดตั้ง…');
          } else if (s == 'INSTALLATION_DONE') {
            onProgress?.call(100, 'ติดตั้งเสร็จ — กำลังเปิดแอปใหม่');
          } else if (s == 'ALREADY_RUNNING_ERROR') {
            onError?.call('การอัปเดตกำลังทำงานอยู่');
          } else if (s == 'PERMISSION_NOT_GRANTED_ERROR') {
            onError?.call('ไม่ได้รับสิทธิ์ติดตั้งแอป');
          } else if (s == 'INTERNAL_ERROR' || s == 'INSTALLATION_ERROR') {
            onError?.call('ติดตั้งไม่สำเร็จ — ${event.value ?? ''}');
          } else if (s == 'DOWNLOAD_ERROR') {
            onError?.call('ดาวน์โหลดไม่สำเร็จ — ตรวจสอบอินเทอร์เน็ต');
          } else if (s == 'CHECKSUM_ERROR') {
            onError?.call('ไฟล์ที่ดาวน์โหลดเสียหาย — ลองใหม่อีกครั้ง');
          }
        },
        onDone: () {
          onComplete?.call();
          if (!done.isCompleted) done.complete();
        },
        onError: (Object e) {
          onError?.call('อัปเดตไม่สำเร็จ: $e');
          if (!done.isCompleted) done.complete();
        },
      );
    } catch (e) {
      onError?.call('อัปเดตไม่สำเร็จ: $e');
      if (!done.isCompleted) done.complete();
    }
    return done.future;
  }

  Future<void> _installWindows(
    UpdateInfo info, {
    void Function(double percent, String status)? onProgress,
    void Function(String error)? onError,
    Future<void> Function()? onBeforeRestart,
  }) async {
    try {
      final exe = Platform.resolvedExecutable;
      final installDir = p.dirname(exe);

      // The helper copies files into the install folder — it must be writable.
      try {
        final probe = File(p.join(installDir, '.tp_update_probe'));
        await probe.writeAsString('ok', flush: true);
        await probe.delete();
      } catch (_) {
        onError?.call('โฟลเดอร์ที่ติดตั้งแอปไม่อนุญาตให้เขียนไฟล์ — ย้ายโฟลเดอร์ Thai Prompt POS ไปไว้ที่ C:\\ThaipromptPOS หรือเปิดแอปด้วยสิทธิ์ผู้ดูแลระบบ แล้วลองใหม่');
        return;
      }

      final work = Directory(p.join(Directory.systemTemp.path, 'thaiprompt_pos_update'));
      if (await work.exists()) await work.delete(recursive: true);
      await work.create(recursive: true);
      final zip = p.join(work.path, 'update.zip');

      onProgress?.call(0, 'กำลังดาวน์โหลด 0%');
      await _dio.download(
        info.assetUrl,
        zip,
        onReceiveProgress: (got, total) {
          final t = total > 0 ? total : (info.sizeBytes > 0 ? info.sizeBytes : 0);
          final pct = t > 0 ? (got / t * 100).clamp(0, 100).toDouble() : 0.0;
          onProgress?.call(pct, 'กำลังดาวน์โหลด ${pct.toStringAsFixed(0)}%');
        },
      );
      final size = await File(zip).length();
      if (size < 1024 * 1024) {
        onError?.call('ไฟล์อัปเดตไม่สมบูรณ์ — ลองใหม่อีกครั้ง');
        return;
      }

      onProgress?.call(100, 'ดาวน์โหลดเสร็จ — กำลังติดตั้งและเปิดแอปใหม่');
      // ASCII-only script (PowerShell 5 misreads non-BOM UTF-8). Never name a
      // variable $pid — it's PowerShell's read-only automatic variable.
      final script = File(p.join(work.path, 'apply-update.ps1'));
      await script.writeAsString(r'''
param([int]$AppPid, [string]$Zip, [string]$Target, [string]$Exe)
$ErrorActionPreference = 'Stop'
$log = Join-Path (Split-Path $Zip) 'apply-update.log'
try {
  try { Wait-Process -Id $AppPid -Timeout 60 -ErrorAction SilentlyContinue } catch {}
  Start-Sleep -Milliseconds 800
  $tmp = Join-Path (Split-Path $Zip) 'extracted'
  if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
  Expand-Archive -Path $Zip -DestinationPath $tmp -Force
  $src = $tmp
  $inner = Get-ChildItem $tmp -Directory
  if ((Get-ChildItem $tmp -File).Count -eq 0 -and $inner.Count -eq 1) { $src = $inner[0].FullName }
  Copy-Item -Path (Join-Path $src '*') -Destination $Target -Recurse -Force
  "ok $(Get-Date -Format o)" | Out-File $log -Encoding ascii
} catch {
  "error $($_.Exception.Message)" | Out-File $log -Encoding ascii
}
Start-Process -FilePath (Join-Path $Target $Exe) -WorkingDirectory $Target
''');

      if (onBeforeRestart != null) await onBeforeRestart();
      await Process.start(
        'powershell.exe',
        [
          '-NoProfile',
          '-ExecutionPolicy', 'Bypass',
          '-WindowStyle', 'Hidden',
          '-File', script.path,
          '-AppPid', '$pid',
          '-Zip', zip,
          '-Target', installDir,
          '-Exe', p.basename(exe),
        ],
        mode: ProcessStartMode.detached,
      );
      // Give the helper a moment to start, then quit so files can be replaced.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      exit(0);
    } catch (e) {
      onError?.call('อัปเดตไม่สำเร็จ: $e');
    }
  }
}
