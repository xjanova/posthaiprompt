// Thaiprompt POS — Security & audit (Nova).
//
// • Audit log — the store's real activity log (logins, checkouts, refunds,
//   stock, price and settings changes…), searchable, filterable by kind.
// • Role matrix — what each role can open/do, computed from the router guard
//   itself (AppRouter.guardFor) plus the manager-PIN rules, so it can't drift.
// • Locked accounts — unlock = set a new PIN (manager approval; owner accounts
//   need an owner's PIN). Manager-override lock status.
// • Data — where data lives + "บันทึกข้อมูลทันที" (flush to disk now).
//
// by xman studio

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/extra_models.dart';
import '../routes/app_router.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';
import 'staff_screen.dart' show StaffPinForm;

/// Thai labels for the store's audit action keys.
const _actionLabels = <String, String>{
  'setup': 'ตั้งค่าร้านครั้งแรก',
  'login': 'เข้าสู่ระบบ',
  'login.locked': 'ล็อกบัญชี (PIN ผิดหลายครั้ง)',
  'logout': 'ล็อกหน้าจอ',
  'logout.clockout': 'ออกกะ / ลงเวลาออก',
  'clockout': 'ลงเวลาออกให้พนักงาน',
  'override.locked': 'ล็อกการอนุมัติ (PIN ผู้จัดการผิด)',
  'staff.add': 'เพิ่มพนักงาน',
  'staff.edit': 'แก้ไขพนักงาน',
  'staff.pin': 'เปลี่ยน PIN',
  'staff.remove': 'ลบพนักงาน',
  'price': 'เปลี่ยนราคา',
  'product.add': 'เพิ่มสินค้า',
  'product.remove': 'ลบสินค้า',
  'category.add': 'เพิ่มหมวดหมู่',
  'category.remove': 'ลบหมวดหมู่',
  'stock': 'ปรับสต็อก',
  'hold': 'พักบิล',
  'hold.delete': 'ลบบิลที่พัก',
  'split': 'แยกบิล',
  'checkout': 'รับชำระเงิน',
  'refund': 'คืนเงิน',
  'reprint': 'พิมพ์ใบเสร็จซ้ำ',
  'ticket': 'ส่งออเดอร์เข้าครัว',
  'ticket.cancel': 'ยกเลิกออเดอร์ครัว',
  'call.waiter': 'ลูกค้าเรียกพนักงาน',
  'self.order': 'ลูกค้าสั่งเอง',
  'taxinvoice': 'ออกใบกำกับภาษี',
  'customer.add': 'เพิ่มสมาชิก',
  'customer.remove': 'ลบสมาชิก',
  'points': 'ปรับแต้มสมาชิก',
  'tier': 'แก้ไขระดับสมาชิก',
  'coupon': 'บันทึกคูปอง',
  'coupon.remove': 'ลบคูปอง',
  'promotion': 'บันทึกโปรโมชั่น',
  'promotion.remove': 'ลบโปรโมชั่น',
  'table.add': 'เพิ่มโต๊ะ',
  'table.remove': 'ลบโต๊ะ',
  'shift.open': 'เปิดกะ',
  'shift.close': 'ปิดกะ (Z-Report)',
  'drawer': 'เงินเข้า/ออกลิ้นชัก',
  'supplier.add': 'เพิ่มซัพพลายเออร์',
  'supplier.remove': 'ลบซัพพลายเออร์',
  'po.create': 'สร้างใบสั่งซื้อ',
  'po.order': 'ส่งใบสั่งซื้อ',
  'po.receive': 'รับสินค้าเข้า',
  'po.cancel': 'ยกเลิกใบสั่งซื้อ',
  'delivery': 'สร้างงานจัดส่ง',
  'delivery.status': 'อัปเดตสถานะจัดส่ง',
  'delivery.cancel': 'ยกเลิกงานจัดส่ง',
  'branch.add': 'เพิ่มสาขา',
  'branch.edit': 'แก้ไขสาขา',
  'branch.remove': 'ลบสาขา',
  'branch.switch': 'เปลี่ยนสาขาของเครื่อง',
  'settings': 'แก้ไขการตั้งค่า',
  'server.config': 'ตั้งค่าเซิร์ฟเวอร์',
  'server.pair': 'จับคู่เซิร์ฟเวอร์',
  'server.unpair': 'เลิกจับคู่เซิร์ฟเวอร์',
  'data.flush': 'บันทึกข้อมูลลงเครื่อง',
};

String _actionLabel(String a) => _actionLabels[a] ?? a;

typedef _Group = ({String key, String label, bool Function(String a) test, IconData icon, NvTint tint});

final List<_Group> _groups = [
  (key: 'all', label: 'ทั้งหมด', test: (_) => true, icon: NvIcons.list, tint: NvTint.neutral),
  (
    key: 'login',
    label: 'เข้าระบบ',
    test: (a) => a.startsWith('login') || a.startsWith('logout') || a == 'clockout' || a == 'setup',
    icon: NvIcons.login,
    tint: NvTint.sapphire,
  ),
  (
    key: 'sale',
    label: 'ขาย',
    test: (a) => const {'checkout', 'hold', 'hold.delete', 'split', 'ticket', 'self.order', 'taxinvoice', 'reprint', 'call.waiter'}.contains(a),
    icon: NvIcons.cashier,
    tint: NvTint.jade,
  ),
  (
    key: 'refund',
    label: 'คืนเงิน/ยกเลิก',
    test: (a) => a == 'refund' || a == 'ticket.cancel' || a.startsWith('void'),
    icon: NvIcons.refund,
    tint: NvTint.lacquer,
  ),
  (
    key: 'stock',
    label: 'สต็อก',
    test: (a) => a == 'stock' || a.startsWith('po.') || a.startsWith('supplier'),
    icon: NvIcons.inventory,
    tint: NvTint.amber,
  ),
  (
    key: 'menu',
    label: 'เมนู/ราคา',
    test: (a) => a == 'price' || a.startsWith('product') || a.startsWith('category'),
    icon: NvIcons.menuBook,
    tint: NvTint.gold,
  ),
  (key: 'shift', label: 'กะ/ลิ้นชัก', test: (a) => a.startsWith('shift') || a == 'drawer', icon: NvIcons.drawer, tint: NvTint.gold),
  (key: 'staff', label: 'พนักงาน', test: (a) => a.startsWith('staff'), icon: NvIcons.staff, tint: NvTint.navy),
  (
    key: 'settings',
    label: 'ตั้งค่า/สาขา',
    test: (a) => a == 'settings' || a.startsWith('server') || a.startsWith('branch') || a.startsWith('table') || a == 'data.flush',
    icon: NvIcons.settings,
    tint: NvTint.navy,
  ),
  (
    key: 'security',
    label: 'ความปลอดภัย',
    test: (a) => a.endsWith('.locked') || a == 'staff.pin' || a == 'staff.remove' || a == 'server.unpair',
    icon: NvIcons.shield,
    tint: NvTint.lacquer,
  ),
  (
    key: 'crm',
    label: 'ลูกค้า/โปร',
    test: (a) => a.startsWith('customer') || a == 'points' || a == 'tier' || a.startsWith('coupon') || a.startsWith('promotion'),
    icon: NvIcons.members,
    tint: NvTint.amethyst,
  ),
  (key: 'delivery', label: 'จัดส่ง', test: (a) => a.startsWith('delivery'), icon: NvIcons.delivery, tint: NvTint.sapphire),
];

_Group _groupFor(String action) {
  for (final g in _groups.skip(1)) {
    if (g.key == 'security') continue; // overlay filter, not a home group
    if (g.test(action)) return g;
  }
  return _groups.first;
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String _query = '';
  String _group = 'all';
  int _tab = 0;
  bool _saving = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // lock timers (staff + manager override) expire without a store change
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _unlock(Staff s) async {
    final store = AppScope.read(context);
    final meOwner = store.currentStaff?.role == StaffRole.owner;
    Staff? appr;
    if (s.role == StaffRole.owner && !meOwner) {
      appr = await showManagerPin(context, reason: 'ปลดล็อกบัญชีเจ้าของร้าน ${s.name} · ต้องใช้ PIN เจ้าของร้าน', alwaysAsk: true);
      if (appr == null || !mounted) return;
      if (appr.role != StaffRole.owner) {
        nvToast(context, 'บัญชีเจ้าของร้านปลดล็อกได้ด้วย PIN ของเจ้าของร้านเท่านั้น', kind: NvToastKind.error);
        return;
      }
    } else {
      appr = await showManagerPin(context, reason: 'ปลดล็อกบัญชี ${s.name}');
      if (appr == null || !mounted) return;
    }
    final pin = await showNvDialog<String>(
      context,
      title: 'ปลดล็อกด้วย PIN ใหม่',
      subtitle: '${s.name} · ${s.role.label} — ตั้ง PIN ใหม่แล้วบัญชีจะใช้งานได้ทันที',
      art: 'shield',
      maxWidth: 420,
      body: StaffPinForm(staff: s),
    );
    if (pin == null || !mounted) return;
    store.setStaffPin(s, pin);
    nvToast(context, 'ปลดล็อก ${s.name} แล้ว (อนุมัติโดย ${appr.name})', kind: NvToastKind.success);
  }

  Future<void> _flush() async {
    if (_saving) return;
    setState(() => _saving = true);
    final store = AppScope.read(context);
    try {
      store.log('data.flush', '${store.orders.length} บิล');
      await store.flush();
      if (!mounted) return;
      nvToast(context, 'บันทึกข้อมูลลงเครื่องเรียบร้อย', kind: NvToastKind.success);
    } catch (_) {
      if (!mounted) return;
      nvToast(context, 'บันทึกไม่สำเร็จ — ตรวจพื้นที่ว่างของเครื่องแล้วลองใหม่', kind: NvToastKind.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return NvScaffold(
      title: 'ความปลอดภัย',
      eyebrow: 'บันทึกการใช้งาน · สิทธิ์',
      subtitle: '${store.auditLog.length} รายการในบันทึก',
      art: 'shield',
      body: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        final audit = _auditPanel(store);
        final side = ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _lockedCard(store),
            const SizedBox(height: 14),
            _matrixCard(w < 520),
            const SizedBox(height: 14),
            _dataCard(store),
          ],
        );
        if (w >= 1100) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 4), child: audit)),
              const SizedBox(width: 14),
              SizedBox(width: math.min(480, w * 0.4), child: side),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: NvSegmented<int>(
                options: const [(0, 'บันทึกการใช้งาน'), (1, 'สิทธิ์และบัญชี')],
                value: _tab,
                onChanged: (v) => setState(() => _tab = v),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _tab == 0 ? audit : side),
          ],
        );
      }),
    );
  }

  // ───────────────────────── audit log ─────────────────────────

  Widget _auditPanel(PosStore store) {
    final q = _query.trim().toLowerCase();
    final group = _groups.firstWhere((g) => g.key == _group, orElse: () => _groups.first);
    final entries = store.auditLog.where((e) {
      if (!group.test(e.action)) return false;
      if (q.isEmpty) return true;
      return e.action.toLowerCase().contains(q) ||
          _actionLabel(e.action).toLowerCase().contains(q) ||
          e.actor.toLowerCase().contains(q) ||
          e.detail.toLowerCase().contains(q);
    }).toList();

    return NvSheet(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(builder: (context, c) {
            final title = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                NvArt.icon('shield', size: 40),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('บันทึกการใช้งาน', style: Nv.display(18)),
                      Text('แสดง ${groupDigits(entries.length)} จาก ${groupDigits(store.auditLog.length)} รายการ · เก็บล่าสุด 1,500 รายการ',
                          style: Nv.ui(11.5, color: Nv.ink3)),
                    ],
                  ),
                ),
              ],
            );
            final search = NvSearchField(hint: 'ค้นหาผู้ทำรายการ เลขบิล รายละเอียด…', onChanged: (v) => setState(() => _query = v));
            if (c.maxWidth < 640) {
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [title, const SizedBox(height: 10), search]);
            }
            return Row(children: [Expanded(child: title), const SizedBox(width: 12), SizedBox(width: 300, child: search)]);
          }),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final g in _groups) ...[
                  NvChip(
                    g.label,
                    icon: g.icon,
                    selected: _group == g.key,
                    count: g.key == 'all' ? store.auditLog.length : store.auditLog.where((e) => g.test(e.action)).length,
                    onTap: () => setState(() => _group = g.key),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
          Expanded(
            child: entries.isEmpty
                ? NvEmptyState(
                    mascot: store.auditLog.isEmpty ? 'sleepy' : 'search',
                    size: 120,
                    title: store.auditLog.isEmpty ? 'ยังไม่มีบันทึก' : 'ไม่พบรายการที่ตรงกัน',
                    message: store.auditLog.isEmpty
                        ? 'ทุกการเข้าระบบ ขาย คืนเงิน และแก้ไขข้อมูลจะถูกบันทึกที่นี่อัตโนมัติ'
                        : 'ลองเปลี่ยนคำค้นหรือหมวดที่เลือก',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 12),
                    itemCount: entries.length,
                    itemBuilder: (context, i) => _AuditRow(entry: entries[i]),
                  ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── side panels ─────────────────────────

  Widget _lockedCard(PosStore store) {
    final locked = store.staff.where((s) => s.isLocked).toList();
    final strikes = store.staff.where((s) => !s.isLocked && s.failedAttempts > 0).toList();
    final mgrLock = store.managerLockedUntil;
    return NvSheet(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              NvArt.icon('staff', size: 40),
              const SizedBox(width: 10),
              Expanded(child: Text('บัญชีที่ถูกล็อก', style: Nv.display(18))),
              NvButton.soft('พนักงาน', size: NvButtonSize.sm, onPressed: () => context.go('/staff')),
            ],
          ),
          const SizedBox(height: 4),
          Text('ใส่ PIN ผิด ${PosStore.maxPinAttempts} ครั้ง = ล็อก ${PosStore.pinLockDuration.inMinutes} นาที · ปลดล็อกทันทีด้วยการตั้ง PIN ใหม่',
              style: Nv.ui(12, color: Nv.ink3)),
          const SizedBox(height: 10),
          if (locked.isEmpty)
            Row(
              children: [
                const Icon(NvIcons.checkCircle, size: 15, color: Nv.jade),
                const SizedBox(width: 8),
                Text('ไม่มีบัญชีถูกล็อก', style: Nv.ui(13, color: Nv.ink2)),
              ],
            )
          else
            for (final s in locked)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    NvAvatar(s.initials, hue: s.hue, size: 36),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(13.5, weight: FontWeight.w700)),
                          Text('${s.role.label} · ล็อกถึง ${hm(s.lockedUntil!)}', style: Nv.ui(11.5, color: Nv.lacquer)),
                        ],
                      ),
                    ),
                    NvButton.gold('ปลดล็อก', icon: NvIcons.unlock, size: NvButtonSize.sm, onPressed: () => _unlock(s)),
                  ],
                ),
              ),
          if (strikes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in strikes) NvBadge('${s.name} ใส่ผิด ${s.failedAttempts} ครั้ง', tint: NvTint.amber),
              ],
            ),
          ],
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(mgrLock == null ? NvIcons.unlock : NvIcons.lock, size: 15, color: mgrLock == null ? Nv.jade : Nv.lacquer),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('การอนุมัติด้วย PIN ผู้จัดการ', style: Nv.ui(13.5, weight: FontWeight.w700)),
                    Text(
                      mgrLock == null
                          ? 'ใช้งานได้ปกติ'
                          : 'ล็อกถึง ${hm(mgrLock)} — มีการใส่ PIN ผู้จัดการผิด ${PosStore.maxPinAttempts} ครั้ง (ปลดอัตโนมัติ)',
                      style: Nv.ui(12, color: mgrLock == null ? Nv.ink3 : Nv.lacquer),
                    ),
                  ],
                ),
              ),
              NvBadge(mgrLock == null ? 'ปกติ' : 'ล็อกอยู่', tint: mgrLock == null ? NvTint.jade : NvTint.lacquer),
            ],
          ),
        ],
      ),
    );
  }

  Widget _matrixCard(bool narrow) {
    const shortRole = {
      StaffRole.owner: 'เจ้าของ',
      StaffRole.manager: 'ผจก.',
      StaffRole.cashier: 'แคช.',
      StaffRole.waiter: 'เสิร์ฟ',
      StaffRole.kitchen: 'ครัว',
    };
    // Route rows are evaluated against the real router guard.
    const routeRows = <(String, String)>[
      ('ขายสินค้า / รับชำระ', '/cashier'),
      ('ผังโต๊ะ / สั่งจากมือถือ', '/tablet/floor'),
      ('จอครัว (KDS)', '/display/kitchen'),
      ('บิลย้อนหลัง / พิมพ์ซ้ำ', '/orders'),
      ('กะการขาย / นับเงิน', '/shift'),
      ('คลังสินค้า', '/inventory'),
      ('สมาชิก (CRM)', '/crm'),
      ('ใบกำกับภาษี', '/tax-invoice'),
      ('เมนูและราคา', '/menu-editor'),
      ('ใบสั่งซื้อ / ความเคลื่อนไหวสต็อก', '/po'),
      ('คูปอง / โปรโมชั่น / ระดับสมาชิก', '/coupons'),
      ('รายงาน / บัญชี', '/dashboard'),
      ('พนักงาน / ความปลอดภัย', '/staff'),
      ('ตั้งค่า / เซิร์ฟเวอร์ / สาขา', '/settings'),
    ];
    bool can(StaffRole r, String route) {
      final probe = Staff(id: 'perm-${r.name}', name: r.label, role: r);
      final ok = AppRouter.guardFor(needsSetup: false, me: probe, loc: route) == null;
      return route == '/cashier' ? ok && r.canSell : ok;
    }

    // 2 = allowed · 1 = needs manager PIN · 0 = no
    final rows = <(String, List<int>)>[
      for (final r in routeRows) (r.$1, [for (final role in StaffRole.values) can(role, r.$2) ? 2 : 0]),
      (
        'คืนเงิน / ยกเลิกรายการที่ส่งครัว',
        [for (final role in StaffRole.values) role.isManager ? 2 : (can(role, '/refund') && role.canSell ? 1 : 0)],
      ),
      (
        'ลดสต็อก / นำเงินออกจากลิ้นชัก',
        [for (final role in StaffRole.values) role.isManager ? 2 : (can(role, '/inventory') ? 1 : 0)],
      ),
      ('แก้ไขบัญชีเจ้าของร้าน', [for (final role in StaffRole.values) role == StaffRole.owner ? 2 : (role == StaffRole.manager ? 1 : 0)]),
    ];

    Widget cell(int v) => Center(
          child: switch (v) {
            2 => const Icon(NvIcons.check, size: 13, color: Nv.jade),
            1 => Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(color: Nv.amberTint, borderRadius: BorderRadius.circular(6)),
                child: Text('PIN', style: Nv.ui(10, color: const Color(0xFF8A5A00), weight: FontWeight.w800)),
              ),
            _ => Text('—', style: Nv.ui(12, color: Nv.ink4)),
          },
        );

    return NvSheet(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              NvArt.icon('settings', size: 40),
              const SizedBox(width: 10),
              Expanded(child: Text('ตารางสิทธิ์ตามบทบาท', style: Nv.display(18))),
            ],
          ),
          const SizedBox(height: 4),
          Text('คำนวณจากกฎการเข้าหน้าจอของแอปโดยตรง · PIN = ต้องให้ผู้จัดการอนุมัติ', style: Nv.ui(12, color: Nv.ink3)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
            decoration: BoxDecoration(color: Nv.ivoryDeep.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Expanded(flex: narrow ? 3 : 4, child: Text('สิทธิ์', style: Nv.ui(11.5, color: Nv.ink3, weight: FontWeight.w700))),
                for (final r in StaffRole.values)
                  Expanded(
                    flex: 1,
                    child: Text(narrow ? shortRole[r]! : r.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: Nv.ui(10.5, color: Nv.ink2, weight: FontWeight.w700, height: 1.2)),
                  ),
              ],
            ),
          ),
          for (final row in rows)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Nv.lineSoft))),
              child: Row(
                children: [
                  Expanded(flex: narrow ? 3 : 4, child: Text(row.$1, style: Nv.ui(12.5, color: Nv.ink))),
                  for (final v in row.$2) Expanded(flex: 1, child: cell(v)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _dataCard(PosStore store) {
    final pending = store.sync?.pendingCount ?? 0;
    return NvSheet(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              NvArt.icon('drawer', size: 40),
              const SizedBox(width: 10),
              Expanded(child: Text('ข้อมูลในเครื่อง', style: Nv.display(18))),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'ข้อมูลร้านทั้งหมดเก็บในเครื่องนี้แบบออฟไลน์ (ไฟล์ข้อมูลในโฟลเดอร์ของแอป บันทึกอัตโนมัติทุกครั้งที่มีการเปลี่ยนแปลง '
            'และเก็บสำเนาสำรองฉบับก่อนหน้าไว้เสมอ) · PIN เก็บแบบเข้ารหัสทางเดียว (hash + salt) · คีย์ API ของเซิร์ฟเวอร์เก็บใน secure storage ของระบบปฏิบัติการ',
            style: Nv.ui(12.5, color: Nv.ink2, height: 1.5),
          ),
          if (store.restoredFromBackup) ...[
            const SizedBox(height: 10),
            const NvBadge('เปิดแอปครั้งล่าสุดกู้ข้อมูลจากสำเนาสำรอง — ไฟล์หลักเสียหาย', tint: NvTint.amber, icon: NvIcons.warning),
          ],
          const SizedBox(height: 10),
          NvKeyValue('บิลที่บันทึก', groupDigits(store.orders.length)),
          NvKeyValue('สินค้า', groupDigits(store.products.length)),
          NvKeyValue('สมาชิก', groupDigits(store.customers.length)),
          NvKeyValue('บันทึกการใช้งาน', '${groupDigits(store.auditLog.length)} / 1,500'),
          NvKeyValue('บิลรอส่งขึ้นเซิร์ฟเวอร์', groupDigits(pending), valueColor: pending > 0 ? Nv.amber : null),
          const SizedBox(height: 12),
          NvButton.gold('บันทึกข้อมูลทันที', icon: NvIcons.floppy, expand: true, loading: _saving, onPressed: _flush),
        ],
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  final AuditEntry entry;
  const _AuditRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final g = _groupFor(entry.action);
    final c = nvTint(g.tint);
    final sensitive = entry.action.endsWith('.locked') || entry.action == 'refund' || entry.action == 'ticket.cancel';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Nv.lineSoft))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(g.icon, size: 13, color: c.fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _actionLabel(entry.action),
                        style: Nv.ui(13.5, color: sensitive ? Nv.lacquerDeep : Nv.ink, weight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(thaiDateTime(entry.at), style: Nv.money(11, color: Nv.ink3, weight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: entry.actor, style: Nv.ui(12, color: Nv.ink2, weight: FontWeight.w600)),
                    if (entry.detail.isNotEmpty) TextSpan(text: '  ·  ${entry.detail}', style: Nv.ui(12, color: Nv.ink3)),
                  ]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
