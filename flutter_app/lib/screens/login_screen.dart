// Thaiprompt POS — Login (Screen #04): pick a staff member, enter PIN.
//
// Real auth: PINs are verified against salted SHA-256 hashes in the store;
// 5 wrong tries lock that staff member for 2 minutes (persisted, survives a
// restart). After login, cashiers/managers are asked to open the shift when
// the shop requires one, then land on their role's home screen.
//
// by xman studio

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../models/extra_models.dart';
import '../services/auto_updater.dart';
import '../services/update_watcher.dart';
import '../state/app_scope.dart';
import '../widgets/nova/nova.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? _staffId;
  String _pin = '';
  String? _error;
  bool _busy = false;

  Staff? _selected(BuildContext context) {
    final store = AppScope.of(context);
    final list = store.activeStaff;
    if (list.isEmpty) return null;
    final id = _staffId ?? (list.length == 1 ? list.first.id : null);
    return id == null ? null : store.staffById(id);
  }

  void _digit(String d) {
    if (_pin.length >= 6 || _busy) return;
    setState(() {
      _pin += d;
      _error = null;
    });
  }

  void _back() => setState(() => _pin = _pin.isEmpty ? '' : _pin.substring(0, _pin.length - 1));

  Future<void> _submit() async {
    final store = AppScope.read(context);
    final s = _selected(context);
    if (s == null || _pin.length < 4 || _busy) return;
    final res = store.login(s.id, _pin);
    switch (res) {
      case LoginOk(:final staff):
        setState(() => _busy = true);
        await _maybeOpenShift(staff);
        if (!mounted) return;
        context.go(staff.role.home);
      case LoginWrongPin(:final attemptsLeft):
        HapticFeedback.heavyImpact();
        setState(() {
          _pin = '';
          _error = 'PIN ไม่ถูกต้อง · เหลือ $attemptsLeft ครั้งก่อนล็อก';
        });
      case LoginLocked(:final until):
        HapticFeedback.heavyImpact();
        setState(() {
          _pin = '';
          _error = 'ใส่ PIN ผิดหลายครั้ง · ล็อกถึง ${hm(until)} น.';
        });
    }
  }

  Future<void> _maybeOpenShift(Staff staff) async {
    final store = AppScope.read(context);
    if (!store.requireShift || store.hasOpenShift || !staff.role.canSell || staff.role == StaffRole.waiter) return;
    final amount = await showNvAmountDialog(
      context,
      title: 'เปิดกะการขาย',
      subtitle: 'ใส่เงินทอนตั้งต้นในลิ้นชัก (ข้ามได้ แล้วเปิดกะภายหลังที่เมนู "กะ")',
      art: 'drawer',
      confirmLabel: 'เปิดกะ',
      initial: store.shiftHistory.isNotEmpty ? store.shiftHistory.first.openingCash : null,
    );
    if (amount != null) store.openShift(openingCash: amount);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final staff = store.activeStaff;
    final sel = _selected(context);
    final locked = sel?.isLocked ?? false;

    final panel = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 470),
      child: Container(
        padding: const EdgeInsets.fromLTRB(28, 26, 28, 22),
        decoration: BoxDecoration(
          color: Nv.navy900.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(Nv.rXl),
          border: Border.all(color: Nv.lineNightStrong),
          boxShadow: Nv.shadowNight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NvArt(NvAssets.logoOnDark, height: 44, width: 170),
            const SizedBox(height: 10),
            NvFoilText(
              store.shopName,
              style: Nv.display(26, weight: FontWeight.w700),
              align: TextAlign.center,
            ),
            Text(store.branch, style: Nv.ui(13.5, color: Nv.onNight3)),
            const SizedBox(height: 8),
            const NvKanokDivider(width: 220, thin: true, opacity: 0.85),
            const SizedBox(height: 12),
            if (store.restoredFromBackup)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Nv.amber.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(Nv.rSm),
                  border: Border.all(color: Nv.amber.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(NvIcons.warning, size: 14, color: Nv.gold300),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ไฟล์ข้อมูลหลักเสียหาย ระบบกู้คืนจากสำเนาล่าสุดให้แล้ว — โปรดตรวจยอดขายล่าสุด',
                        style: Nv.ui(12, color: Nv.gold200),
                      ),
                    ),
                  ],
                ),
              ),
            if (staff.length > 1) ...[
              Text(
                'เลือกผู้ใช้งาน',
                style: Nv.ui(13, color: Nv.onNight2, weight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 104,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  itemCount: staff.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final s = staff[i];
                    final on = sel?.id == s.id;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _staffId = s.id;
                        _pin = '';
                        _error = null;
                      }),
                      child: SizedBox(
                        width: 78,
                        child: Column(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                AnimatedContainer(
                                  duration: Nv.fast,
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: on ? Nv.btnGold : null,
                                    boxShadow: on ? Nv.goldGlow(0.8) : null,
                                  ),
                                  child: NvAvatar(s.initials, hue: s.hue, size: 52),
                                ),
                                if (s.isLocked)
                                  const Positioned(
                                    right: -2,
                                    bottom: -2,
                                    child: CircleAvatar(
                                      radius: 10,
                                      backgroundColor: Nv.lacquer,
                                      child: Icon(NvIcons.lock, size: 9, color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              s.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Nv.ui(12, color: on ? Nv.gold200 : Nv.onNight2, weight: FontWeight.w600),
                            ),
                            Text(
                              s.role.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Nv.ui(10, color: Nv.onNight3),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ] else if (sel != null) ...[
              NvAvatar(sel.initials, hue: sel.hue, size: 58, ring: true),
              const SizedBox(height: 6),
              Text(
                '${sel.name} · ${sel.role.label}',
                style: Nv.ui(14, color: Nv.onNight, weight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
            ],
            if (sel == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Text('แตะชื่อของคุณเพื่อใส่ PIN', style: Nv.ui(14, color: Nv.onNight3)),
              )
            else ...[
              NvPinDots(length: _pin.length, error: _error != null, onNight: true),
              const SizedBox(height: 8),
              SizedBox(
                height: 20,
                child: Text(
                  locked ? 'บัญชีนี้ถูกล็อกชั่วคราวถึง ${hm(sel.lockedUntil!)} น.' : (_error ?? ''),
                  style: Nv.ui(12.5, color: Nv.lacquerLight, weight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 6),
              NvPinPad(onDigit: _digit, onBackspace: _back, onSubmit: _pin.length >= 4 && !locked ? _submit : null, onNight: true),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () => showNvDialog(
                  context,
                  title: 'ลืม PIN?',
                  art: 'shield',
                  body: Text(
                    'ให้เจ้าของร้านหรือผู้จัดการเข้าสู่ระบบ แล้วไปที่ ตั้งค่า → พนักงาน เพื่อตั้ง PIN ใหม่ให้คุณ\n\nเพื่อความปลอดภัย ระบบไม่สามารถแสดง PIN เดิมได้',
                    textAlign: TextAlign.center,
                    style: Nv.ui(14, color: Nv.ink2, height: 1.5),
                  ),
                  actions: (ctx) => [NvButton.gold('เข้าใจแล้ว', onPressed: () => Navigator.of(ctx).pop())],
                ),
                icon: const Icon(NvIcons.question, size: 13, color: Nv.gold300),
                label: Text(
                  'ลืม PIN?',
                  style: Nv.ui(13, color: Nv.gold300, weight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: Scaffold(
        backgroundColor: Nv.navy950,
        body: NvBackdrop.night(
          image: NvAssets.art('login-hero'),
          imageAlignment: Alignment.centerRight,
          child: LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth > 960;
              return Stack(
                children: [
                  // navy wash on the left so the panel reads over the scene
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Nv.navy950.withValues(alpha: wide ? 0.92 : 0.8),
                            Nv.navy950.withValues(alpha: wide ? 0.25 : 0.7),
                          ],
                          stops: const [0.25, 0.75],
                        ),
                      ),
                    ),
                  ),
                  if (wide) Positioned(right: 30, bottom: 0, child: NvArt.mascot('welcome', height: c.maxHeight * 0.72)),
                  if (wide)
                    Positioned(
                      top: 22,
                      right: 28,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                        decoration: BoxDecoration(
                          color: Nv.navy950.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(Nv.rLg),
                          border: Border.all(color: Nv.lineNight),
                        ),
                        child: const NvClock(night: true, large: true),
                      ),
                    ),
                  Align(
                    alignment: wide ? const Alignment(-0.72, 0) : Alignment.center,
                    child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: panel),
                  ),
                  const Positioned(top: 18, left: 0, right: 0, child: Center(child: _AutoUpdateBanner())),
                  Positioned(
                    left: 24,
                    bottom: 14,
                    child: Text('Thai Prompt POS · ธีมโนวา · by xman studio', style: Nv.ui(11.5, color: Nv.onNight3)),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// On the login screen nobody is mid-sale, so a downloaded-and-ready update
/// installs itself after a short, cancellable countdown (when auto-update is on).
class _AutoUpdateBanner extends StatefulWidget {
  const _AutoUpdateBanner();

  @override
  State<_AutoUpdateBanner> createState() => _AutoUpdateBannerState();
}

class _AutoUpdateBannerState extends State<_AutoUpdateBanner> {
  static bool _cancelledThisSession = false;
  Timer? _tick;
  int _left = 15;

  @override
  void initState() {
    super.initState();
    UpdateWatcher.instance.addListener(_onUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onUpdate());
  }

  void _onUpdate() {
    if (!mounted) return;
    final w = UpdateWatcher.instance;
    final store = AppScope.read(context);
    final eligible = w.available != null &&
        w.available!.hasInstaller &&
        AutoUpdater.canSelfInstall &&
        store.autoUpdate &&
        !_cancelledThisSession &&
        store.cart.isEmpty &&
        !w.installing;
    if (eligible && _tick == null) {
      _left = 15;
      _tick = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return t.cancel();
        setState(() => _left--);
        if (_left <= 0) {
          t.cancel();
          _tick = null;
          UpdateWatcher.instance.install(beforeRestart: AppScope.read(context).flush);
        }
      });
    }
    setState(() {});
  }

  @override
  void dispose() {
    UpdateWatcher.instance.removeListener(_onUpdate);
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = UpdateWatcher.instance;
    final info = w.available;
    if (info == null || (!w.installing && _tick == null && w.error == null)) return const SizedBox.shrink();
    final text = w.error != null
        ? 'อัปเดตไม่สำเร็จ: ${w.error}'
        : w.installing
            ? 'กำลังอัปเดตเป็นเวอร์ชัน ${info.latestVersion} · ${w.status}'
            : 'จะติดตั้งเวอร์ชันใหม่ ${info.latestVersion} อัตโนมัติใน $_left วินาที';
    return Container(
      constraints: const BoxConstraints(maxWidth: 560),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      decoration: BoxDecoration(
        color: Nv.navy900.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(Nv.rPill),
        border: Border.all(color: Nv.lineNightStrong),
        boxShadow: Nv.goldGlow(0.4),
      ),
      child: Row(
        children: [
          const Icon(NvIcons.download, size: 15, color: Nv.gold300),
          const SizedBox(width: 10),
          Expanded(child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.ui(13, color: Nv.onNight))),
          if (!w.installing && _tick != null) ...[
            NvButton.ghost('ยกเลิก', size: NvButtonSize.sm, onNight: true, onPressed: () {
              _tick?.cancel();
              setState(() {
                _tick = null;
                _cancelledThisSession = true;
              });
            }),
            const SizedBox(width: 6),
            NvButton.gold('ติดตั้งเลย', size: NvButtonSize.sm, onPressed: () {
              _tick?.cancel();
              setState(() => _tick = null);
              UpdateWatcher.instance.install(beforeRestart: AppScope.read(context).flush);
            }),
          ],
        ],
      ),
    );
  }
}
