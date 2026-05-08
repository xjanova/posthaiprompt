// Thaiprompt POS — Settings + Update center
// by xman studio

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/auto_updater.dart';
import '../theme/tp_tokens.dart';
import '../widgets/glass_card.dart';
import '../widgets/tp_button.dart';
import '../widgets/tp_orb.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '...';
  String _build = '...';
  String _status = 'ยังไม่ได้ตรวจสอบ';
  bool _checking = false;
  UpdateInfo? _info;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((p) {
      if (mounted) {
        setState(() {
          _version = p.version;
          _build = p.buildNumber;
        });
      }
    });
  }

  Future<void> _check() async {
    setState(() { _checking = true; _status = 'กำลังเช็ค GitHub Releases...'; });
    final updater = AutoUpdater(owner: 'xjanova', repo: 'posthaiprompt');
    final info = await updater.checkForUpdate();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _info = info;
      if (info == null) {
        _status = '⚠️ ไม่สามารถเช็คได้ — ตรวจอินเทอร์เน็ตหรือยังไม่มี releases';
      } else if (info.hasUpdate) {
        _status = '🎉 มีอัปเดต! v${info.currentVersion} → v${info.latestVersion}';
      } else {
        _status = '✓ ใช้เวอร์ชันล่าสุดแล้ว';
      }
    });
  }

  Future<void> _install() async {
    if (_info == null || !_info!.hasUpdate) return;
    final updater = AutoUpdater(owner: 'xjanova', repo: 'posthaiprompt');
    await updater.downloadAndInstall(
      _info!,
      onProgress: (pct, status) {
        if (mounted) setState(() => _status = status);
      },
      onError: (e) {
        if (mounted) setState(() => _status = 'ผิดพลาด: $e');
      },
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: TpTokens.inkSoft),
                          onPressed: () => context.go('/'),
                        ),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('⚙️ ตั้งค่า + อัปเดต',
                                  style: TextStyle(fontSize: 11, color: TpTokens.inkMute, letterSpacing: 1.5)),
                              Text('Settings',
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    SoftCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const TpBrandMark(size: 48),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Thaiprompt POS',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                    Text('v$_version (build $_build) · Android',
                                        style: const TextStyle(fontSize: 11, color: TpTokens.inkMute)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: TpTokens.bg1,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(_status, style: const TextStyle(fontSize: 13)),
                          ),
                          const SizedBox(height: 14),
                          if (_info != null && _info!.hasUpdate)
                            TpCoralButton(
                              label: 'ดาวน์โหลด & ติดตั้ง v${_info!.latestVersion}',
                              icon: Icons.system_update,
                              onPressed: _install,
                            )
                          else
                            TpPrimaryButton(
                              label: _checking ? 'กำลังเช็ค...' : 'เช็คอัปเดตตอนนี้',
                              icon: Icons.refresh,
                              onPressed: _checking ? null : _check,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    SoftCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('การซิงก์ข้อมูล',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          SizedBox(height: 6),
                          Text('Endpoint: github.com/xjanova/Thaiprompt-Affiliate',
                              style: TextStyle(fontSize: 11, color: TpTokens.inkMute, fontFamily: 'monospace')),
                          SizedBox(height: 14),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.cloud_outlined, color: TpTokens.teal),
                            title: Text('Sync interval', style: TextStyle(fontSize: 13)),
                            trailing: Text('30 วินาที', style: TextStyle(fontSize: 12, color: TpTokens.inkMute)),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.cloud_off_outlined, color: TpTokens.coral),
                            title: Text('Outbox pending', style: TextStyle(fontSize: 13)),
                            trailing: Text('0 messages', style: TextStyle(fontSize: 12, color: TpTokens.inkMute)),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.access_time, color: TpTokens.gold),
                            title: Text('Last sync', style: TextStyle(fontSize: 13)),
                            trailing: Text('— never —', style: TextStyle(fontSize: 12, color: TpTokens.inkMute)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    SoftCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('เกี่ยวกับ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          SizedBox(height: 6),
                          Text('Thaiprompt POS Android · Flutter edition',
                              style: TextStyle(fontSize: 13)),
                          Text('สร้างโดย xman studio · 2026',
                              style: TextStyle(fontSize: 11, color: TpTokens.inkMute)),
                          SizedBox(height: 12),
                          Text('Repo: github.com/xjanova/posthaiprompt',
                              style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: TpTokens.tealDeep)),
                        ],
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
