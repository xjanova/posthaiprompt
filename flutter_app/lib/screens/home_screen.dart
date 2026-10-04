// Thaiprompt POS — Home launcher (replaces the old dev overview).
//
// A night hero with น้องพร้อม and today's live numbers, then every module as a
// 3D Nova icon card grouped like the website's service grid. Cards are
// filtered by the signed-in role and carry live badges (kitchen queue, low
// stock, open tables, waiter calls).
//
// by xman studio

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/extra_models.dart';
import '../routes/app_router.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';

class _Module {
  final String route;
  final String art;
  final String title;
  final String sub;
  final int Function(PosStore s)? badge;
  const _Module(this.route, this.art, this.title, this.sub, [this.badge]);
}

const _groups = <(String, String, List<_Module>)>[
  ('ขายหน้าร้าน', 'POINT OF SALE', [
    _Module('/cashier', 'pos', 'ขายสินค้า', 'แคชเชียร์ · สแกน · ชำระเงิน'),
    _Module('/orders', 'receipt', 'บิลย้อนหลัง', 'พิมพ์ซ้ำ · คืนเงิน · ใบกำกับ'),
    _Module('/bill/create', 'payment', 'พักบิล / แยกบิล', 'บิลที่พักไว้และบิลปัจจุบัน', _held),
    _Module('/shift', 'shift', 'กะการขาย', 'เปิด–ปิดกะ · นับเงิน · Z-Report'),
    _Module('/refund', 'refund', 'คืนเงิน', 'คืนทั้งบิลหรือบางรายการ'),
    _Module('/payment/nfc', 'nfc', 'รับชำระบัตร/EDC', 'บันทึกรหัสอนุมัติจากเครื่อง'),
  ]),
  ('โต๊ะและครัว', 'DINING', [
    _Module('/tablet/floor', 'table', 'ผังโต๊ะ', 'เปิดโต๊ะ · สั่ง · เช็คบิล', _tables),
    _Module('/display/kitchen', 'kitchen', 'จอครัว (KDS)', 'คิวออเดอร์ตามลำดับ', _kitchen),
    _Module('/mobile/order', 'qr', 'สั่งจากมือถือพนักงาน', 'รับออเดอร์ข้างโต๊ะ'),
    _Module('/self-order', 'qr', 'ลูกค้าสั่งเอง', 'โหมดแท็บเล็ตประจำโต๊ะ'),
    _Module('/display/customer', 'display', 'จอฝั่งลูกค้า', 'แสดงรายการและยอดชำระ'),
    _Module('/floor-designer', 'table', 'ออกแบบผังร้าน', 'เพิ่ม/ย้าย/ลบโต๊ะ'),
  ]),
  ('สินค้าและสต็อก', 'CATALOG', [
    _Module('/menu-editor', 'menu', 'เมนูและสินค้า', 'ราคา · หมวด · ตัวเลือก · รูป'),
    _Module('/inventory', 'inventory', 'คลังสินค้า', 'รับเข้า · ปรับยอด · ตรวจนับ', _lowStock),
    _Module('/stock', 'inventory', 'ความเคลื่อนไหวสต็อก', 'ประวัติเข้า–ออกทุกรายการ'),
    _Module('/po', 'po', 'ใบสั่งซื้อ (PO)', 'ซัพพลายเออร์ · รับของเข้าสต็อก'),
    _Module('/barcode', 'barcode', 'บาร์โค้ดและฉลาก', 'พิมพ์สติกเกอร์สินค้า'),
  ]),
  ('ลูกค้าและโปรโมชั่น', 'LOYALTY', [
    _Module('/crm', 'member', 'สมาชิก', 'ค้นหา · แต้ม · ประวัติ'),
    _Module('/tiers', 'tiers', 'ระดับสมาชิก', 'ส่วนลดและแต้มตามระดับ'),
    _Module('/coupons', 'coupon', 'คูปอง', 'สร้างและจัดการรหัสส่วนลด'),
    _Module('/discount-center', 'discount', 'โปรโมชั่นอัตโนมัติ', 'ลดตามยอด · หมวด · ช่วงเวลา'),
    _Module('/affiliate', 'affiliate', 'แนะนำเพื่อน', 'ลิงก์ Thai Prompt ของร้าน'),
  ]),
  ('จัดส่ง', 'DELIVERY', [
    _Module('/delivery', 'delivery', 'งานจัดส่ง', 'ติดตามสถานะไรเดอร์', _deliveries),
    _Module('/shipping/labels', 'shipping', 'ใบปะหน้าพัสดุ', 'พิมพ์ฉลากพร้อมบาร์โค้ด'),
    _Module('/shipping/providers', 'shipping', 'ผู้ให้บริการขนส่ง', 'ค่าส่ง · บัญชีร้าน'),
  ]),
  ('การเงินและรายงาน', 'INSIGHTS', [
    _Module('/dashboard', 'dashboard', 'แดชบอร์ด', 'ยอดขาย · สินค้าขายดี · ชั่วโมงทอง'),
    _Module('/accounting', 'accounting', 'บัญชี', 'กำไรขาดทุน · ภาษีขาย'),
    _Module('/tax-invoice', 'tax', 'ใบกำกับภาษี', 'ออกใบกำกับเต็มรูป'),
    _Module('/mobile/manager', 'dashboard', 'สรุปผู้จัดการ', 'ภาพรวมแบบมือถือ'),
    _Module('/hq', 'branch', 'หลายสาขา', 'ข้อมูลสาขาของร้าน'),
  ]),
  ('ระบบ', 'SYSTEM', [
    _Module('/staff', 'staff', 'พนักงาน', 'บทบาท · PIN · ลงเวลา'),
    _Module('/admin', 'shield', 'ความปลอดภัย', 'บันทึกการใช้งาน · สิทธิ์'),
    _Module('/settings', 'settings', 'ตั้งค่า', 'ร้าน · ใบเสร็จ · เครื่องพิมพ์ · เซิร์ฟเวอร์'),
  ]),
];

int _held(PosStore s) => s.heldCarts.length;
int _tables(PosStore s) => s.tablesCallingWaiter.length;
int _kitchen(PosStore s) => s.kitchenQueueCount;
int _lowStock(PosStore s) => s.lowStockProducts.length;
int _deliveries(PosStore s) => s.deliveries.where((d) => d.status.index < 3).length;

bool _allowed(String route, Staff? me) => me != null && AppRouter.guardFor(needsSetup: false, me: me, loc: route) == null;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greet() {
    final h = DateTime.now().hour;
    if (h < 11) return 'อรุณสวัสดิ์';
    if (h < 16) return 'สวัสดีตอนบ่าย';
    return 'สวัสดีตอนเย็น';
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final me = store.currentStaff;
    return NvScaffold(
      title: '${_greet()}, ${me?.name ?? ''}',
      eyebrow: '${store.shopName} · ${store.branch}',
      body: LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth > 1250 ? 4 : (c.maxWidth > 900 ? 3 : (c.maxWidth > 560 ? 2 : 1));
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _Hero(store: store, compact: c.maxWidth < 900),
            const SizedBox(height: 22),
            for (final g in _groups) ...[
              Builder(builder: (context) {
                final mods = g.$3.where((m) => _allowed(m.route, me)).toList();
                if (mods.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 10),
                        child: Row(
                          children: [
                            Text(g.$2, style: Nv.eyebrowLatin()),
                            const SizedBox(width: 10),
                            Text(g.$1, style: Nv.display(18)),
                          ],
                        ),
                      ),
                      GridView.count(
                        crossAxisCount: cols,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: cols == 1 ? 4.2 : 2.55,
                        children: [for (final m in mods) _ModuleCard(m: m, badge: m.badge?.call(store) ?? 0)],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        );
      }),
    );
  }
}

class _ModuleCard extends StatefulWidget {
  final _Module m;
  final int badge;
  const _ModuleCard({required this.m, this.badge = 0});

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.m;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedSlide(
        duration: Nv.fast,
        offset: _hover ? const Offset(0, -0.02) : Offset.zero,
        child: NvSheet(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          selected: _hover,
          onTap: () => context.go(m.route),
          child: Row(
            children: [
              AnimatedScale(duration: Nv.med, curve: Nv.ease, scale: _hover ? 1.08 : 1, child: NvArt.icon(m.art, size: 64)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(m.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(15.5, weight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(m.sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.ui(12, color: Nv.ink3, height: 1.3)),
                  ],
                ),
              ),
              if (widget.badge > 0) NvBadge('${widget.badge}', tint: NvTint.lacquer, dot: false),
              const SizedBox(width: 4),
              Icon(NvIcons.angleRight, size: 14, color: _hover ? Nv.goldInk : Nv.ink4),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final PosStore store;
  final bool compact;
  const _Hero({required this.store, required this.compact});

  @override
  Widget build(BuildContext context) {
    final me = store.currentStaff;
    final canSell = me?.role.canSell ?? false;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Nv.rXl),
      child: Container(
        constraints: const BoxConstraints(minHeight: 210),
        decoration: BoxDecoration(
          gradient: Nv.night,
          borderRadius: BorderRadius.circular(Nv.rXl),
          border: Border.all(color: Nv.lineNightStrong),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.35,
                child: Image.asset(NvAssets.art('hero-temple'), fit: BoxFit.cover, alignment: Alignment.bottomCenter,
                    errorBuilder: (_, _, _) => const SizedBox()),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Nv.navy950.withValues(alpha: 0.85), Nv.navy900.withValues(alpha: 0.2)]),
                ),
              ),
            ),
            const NvKanokCorners(size: 70, opacity: 0.6, inset: EdgeInsets.all(4), bottom: false),
            if (!compact) Positioned(right: 24, bottom: 0, child: NvArt.mascot('present_tab', height: 205)),
            Padding(
              padding: EdgeInsets.fromLTRB(26, 22, compact ? 22 : 230, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ภาพรวมวันนี้', style: Nv.eyebrow(color: Nv.gold300)),
                  const SizedBox(height: 4),
                  NvFoilText(baht(store.todaySales), style: Nv.money(40)),
                  Text('ยอดขายสุทธิ · ${thaiDateFull(DateTime.now())}', style: Nv.ui(13, color: Nv.onNight3)),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 22,
                    runSpacing: 10,
                    children: [
                      _mini('บิล', '${store.todayOrderCount}'),
                      _mini('เฉลี่ย/บิล', baht(store.avgBasket)),
                      _mini('คิวครัว', '${store.kitchenQueueCount}'),
                      _mini('โต๊ะเปิด', '${store.tables.where((t) => t.status != TableStatus.free).length}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (canSell) NvButton.gold('เริ่มขาย', icon: NvIcons.cashier, onPressed: () => context.go('/cashier')),
                      if (canSell && me!.role != StaffRole.waiter)
                        NvButton.ghost(store.hasOpenShift ? 'จัดการกะ' : 'เปิดกะ', icon: NvIcons.clock, onNight: true, onPressed: () => context.go('/shift')),
                      if (me?.role == StaffRole.kitchen || (me?.role.isManager ?? false))
                        NvButton.ghost('จอครัว', icon: NvIcons.fire, onNight: true, onPressed: () => context.go('/display/kitchen')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mini(String k, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(v, style: Nv.money(19, color: Nv.onNight)),
          Text(k, style: Nv.ui(11.5, color: Nv.onNight3)),
        ],
      );
}
