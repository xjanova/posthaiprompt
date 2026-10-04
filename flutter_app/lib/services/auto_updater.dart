// Thaiprompt POS — Auto-update service (Android + Windows).
//
// The only update source is xman4289.com (xman studio's product site, which
// mirrors each release on its side):
//   check    GET https://xman4289.com/api/v1/product/<slug>/update/check
//            ?current_version=X.Y.Z
//            → {has_update, latest_version, download_url, changelog,
//               sha256, file_size, filename}
//   download the `download_url` it returns — accepted only over https on
//            xman4289.com, redirects refused, and kept only when the byte
//            count and SHA-256 match what the check promised.
// Then install in place:
//   • Android  — hand the verified .apk to the package installer
//                (same signing key → overwrites, keeps shop data).
//   • Windows  — a small detached PowerShell helper waits for the app to exit,
//                extracts the verified .zip over the install folder and
//                relaunches the POS.
//   • iOS      — not self-installable (App Store / TestFlight).
//
// by xman studio

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Product slugs on xman4289.com, one per installer.
const kUpdateSlugAndroid = 'thaiprompt-pos';
const kUpdateSlugWindows = 'thaiprompt-pos-windows';

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;

  /// Verified download (https on xman4289.com) — '' when the server offers no
  /// file this app can check before installing.
  final String assetUrl;
  final String assetName;
  final String releaseNotes; // already cleaned for display
  final int sizeBytes;
  final String sha256; // lowercase hex
  final bool serverSaysNewer;

  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    this.assetUrl = '',
    this.assetName = '',
    this.releaseNotes = '',
    this.sizeBytes = 0,
    this.sha256 = '',
    this.serverSaysNewer = false,
  });

  String get tag => 'v$latestVersion';

  bool get hasUpdate => serverSaysNewer && isNewer(latestVersion, currentVersion);
  bool get hasInstaller => assetUrl.isNotEmpty && sizeBytes > 0 && sha256.length == 64;

  /// Semver compare; a build suffix (`+7`) breaks a tie only when both carry one.
  static bool isNewer(String latest, String current) {
    final l = _parse(latest);
    final c = _parse(current);
    for (var i = 0; i < l.length || i < c.length; i++) {
      final lv = i < l.length ? l[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (lv != cv) return lv > cv;
    }
    final lb = _build(latest), cb = _build(current);
    return lb != null && cb != null && lb > cb;
  }

  static List<int> _parse(String v) {
    final cleaned = v.trim().replaceFirst(RegExp(r'^v'), '').split('+').first.replaceAll(RegExp(r'[^\d.]'), '');
    return cleaned.split('.').map(int.tryParse).whereType<int>().toList();
  }

  static int? _build(String v) => v.contains('+') ? int.tryParse(v.split('+').last.trim()) : null;

  /// Parse an update/check answer. The download is accepted only when it can
  /// be verified: https on xman4289.com, a 64-hex SHA-256 and a sane size.
  static UpdateInfo fromCheck(Map<String, dynamic> json, {required String currentVersion}) {
    String text(Object? v) => v is String ? v.trim() : '';
    int? whole(Object? v) {
      if (v is int) return v;
      if (v is double && v == v.truncateToDouble()) return v.toInt();
      if (v is String) return int.tryParse(v.trim());
      return null;
    }

    final latest = text(json['latest_version']).replaceFirst(RegExp(r'^v'), '');
    final version = RegExp(r'^\d+(\.\d+)*(\+\d+)?$').hasMatch(latest) ? latest : currentVersion;
    final url = Uri.tryParse(text(json['download_url']));
    final sha = text(json['sha256']).toLowerCase();
    final size = whole(json['file_size']) ?? 0;
    final verifiable = url != null &&
        AutoUpdater.isAllowedDownload(url) &&
        RegExp(r'^[0-9a-f]{64}$').hasMatch(sha) &&
        size > 0 &&
        size <= AutoUpdater.maxBytes;
    return UpdateInfo(
      currentVersion: currentVersion,
      latestVersion: version,
      assetUrl: verifiable ? url.toString() : '',
      assetName: verifiable ? text(json['filename']) : '',
      releaseNotes: cleanReleaseNotes(text(json['changelog'])),
      sizeBytes: verifiable ? size : 0,
      sha256: verifiable ? sha : '',
      serverSaysNewer: json['has_update'] == true,
    );
  }
}

/// Release notes shown in the app: plain text, no links or build-system lines.
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

/// Download or verification failure, with a Thai message for the UI.
class UpdateException implements Exception {
  final String message;
  const UpdateException(this.message);
  @override
  String toString() => message;
}

class AutoUpdater {
  /// The only host the app checks or downloads updates from.
  static const host = 'xman4289.com';

  /// Refuse anything bigger, whatever the server claims.
  static const maxBytes = 1024 * 1024 * 1024;

  /// Longest wait for the next piece of a download before giving up.
  static const stallTimeout = Duration(seconds: 30);

  /// Shortest wait after a 503 "slots full" answer (tests lower it).
  static int busyMinWait = 5;

  static const _installer = MethodChannel('tp/installer');

  /// Product slug (defaults to this platform's installer).
  final String slug;

  /// Test hook: where update/check lives (defaults to https://xman4289.com).
  final Uri? checkBase;

  AutoUpdater({String? slug, this.checkBase}) : slug = slug ?? _platformSlug();

  static String _platformSlug() => !kIsWeb && Platform.isWindows ? kUpdateSlugWindows : kUpdateSlugAndroid;

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

  /// https on xman4289.com (or www.), default port, no credentials.
  static bool isAllowedDownload(Uri u) =>
      u.scheme == 'https' &&
      (u.host == host || u.host == 'www.$host') &&
      u.userInfo.isEmpty &&
      (!u.hasPort || u.port == 443);

  Uri _checkUri(String current) {
    final base = checkBase ?? Uri.https(host, '/');
    return base.replace(
      path: '/api/v1/product/$slug/update/check',
      queryParameters: {'current_version': current},
    );
  }

  /// What the site offers for this installer, or null when it can't be asked
  /// (offline, server error, product not published yet).
  Future<UpdateInfo?> checkForUpdate({String? currentVersion}) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final current = currentVersion ?? (await PackageInfo.fromPlatform()).version;
      final req = await client.getUrl(_checkUri(current)).timeout(const Duration(seconds: 15));
      req.followRedirects = false;
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final res = await req.close().timeout(const Duration(seconds: 15));
      final bytes = await res.fold<List<int>>(<int>[], (a, b) => a..addAll(b)).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      // The server sends JSON without a charset; it is UTF-8 (Thai notes).
      final data = jsonDecode(utf8.decode(bytes));
      if (data is! Map) return null;
      return UpdateInfo.fromCheck(data.cast<String, dynamic>(), currentVersion: current);
    } catch (e) {
      debugPrint('AutoUpdater.checkForUpdate failed: $e');
      return null;
    } finally {
      client.close(force: true);
    }
  }

  /// Stream [url] into [target], refusing redirects, and keep the file only
  /// when it has exactly [size] bytes with SHA-256 [sha256]. Throws
  /// [UpdateException] (and removes the partial file) otherwise.
  static Future<File> downloadVerified(
    Uri url,
    File target, {
    required int size,
    required String sha256,
    void Function(double percent)? onProgress,
    void Function(int seconds)? onBusyWait,
    int busyRetries = 2,
  }) async {
    // All download slots taken (503 + Retry-After): wait and try again.
    for (var attempt = 0;; attempt++) {
      try {
        return await _downloadOnce(url, target, size: size, sha256: sha256, onProgress: onProgress);
      } on _Busy catch (b) {
        if (attempt >= busyRetries) {
          throw const UpdateException('เซิร์ฟเวอร์อัปเดตมีผู้ดาวน์โหลดเต็ม — ลองใหม่อีกสักครู่');
        }
        onBusyWait?.call(b.seconds);
        await Future<void>.delayed(Duration(seconds: b.seconds));
      }
    }
  }

  static Future<File> _downloadOnce(
    Uri url,
    File target, {
    required int size,
    required String sha256,
    void Function(double percent)? onProgress,
  }) async {
    final part = File('${target.path}.part');
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    IOSink? sink;
    try {
      final req = await client.getUrl(url).timeout(stallTimeout);
      req.followRedirects = false; // a redirect would leave the update site
      final res = await req.close().timeout(stallTimeout);
      if (res.statusCode == 503) {
        final after = int.tryParse(res.headers.value(HttpHeaders.retryAfterHeader) ?? '') ?? 20;
        await res.drain<void>();
        throw _Busy(after.clamp(busyMinWait, 60));
      }
      if (res.statusCode != 200) throw const UpdateException('ดาวน์โหลดไม่สำเร็จ — ลองใหม่อีกครั้ง');
      final type = res.headers.contentType?.mimeType ?? '';
      if (type.startsWith('text/') || type == 'application/json') {
        throw const UpdateException('เซิร์ฟเวอร์ไม่ได้ส่งไฟล์ติดตั้ง — ลองใหม่อีกครั้ง');
      }
      if (res.contentLength >= 0 && res.contentLength != size) {
        throw const UpdateException('ขนาดไฟล์อัปเดตไม่ตรง — ลองใหม่อีกครั้ง');
      }
      final digest = _DigestSink();
      final hasher = crypto.sha256.startChunkedConversion(digest);
      if (await part.exists()) await part.delete();
      sink = part.openWrite();
      var received = 0;
      await for (final chunk in res.timeout(stallTimeout)) {
        received += chunk.length;
        if (received > size) throw const UpdateException('ไฟล์อัปเดตใหญ่กว่าที่ประกาศ — ยกเลิกการติดตั้ง');
        hasher.add(chunk);
        sink.add(chunk);
        onProgress?.call(received / size * 100);
      }
      await sink.flush();
      await sink.close();
      sink = null;
      hasher.close();
      if (received != size) throw const UpdateException('ดาวน์โหลดไม่ครบ — ลองใหม่อีกครั้ง');
      if (digest.value.toString() != sha256) {
        throw const UpdateException('ไฟล์อัปเดตไม่ผ่านการตรวจสอบความถูกต้อง — ยกเลิกการติดตั้ง');
      }
      if (await target.exists()) await target.delete();
      return part.rename(target.path);
    } on UpdateException {
      await _discard(sink, part);
      rethrow;
    } on _Busy {
      await _discard(sink, part);
      rethrow;
    } on TimeoutException {
      await _discard(sink, part);
      throw const UpdateException('การดาวน์โหลดหยุดนิ่ง — ตรวจอินเทอร์เน็ตแล้วลองใหม่');
    } catch (e) {
      debugPrint('AutoUpdater.downloadVerified failed: $e');
      await _discard(sink, part);
      throw const UpdateException('ดาวน์โหลดไม่สำเร็จ — ตรวจอินเทอร์เน็ตแล้วลองใหม่');
    } finally {
      client.close(force: true);
    }
  }

  static Future<void> _discard(IOSink? sink, File part) async {
    try {
      await sink?.close();
    } catch (_) {}
    try {
      if (await part.exists()) await part.delete();
    } catch (_) {}
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
    try {
      if (!kIsWeb && Platform.isWindows) {
        await _installWindows(info, onProgress: onProgress, onBeforeRestart: onBeforeRestart);
      } else if (!kIsWeb && Platform.isAndroid) {
        await _installAndroid(info, onProgress: onProgress);
        onComplete?.call();
      } else {
        onError?.call('$platformLabel ต้องติดตั้งเวอร์ชันใหม่ผ่านร้านค้าแอป');
      }
    } on UpdateException catch (e) {
      onError?.call(e.message);
    } catch (e) {
      debugPrint('AutoUpdater.downloadAndInstall failed: $e');
      onError?.call('อัปเดตไม่สำเร็จ — ลองใหม่อีกครั้ง');
    }
  }

  Future<void> _installAndroid(UpdateInfo info, {void Function(double percent, String status)? onProgress}) async {
    // Android 8+: REQUEST_INSTALL_PACKAGES + user-granted "install unknown apps".
    final installPerm = await Permission.requestInstallPackages.status;
    if (!installPerm.isGranted) {
      final asked = await Permission.requestInstallPackages.request();
      if (!asked.isGranted) {
        throw const UpdateException('ยังไม่ได้อนุญาตให้ติดตั้งแอป — เปิดสิทธิ์ "ติดตั้งแอปที่ไม่รู้จัก" ให้ Thai Prompt POS แล้วลองอีกครั้ง');
      }
    }
    final dir = await getTemporaryDirectory();
    onProgress?.call(0, 'กำลังดาวน์โหลด 0%');
    final apk = await downloadVerified(
      Uri.parse(info.assetUrl),
      File(p.join(dir.path, 'thaiprompt-pos-update.apk')),
      size: info.sizeBytes,
      sha256: info.sha256,
      onProgress: (pct) => onProgress?.call(pct, 'กำลังดาวน์โหลด ${pct.toStringAsFixed(0)}%'),
      onBusyWait: (s) => onProgress?.call(0, 'ผู้ดาวน์โหลดเต็ม — จะลองใหม่ใน $s วินาที'),
    );
    onProgress?.call(100, 'ตรวจสอบไฟล์แล้ว — เปิดหน้าติดตั้ง');
    try {
      await _installer.invokeMethod<bool>('installApk', {'filePath': apk.path});
    } on PlatformException catch (e) {
      debugPrint('installApk failed: ${e.code} ${e.message}');
      throw const UpdateException('เปิดหน้าติดตั้งไม่ได้ — ลองใหม่อีกครั้ง');
    }
  }

  Future<void> _installWindows(
    UpdateInfo info, {
    void Function(double percent, String status)? onProgress,
    Future<void> Function()? onBeforeRestart,
  }) async {
    final exe = Platform.resolvedExecutable;
    final installDir = p.dirname(exe);

    // The helper copies files into the install folder — it must be writable.
    try {
      final probe = File(p.join(installDir, '.tp_update_probe'));
      await probe.writeAsString('ok', flush: true);
      await probe.delete();
    } catch (_) {
      throw const UpdateException(
          'โฟลเดอร์ที่ติดตั้งแอปไม่อนุญาตให้เขียนไฟล์ — ย้ายโฟลเดอร์ Thai Prompt POS ไปไว้ที่ C:\\ThaipromptPOS หรือเปิดแอปด้วยสิทธิ์ผู้ดูแลระบบ แล้วลองใหม่');
    }

    final work = Directory(p.join(Directory.systemTemp.path, 'thaiprompt_pos_update'));
    if (await work.exists()) await work.delete(recursive: true);
    await work.create(recursive: true);

    onProgress?.call(0, 'กำลังดาวน์โหลด 0%');
    final zip = await downloadVerified(
      Uri.parse(info.assetUrl),
      File(p.join(work.path, 'update.zip')),
      size: info.sizeBytes,
      sha256: info.sha256,
      onProgress: (pct) => onProgress?.call(pct, 'กำลังดาวน์โหลด ${pct.toStringAsFixed(0)}%'),
      onBusyWait: (s) => onProgress?.call(0, 'ผู้ดาวน์โหลดเต็ม — จะลองใหม่ใน $s วินาที'),
    );

    onProgress?.call(100, 'ตรวจสอบไฟล์แล้ว — กำลังติดตั้งและเปิดแอปใหม่');
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
        '-Zip', zip.path,
        '-Target', installDir,
        '-Exe', p.basename(exe),
      ],
      mode: ProcessStartMode.detached,
    );
    // Give the helper a moment to start, then quit so files can be replaced.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    exit(0);
  }
}

/// 503 from the download slot pool; [seconds] = Retry-After.
class _Busy implements Exception {
  final int seconds;
  const _Busy(this.seconds);
}

/// Collects the single digest a chunked SHA-256 conversion emits.
class _DigestSink implements Sink<crypto.Digest> {
  crypto.Digest? _value;
  crypto.Digest get value => _value!;

  @override
  void add(crypto.Digest data) => _value = data;

  @override
  void close() {}
}
