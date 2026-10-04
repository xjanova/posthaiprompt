// Thaiprompt POS — background update watcher + update dialog.
//
// Asks xman4289.com for a newer release 20 s after launch and every 6 hours.
// When one is found the top bar shows a gold "อัปเดต" pill; the login screen
// installs it by itself (with a cancellable countdown) when auto-update is on
// and nobody is mid-sale. Installing from a staff screen needs a manager.
// Downloads are verified (size + SHA-256) before anything is installed.
//
// by xman studio

import 'dart:async';

import 'package:flutter/material.dart';

import '../state/app_scope.dart';
import '../widgets/nova/nova.dart';
import 'auto_updater.dart';

class UpdateWatcher extends ChangeNotifier {
  UpdateWatcher._();
  static final UpdateWatcher instance = UpdateWatcher._();

  final AutoUpdater _updater = AutoUpdater();

  UpdateInfo? available;
  DateTime? lastCheck;
  bool checking = false;
  bool installing = false;
  double progress = 0;
  String status = '';
  String? error;
  Timer? _timer;
  Timer? _first;

  void start() {
    _first ??= Timer(const Duration(seconds: 20), check);
    _timer ??= Timer.periodic(const Duration(hours: 6), (_) => check());
  }

  Future<UpdateInfo?> check() async {
    if (checking || installing) return available;
    checking = true;
    error = null;
    notifyListeners();
    final info = await _updater.checkForUpdate();
    checking = false;
    lastCheck = DateTime.now();
    available = (info != null && info.hasUpdate) ? info : null;
    notifyListeners();
    return info;
  }

  Future<void> install({Future<void> Function()? beforeRestart}) async {
    final info = available;
    if (info == null || installing) return;
    installing = true;
    error = null;
    progress = 0;
    status = 'กำลังเตรียมอัปเดต…';
    notifyListeners();
    await _updater.downloadAndInstall(
      info,
      onProgress: (pct, s) {
        progress = pct;
        status = s;
        notifyListeners();
      },
      onError: (e) {
        error = e;
        installing = false;
        notifyListeners();
      },
      onComplete: () {
        installing = false;
        notifyListeners();
      },
      onBeforeRestart: beforeRestart,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _first?.cancel();
    super.dispose();
  }
}

/// Nova dialog: version, what's new, progress, install / later.
Future<void> showUpdateDialog(BuildContext context, {bool requireManager = true}) async {
  final w = UpdateWatcher.instance;
  final info = w.available;
  if (info == null) return;
  if (requireManager) {
    final ok = await showManagerPin(context, reason: 'ติดตั้งเวอร์ชันใหม่ของ Thai Prompt POS');
    if (ok == null || !context.mounted) return;
  }
  final store = AppScope.read(context);
  await showNvDialog<void>(
    context,
    title: 'มีเวอร์ชันใหม่ ${info.latestVersion}',
    subtitle: 'ตอนนี้ใช้ ${info.currentVersion} · ${AutoUpdater.platformLabel}',
    art: 'sync',
    body: ListenableBuilder(
      listenable: w,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (info.releaseNotes.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Nv.paper, borderRadius: BorderRadius.circular(Nv.rSm), border: Border.all(color: Nv.line)),
              child: Text(info.releaseNotes, style: Nv.ui(13.5, color: Nv.ink2, height: 1.5)),
            ),
          const SizedBox(height: 12),
          if (!AutoUpdater.canSelfInstall)
            Text('${AutoUpdater.platformLabel} ติดตั้งเวอร์ชันใหม่ผ่านร้านค้าแอปหรือติดต่อ xman studio (xman4289.com)',
                style: Nv.ui(13, color: Nv.ink3))
          else if (w.installing || w.progress > 0) ...[
            LinearProgressIndicator(value: w.progress > 0 ? (w.progress / 100).clamp(0.0, 1.0) : null, minHeight: 8),
            const SizedBox(height: 8),
            Text(w.status, style: Nv.ui(13, color: Nv.ink2)),
          ] else
            Text(
              AutoUpdater.platformLabel == 'Windows'
                  ? 'แอปจะปิดตัวเอง ติดตั้งไฟล์ใหม่ แล้วเปิดขึ้นมาอีกครั้ง (ข้อมูลร้านยังอยู่ครบ)'
                  : 'ระบบจะดาวน์โหลดและเปิดหน้าติดตั้งของเครื่อง (ข้อมูลร้านยังอยู่ครบ)',
              style: Nv.ui(13, color: Nv.ink3, height: 1.45),
            ),
          if (w.error != null) ...[
            const SizedBox(height: 8),
            Text(w.error!, style: Nv.ui(13, color: Nv.lacquer, weight: FontWeight.w600)),
          ],
        ],
      ),
    ),
    actions: (ctx) => [
      NvButton.soft('ภายหลัง', onPressed: () => Navigator.of(ctx).pop()),
      if (AutoUpdater.canSelfInstall)
        ListenableBuilder(
          listenable: w,
          builder: (_, _) => NvButton.gold(
            'ติดตั้งตอนนี้',
            icon: NvIcons.download,
            loading: w.installing,
            onPressed: w.installing ? null : () => w.install(beforeRestart: store.flush),
          ),
        ),
    ],
  );
}

/// Gold top-bar pill shown while an update is available.
class NvUpdatePill extends StatelessWidget {
  final bool night;
  const NvUpdatePill({super.key, this.night = false});

  @override
  Widget build(BuildContext context) {
    final w = UpdateWatcher.instance;
    return ListenableBuilder(
      listenable: w,
      builder: (context, _) {
        final info = w.available;
        if (info == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Tooltip(
            message: 'มีเวอร์ชันใหม่ ${info.latestVersion} — แตะเพื่อติดตั้ง',
            child: InkWell(
              borderRadius: BorderRadius.circular(Nv.rPill),
              onTap: () => showUpdateDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(gradient: Nv.btnGold, borderRadius: BorderRadius.circular(Nv.rPill), boxShadow: Nv.goldGlow(0.6)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(NvIcons.download, size: 13, color: Color(0xFF1A1405)),
                    const SizedBox(width: 6),
                    Text('อัปเดต ${info.latestVersion}',
                        style: Nv.ui(12.5, color: const Color(0xFF1A1405), weight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
