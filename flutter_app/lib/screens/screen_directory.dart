// Thaiprompt POS — Screen directory (/screens · manager dev tool).
//
// Every route registered in app_router.dart (except /setup and /login, which
// the guard only allows when signed out) as a Nova card with its 3D art, Thai
// title and path. Tapping opens it; routes that take a query parameter get the
// latest real record (last bill, last self-order ticket, first product, latest
// delivery) when one exists. Kiosk routes confirm first, since leaving them
// needs the logo long-press + manager PIN.
//
// by xman studio

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routes/app_router.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';

class _Entry {
  final String route;
  final String art;
  final String title;
  final String sub;
  final bool kiosk;
  const _Entry(this.route, this.art, this.title, this.sub, {this.kiosk = false});
}

const _sections = <(String, String, List<_Entry>)>[
  ('เริ่มต้น', 'START', [
    _Entry('/home', 'pos', 'หน้าหลัก', 'ภาพรวมวันนี้และทางลัดทุกโมดูล'),
    _Entry('/screens', 'settings', 'สารบัญหน้าจอ', 'หน้านี้ — รายการทุกเส้นทางในแอป'),
  ]),
  ('ขายหน้าร้าน', 'SELL', [
    _Entry('/cashier', 'pos', 'ขายสินค้า (แคชเชียร์)', 'จอขายหลัก · สแกน · ตะกร้า'),
    _Entry('/m/cashier', 'pos', 'แคชเชียร์มือถือ', 'ขายบนโทรศัพท์'),
    _Entry('/payment', 'payment', 'ชำระเงิน', 'เงินสด · พร้อมเพย์ · บัตร · อีวอลเล็ท'),
    _Entry('/receipt', 'receipt', 'ใบเสร็จ', 'ดู/พิมพ์/แชร์ใบเสร็จ'),
    _Entry('/orders', 'receipt', 'บิลย้อนหลัง', 'ค้นหา · พิมพ์ซ้ำ · คืนเงิน'),
    _Entry('/bill/create', 'payment', 'พักบิล / แยกบิล', 'บิลที่พักไว้และบิลปัจจุบัน'),
    _Entry('/refund', 'refund', 'คืนเงิน', 'คืนทั้งบิลหรือบางรายการ'),
    _Entry('/payment/nfc', 'nfc', 'รับชำระบัตร / EDC', 'บันทึกรหัสอนุมัติจากเครื่องรูดบัตร'),
    _Entry('/tax-invoice', 'tax', 'ใบกำกับภาษี', 'ออกใบกำกับภาษีเต็มรูป'),
    _Entry('/shift', 'shift', 'กะการขาย', 'เปิด–ปิดกะ · นับเงิน · Z-Report'),
  ]),
  ('โต๊ะและครัว', 'DINING', [
    _Entry('/tablet/floor', 'table', 'ผังโต๊ะ', 'เปิดโต๊ะ · สั่ง · เช็คบิล'),
    _Entry('/floor-designer', 'table', 'ออกแบบผังร้าน', 'เพิ่ม/ย้าย/ลบโต๊ะ'),
    _Entry('/display/kitchen', 'kitchen', 'จอครัว (KDS)', 'คิวออเดอร์ตามลำดับ'),
    _Entry('/mobile/order', 'qr', 'สั่งจากมือถือพนักงาน', 'รับออเดอร์ข้างโต๊ะ'),
  ]),
  ('หน้าจอลูกค้า', 'KIOSK', [
    _Entry('/display/customer', 'display', 'จอฝั่งลูกค้า', 'แสดงรายการและยอดชำระ', kiosk: true),
    _Entry('/self-order', 'qr', 'ลูกค้าสั่งเอง', 'แท็บเล็ตประจำโต๊ะ', kiosk: true),
    _Entry('/order-status', 'display', 'สถานะออเดอร์', 'ติดตามคิวของลูกค้า', kiosk: true),
    _Entry('/cust/menu', 'menu', 'เมนูลูกค้า', 'เลือกเมนูแบบกริด', kiosk: true),
    _Entry('/cust/item', 'menu', 'รายละเอียดเมนู', 'ตัวเลือกและจำนวน', kiosk: true),
    _Entry('/cust/cart', 'payment', 'ตะกร้าลูกค้า', 'ตรวจรายการก่อนส่ง', kiosk: true),
    _Entry('/cust/confirm', 'receipt', 'ส่งครัวสำเร็จ', 'หน้ายืนยันคำสั่ง', kiosk: true),
  ]),
  ('สินค้าและสต็อก', 'CATALOG', [
    _Entry('/menu-editor', 'menu', 'เมนูและสินค้า', 'ราคา · หมวด · ตัวเลือก · รูป'),
    _Entry('/inventory', 'inventory', 'คลังสินค้า', 'รับเข้า · ปรับยอด · ตรวจนับ'),
    _Entry('/stock', 'inventory', 'ความเคลื่อนไหวสต็อก', 'ประวัติเข้า–ออกทุกรายการ'),
    _Entry('/po', 'po', 'ใบสั่งซื้อ (PO)', 'ซัพพลายเออร์ · รับของเข้าสต็อก'),
    _Entry('/barcode', 'barcode', 'บาร์โค้ดและฉลาก', 'พิมพ์สติกเกอร์สินค้า'),
  ]),
  ('ลูกค้าและโปรโมชั่น', 'LOYALTY', [
    _Entry('/crm', 'member', 'สมาชิก', 'ค้นหา · แต้ม · ประวัติ'),
    _Entry('/tiers', 'tiers', 'ระดับสมาชิก', 'ส่วนลดและแต้มตามระดับ'),
    _Entry('/coupons', 'coupon', 'คูปอง', 'สร้างและจัดการรหัสส่วนลด'),
    _Entry('/discount-center', 'discount', 'โปรโมชั่นอัตโนมัติ', 'ลดตามยอด · หมวด · ช่วงเวลา'),
    _Entry('/affiliate', 'affiliate', 'แนะนำเพื่อน', 'ลิงก์ Thai Prompt ของร้าน'),
  ]),
  ('จัดส่ง', 'DELIVERY', [
    _Entry('/delivery', 'delivery', 'งานจัดส่ง', 'ติดตามสถานะไรเดอร์'),
    _Entry('/shipping/providers', 'shipping', 'ผู้ให้บริการขนส่ง', 'ค่าส่ง · บัญชีร้าน'),
    _Entry('/shipping/labels', 'shipping', 'ใบปะหน้าพัสดุ', 'พิมพ์ฉลากพร้อมบาร์โค้ด'),
  ]),
  ('รายงานและผู้ดูแล', 'ADMIN', [
    _Entry('/dashboard', 'dashboard', 'แดชบอร์ด', 'ยอดขาย · ชั่วโมงทอง · สินค้าขายดี'),
    _Entry('/mobile/manager', 'dashboard', 'สรุปผู้จัดการ', 'ภาพรวมแบบมือถือ'),
    _Entry('/accounting', 'accounting', 'บัญชี', 'กำไรขาดทุน · ภาษีขาย · สมุดรายวัน'),
    _Entry('/hq', 'branch', 'หลายสาขา', 'ข้อมูลสาขาของร้าน'),
    _Entry('/staff', 'staff', 'พนักงาน', 'บทบาท · PIN · ลงเวลา'),
    _Entry('/admin', 'shield', 'ความปลอดภัย', 'บันทึกการใช้งาน · สิทธิ์'),
    _Entry('/settings', 'settings', 'ตั้งค่า', 'ร้าน · ใบเสร็จ · เครื่องพิมพ์ · เซิร์ฟเวอร์'),
  ]),
];

/// The real route to open, with the latest matching record as its parameter.
String _target(PosStore store, String route) {
  String q(String k, String v) => '$route?$k=${Uri.encodeQueryComponent(v)}';
  switch (route) {
    case '/receipt':
    case '/tax-invoice':
      final o = store.lastOrder;
      return o == null ? route : q('id', o.id);
    case '/cust/item':
      return store.products.isEmpty ? route : q('code', store.products.first.code);
    case '/order-status':
      final t = store.lastSelfTicket;
      return t == null ? route : q('ticket', t.id);
    case '/shipping/labels':
      return store.deliveries.isEmpty ? route : q('id', store.deliveries.first.id);
    default:
      return route;
  }
}

class ScreenDirectory extends StatefulWidget {
  const ScreenDirectory({super.key});

  @override
  State<ScreenDirectory> createState() => _ScreenDirectoryState();
}

class _ScreenDirectoryState extends State<ScreenDirectory> {
  String _query = '';

  Future<void> _open(_Entry e) async {
    final store = AppScope.read(context);
    final target = _target(store, e.route);
    if (e.kiosk) {
      final ok = await showNvConfirm(
        context,
        title: 'เปิด "${e.title}" ในโหมดหน้าจอลูกค้า?',
        message: 'หน้าจอนี้ไม่มีเมนูพนักงาน — ออกโดยกดโลโก้มุมซ้ายบนค้าง 1.5 วินาทีแล้วใส่ PIN ผู้จัดการ',
        confirmLabel: 'เปิดหน้าจอ',
        danger: false,
        art: e.art,
      );
      if (!ok || !mounted) return;
    }
    context.go(target);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final q = _query.trim().toLowerCase();
    final total = _sections.fold<int>(0, (s, sec) => s + sec.$3.length);
    final filtered = [
      for (final sec in _sections)
        (
          sec.$1,
          sec.$2,
          sec.$3
              .where((e) => q.isEmpty || e.title.toLowerCase().contains(q) || e.route.contains(q) || e.sub.toLowerCase().contains(q))
              .toList(),
        ),
    ].where((s) => s.$3.isNotEmpty).toList();

    return NvScaffold(
      title: 'สารบัญหน้าจอ',
      eyebrow: 'เครื่องมือผู้จัดการ',
      subtitle: 'ทุกเส้นทางในแอป · $total หน้าจอ',
      art: 'settings',
      body: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        final cols = w > 1250 ? 4 : (w > 900 ? 3 : (w > 560 ? 2 : 1));
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: w < 560 ? w : 360,
                  child: NvSearchField(hint: 'ค้นหาชื่อหน้าจอหรือเส้นทาง เช่น /shift', onChanged: (v) => setState(() => _query = v)),
                ),
                Text('ไม่รวม /setup และ /login (เปิดได้เฉพาะตอนยังไม่เข้าระบบ)', style: Nv.ui(12, color: Nv.ink3)),
              ],
            ),
            const SizedBox(height: 18),
            if (filtered.isEmpty)
              NvSheet(
                child: NvEmptyState(
                  mascot: 'search',
                  title: 'ไม่พบหน้าจอ',
                  message: 'ไม่มีหน้าจอที่ตรงกับ "$_query"',
                ),
              ),
            for (final sec in filtered)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 10),
                      child: Row(
                        children: [
                          Text(sec.$2, style: Nv.eyebrowLatin()),
                          const SizedBox(width: 10),
                          Flexible(child: Text(sec.$1, style: Nv.display(18))),
                          const SizedBox(width: 8),
                          Text('${sec.$3.length}', style: Nv.money(12, color: Nv.ink3, weight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    GridView(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 124,
                      ),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [for (final e in sec.$3) _EntryCard(entry: e, target: _target(store, e.route), onTap: () => _open(e))],
                    ),
                  ],
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final _Entry entry;
  final String target;
  final VoidCallback onTap;
  const _EntryCard({required this.entry, required this.target, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final manager = kManagerRoutes.contains(e.route);
    final kitchen = kKitchenRoutes.contains(e.route);
    return NvSheet(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      onTap: onTap,
      child: Row(
        children: [
          NvArt.icon(e.art, size: 54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(15, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(target, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.money(11.5, color: Nv.goldInk, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(e.sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(11.5, color: Nv.ink3)),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: [
                    if (manager) const NvBadge('ผู้จัดการ', tint: NvTint.navy, dot: false),
                    if (kitchen) const NvBadge('ครัวเข้าได้', tint: NvTint.amber, dot: false),
                    if (e.kiosk) const NvBadge('จอลูกค้า', tint: NvTint.sapphire, dot: false),
                  ],
                ),
              ],
            ),
          ),
          const Icon(NvIcons.angleRight, size: 14, color: Nv.ink4),
        ],
      ),
    );
  }
}
