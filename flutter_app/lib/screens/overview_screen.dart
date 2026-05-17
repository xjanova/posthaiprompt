// Thaiprompt POS — Overview (landing) screen
// by xman studio

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/tp_tokens.dart';
import '../widgets/glass_card.dart';
import '../widgets/tp_button.dart';
import '../widgets/tp_orb.dart';
import '../services/auto_updater.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  UpdateInfo? _updateInfo;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    // Silent update check on launch (1.5s after first frame so UI settles).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1500), _checkUpdate);
    });
  }

  Future<void> _checkUpdate() async {
    if (_checking) return;
    setState(() => _checking = true);
    final updater = AutoUpdater(owner: 'xjanova', repo: 'posthaiprompt');
    final info = await updater.checkForUpdate();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _updateInfo = info;
    });
  }

  void _showUpdateDialog(UpdateInfo info) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _UpdateDialog(info: info),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: TpTokens.canvasGradient),
        child: Stack(
          children: [
            const TpOrbBackdrop(),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand row
                    Row(
                      children: [
                        const TpBrandMark(size: 44),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Thaiprompt POS',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: TpTokens.ink)),
                              Text('POINT OF SALE · by xman studio',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                      letterSpacing: 1.5, color: TpTokens.inkMute)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined, color: TpTokens.inkSoft),
                          onPressed: () => context.go('/settings'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Update banner (if available)
                    if (_updateInfo != null && _updateInfo!.hasUpdate)
                      _UpdateBanner(info: _updateInfo!, onTap: () => _showUpdateDialog(_updateInfo!)),

                    // Hero with multi-orb decoration
                    Container(
                      decoration: BoxDecoration(
                        gradient: TpTokens.tealGradient,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: TpTokens.tealDeep.withValues(alpha: 0.35),
                            offset: const Offset(0, 24),
                            blurRadius: 50,
                            spreadRadius: -8,
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.6),
                            offset: const Offset(0, 1),
                            blurRadius: 0,
                            spreadRadius: -1,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(26),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Coral orb (top-right)
                          Positioned(
                            right: -50, top: -60,
                            child: Container(
                              width: 200, height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    TpTokens.coral.withValues(alpha: 0.55),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Gold orb (bottom-right, blurred)
                          Positioned(
                            right: 60, bottom: -40,
                            child: Container(
                              width: 120, height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: TpTokens.gold.withValues(alpha: 0.3),
                                boxShadow: [
                                  BoxShadow(color: TpTokens.gold.withValues(alpha: 0.45),
                                      blurRadius: 40, spreadRadius: 8),
                                ],
                              ),
                            ),
                          ),
                          // Glassy white orb (decorative)
                          Positioned(
                            right: 110, top: 60,
                            child: Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.18),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text('✨  THAIPROMPT POS · MAUI EDITION',
                                    style: TextStyle(fontSize: 10, color: Colors.white,
                                        letterSpacing: 1.5, fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(height: 14),
                              const Text('ระบบ POS',
                                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800,
                                      color: Colors.white, height: 1.0)),
                              const Text('ครบวงจร',
                                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800,
                                      color: Colors.white, height: 1.05)),
                              const SizedBox(height: 12),
                              const Text('Android · ออฟไลน์ได้ · ซิงก์อัตโนมัติ',
                                  style: TextStyle(fontSize: 13, color: Colors.white, height: 1.5)),
                              const Text('กดการ์ดด้านล่างเพื่อเปิดแต่ละหน้าจอ',
                                  style: TextStyle(fontSize: 13, color: Colors.white, height: 1.5)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Cards grid 2x3
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.95,
                      children: [
                        _OverviewCard(
                          step: '01 · LOGIN',
                          title: 'เข้าสู่ระบบ',
                          desc: 'PIN เข้าระบบ · เลือกผู้ใช้',
                          icon: '🔑',
                          gradient: TpTokens.indigoGradient,
                          onTap: () => context.go('/login'),
                        ),
                        _OverviewCard(
                          step: '02 · CASHIER ★',
                          title: 'แคชเชียร์',
                          desc: 'จอขายหลัก · ตัดบิล · รับชำระ',
                          icon: '🛒',
                          gradient: TpTokens.tealGradient,
                          onTap: () => context.go('/cashier'),
                        ),
                        _OverviewCard(
                          step: '03 · PAYMENT',
                          title: 'ชำระเงิน',
                          desc: 'เงินสด · QR · บัตร',
                          icon: '💳',
                          gradient: TpTokens.coralGradient,
                          onTap: () => context.go('/payment'),
                        ),
                        _OverviewCard(
                          step: '04 · RECEIPT',
                          title: 'ใบเสร็จ',
                          desc: 'พิมพ์ thermal 80mm',
                          icon: '🧾',
                          gradient: TpTokens.goldGradient,
                          onTap: () => context.go('/receipt'),
                        ),
                        _OverviewCard(
                          step: '07 · DASHBOARD',
                          title: 'แดชบอร์ดยอดขาย',
                          desc: 'KPI · กราฟ · เมนูขายดี',
                          icon: '📊',
                          gradient: TpTokens.purpleGradient,
                          onTap: () => context.go('/dashboard'),
                        ),
                        _OverviewCard(
                          step: '⚙ · SETTINGS',
                          title: 'ตั้งค่า + อัปเดต',
                          desc: 'ตรวจสอบเวอร์ชัน · sync API',
                          icon: '⚙️',
                          gradient: TpTokens.mintGradient,
                          onTap: () => context.go('/settings'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        '✨  Built with ❤ by xman studio',
                        style: TextStyle(
                          fontSize: 11,
                          color: TpTokens.inkMute.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String step, title, desc, icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _OverviewCard({
    required this.step,
    required this.title,
    required this.desc,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: TpTokens.coloredGlow(gradient.colors.last, intensity: 0.4),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 24)),
          ),
          const Spacer(),
          Text(step, style: const TextStyle(
            fontSize: 10, color: TpTokens.inkMute,
            letterSpacing: 1.5, fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(
            fontSize: 17, fontWeight: FontWeight.w700, color: TpTokens.ink,
          )),
          const SizedBox(height: 3),
          Text(desc, style: const TextStyle(
            fontSize: 11, color: TpTokens.inkSoft, height: 1.35,
          ), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _UpdateBanner extends StatelessWidget {
  final UpdateInfo info;
  final VoidCallback onTap;

  const _UpdateBanner({required this.info, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: TpTokens.coralGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: TpTokens.coloredGlow(TpTokens.coral),
            ),
            child: Row(
              children: [
                const Icon(Icons.system_update_outlined, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('มีอัปเดตใหม่!',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      Text(
                        'v${info.currentVersion} → v${info.latestVersion}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UpdateDialog extends StatefulWidget {
  final UpdateInfo info;
  const _UpdateDialog({required this.info});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  double _progress = 0;
  String _status = '';
  String? _error;
  bool _started = false;

  @override
  Widget build(BuildContext context) {
    final i = widget.info;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: TpTokens.coralGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.system_update, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('อัปเดตเวอร์ชันใหม่',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      Text('v${i.currentVersion} → v${i.latestVersion}',
                          style: const TextStyle(fontSize: 12, color: TpTokens.inkSoft)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TpTokens.bg1,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                i.releaseNotes.isEmpty ? '— ไม่มี release notes —' : i.releaseNotes,
                style: const TextStyle(fontSize: 12),
                maxLines: 8, overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Text('ขนาด ${(i.sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB',
                style: const TextStyle(fontSize: 11, color: TpTokens.inkMute)),
            const SizedBox(height: 16),
            if (_started) ...[
              LinearProgressIndicator(
                value: _progress / 100,
                backgroundColor: TpTokens.line,
                valueColor: const AlwaysStoppedAnimation(TpTokens.coral),
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Text(_status, style: const TextStyle(fontSize: 12)),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: TpTokens.danger, fontSize: 12)),
              ],
            ] else
              Row(
                children: [
                  Expanded(child: TpGhostButton(
                    label: 'ภายหลัง',
                    onPressed: () => Navigator.of(context).pop(),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: TpCoralButton(
                    label: 'อัปเดตเลย',
                    icon: Icons.download,
                    height: 46,
                    fontSize: 14,
                    onPressed: _start,
                  )),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _start() async {
    setState(() => _started = true);
    final updater = AutoUpdater(owner: 'xjanova', repo: 'posthaiprompt');
    await updater.downloadAndInstall(
      widget.info,
      onProgress: (pct, status) {
        if (mounted) setState(() { _progress = pct; _status = status; });
      },
      onError: (e) {
        if (mounted) setState(() => _error = e);
      },
    );
  }
}
