// Thaiprompt POS — แคชเชียร์มือถือ (/m/cashier).
//
// Payment-first phone cashier on the live store: order type (ทานที่นี่ /
// กลับบ้าน / เดลิเวอรี่) with table + guests for dine-in, a "เมนู" tab (the
// shared search / category / product list with options) and a "บิล" tab
// (lines with steppers / notes / remove, member link by phone — or sign up a
// new member on the spot, coupon code, every discount + VAT, hold / clear).
// The gold "ชำระเงิน ฿x" bar is always at hand and goes to /payment when
// checkout is allowed (otherwise it says why, with a shortcut to open the
// shift). Nothing here is hard-coded — items, cart, coupons, members all come
// from the store.
//
// by xman studio

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/catalog_models.dart' show stableHue;
import '../models/extra_models.dart';
import '../models/order_models.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';
import 'mobile_order_screen.dart' show MobileCatalog, MobileTableBar, MobileCartLineTile, MobileTotals, mobileGoToPayment;

enum _View { menu, bill }

class CashierMobileScreen extends StatefulWidget {
  const CashierMobileScreen({super.key});

  @override
  State<CashierMobileScreen> createState() => _CashierMobileScreenState();
}

class _CashierMobileScreenState extends State<CashierMobileScreen> {
  _View _view = _View.menu;
  final TextEditingController _coupon = TextEditingController();

  @override
  void dispose() {
    _coupon.dispose();
    super.dispose();
  }

  // ── actions ──

  void _setOrderType(OrderType t) {
    final store = AppScope.read(context);
    if (t == store.orderType) return;
    // a loaded table bill must stay dine-in or its table would never be freed
    if (store.activeTicketIds.isNotEmpty && t != OrderType.dineIn) {
      nvToast(context, 'บิลโต๊ะที่ส่งครัวแล้วต้องเป็น "ทานที่นี่"', kind: NvToastKind.warning);
      return;
    }
    store.setOrderType(t);
  }

  void _applyCoupon() {
    final store = AppScope.read(context);
    final code = _coupon.text.trim();
    if (code.isEmpty) {
      nvToast(context, 'กรุณาใส่รหัสคูปอง', kind: NvToastKind.warning);
      return;
    }
    if (store.cart.isEmpty) {
      nvToast(context, 'เพิ่มรายการก่อนใช้คูปอง', kind: NvToastKind.warning);
      return;
    }
    final err = store.tryApplyCoupon(code);
    if (err != null) {
      nvToast(context, err, kind: NvToastKind.error);
      return;
    }
    _coupon.clear();
    FocusScope.of(context).unfocus();
    nvToast(context, 'ใช้คูปอง ${store.appliedCouponCode ?? code.toUpperCase()} แล้ว · ลด ${baht(store.couponDiscount)}',
        kind: NvToastKind.success);
  }

  Future<void> _pickMember() async {
    final c = await showNvDialog<Customer>(
      context,
      title: 'ผูกสมาชิก',
      subtitle: 'ค้นหาด้วยเบอร์โทรเพื่อรับส่วนลดและสะสมแต้ม',
      art: 'member',
      maxWidth: 460,
      body: const _MemberSearch(),
      actions: (ctx) => [NvButton.soft('ยกเลิก', onPressed: () => Navigator.of(ctx).pop())],
    );
    if (c == null || !mounted) return;
    AppScope.read(context).linkCustomer(c);
    nvToast(context, 'ผูกสมาชิก ${c.name} แล้ว', kind: NvToastKind.success);
  }

  void _hold() {
    final store = AppScope.read(context);
    final h = store.holdCart();
    if (h == null) return;
    final router = GoRouter.of(context);
    setState(() => _view = _View.menu);
    nvToast(context, 'พักบิล "${h.label}" แล้ว',
        kind: NvToastKind.success, actionLabel: 'ดูบิลพัก', onAction: () => router.go('/bill/create'));
  }

  Future<void> _clear() async {
    final store = AppScope.read(context);
    final sent = store.activeTicketIds.isNotEmpty;
    final ok = await showNvConfirm(
      context,
      title: 'ล้างบิลนี้?',
      message: sent
          ? 'นำบิลโต๊ะ ${store.tableNumber ?? ''} ออกจากเครื่องนี้ — ออเดอร์ที่ส่งครัวแล้วยังค้างอยู่ครบ ชำระภายหลังได้'
          : 'รายการ ${store.cartItemCount} รายการ คูปอง และสมาชิกที่ผูกไว้จะถูกล้าง',
      confirmLabel: 'ล้างบิล',
    );
    if (!ok || !mounted) return;
    store.clearCart();
    setState(() => _view = _View.menu);
  }

  // ── build ──

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final count = store.cartItemCount;
    return NvScaffold(
      title: 'แคชเชียร์มือถือ',
      art: 'pos',
      subtitle: 'ขายและรับชำระเงินจากมือถือ',
      actions: [
        NvIconButton(
          NvIcons.pause,
          tooltip: 'บิลที่พักไว้',
          badge: store.heldCarts.length,
          onPressed: () => context.go('/bill/create'),
        ),
      ],
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  NvSegmented<OrderType>(
                    options: [for (final t in OrderType.values) (t, t.label)],
                    value: store.orderType,
                    onChanged: _setOrderType,
                  ),
                  NvSegmented<_View>(
                    options: [(_View.menu, 'เมนู'), (_View.bill, count > 0 ? 'บิล · $count' : 'บิล')],
                    value: _view,
                    onChanged: (v) => setState(() => _view = v),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (store.orderType == OrderType.dineIn) ...[const MobileTableBar(), const SizedBox(height: 10)],
              Expanded(child: _view == _View.menu ? const MobileCatalog() : _bill(store)),
              const SizedBox(height: 10),
              _payBar(store),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bill(PosStore store) {
    if (store.cart.isEmpty) {
      return NvEmptyState(
        mascot: 'empty',
        size: 130,
        title: 'ยังไม่มีรายการในบิล',
        message: store.heldCarts.isEmpty
            ? 'เลือกเมนูจากแท็บ "เมนู" เพื่อเริ่มขาย'
            : 'มีบิลพักไว้ ${store.heldCarts.length} บิล — เปิดต่อได้จากปุ่มบิลพักด้านบน',
        actionLabel: 'ไปเลือกเมนู',
        actionIcon: NvIcons.menuBook,
        onAction: () => setState(() => _view = _View.menu),
      );
    }
    final sent = store.activeTicketIds.isNotEmpty;
    final lines = store.cart;
    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        if (sent)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Nv.amberTint,
              borderRadius: BorderRadius.circular(Nv.rMd),
              border: Border.all(color: Nv.amber.withValues(alpha: 0.5)),
            ),
            child: Text(
              'บิลโต๊ะ ${store.tableNumber ?? ''} ที่ส่งครัวแล้ว — ชำระเงินได้เลย (ลด/ลบรายการต้องให้ผู้จัดการอนุมัติ)',
              style: Nv.ui(12.5, color: const Color(0xFF8A5A00), weight: FontWeight.w600),
            ),
          ),
        NvSheet(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
          child: Column(
            children: [
              for (var i = 0; i < lines.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                MobileCartLineTile(lines[i], key: ObjectKey(lines[i])),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _memberCard(store),
        const SizedBox(height: 12),
        _couponCard(store),
        const SizedBox(height: 12),
        NvSheet(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MobileTotals(),
              if (store.discountNote.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(store.discountNote, style: Nv.ui(12, color: Nv.jade, weight: FontWeight.w600)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: NvButton.soft('พักบิล', icon: NvIcons.pause, expand: true, onPressed: sent ? null : _hold),
            ),
            const SizedBox(width: 10),
            Expanded(child: NvButton.soft('ล้างบิล', icon: NvIcons.trash, expand: true, onPressed: _clear)),
          ],
        ),
      ],
    );
  }

  Widget _memberCard(PosStore store) {
    final c = store.linkedCustomer;
    if (c == null) {
      return NvSheet(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: Nv.gold100, borderRadius: BorderRadius.circular(12)),
              child: const Icon(NvIcons.idCard, size: 17, color: Nv.goldInk),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ยังไม่ผูกสมาชิก', style: Nv.ui(14.5, weight: FontWeight.w700)),
                  Text('ผูกเบอร์สมาชิกเพื่อรับส่วนลดและแต้ม', style: Nv.ui(12, color: Nv.ink3)),
                ],
              ),
            ),
            NvButton.ghost('ผูกสมาชิก', icon: NvIcons.userPlus, size: NvButtonSize.sm, onPressed: _pickMember),
          ],
        ),
      );
    }
    final tier = store.tierFor(c);
    return NvSheet(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      goldEdge: true,
      child: Row(
        children: [
          NvAvatar(c.initials, hue: stableHue(c.id), size: 42, ring: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(14.5, weight: FontWeight.w700)),
                Text(
                  '${c.phone.isEmpty ? 'ไม่มีเบอร์' : phoneFmt(c.phone)} · ${tier.name} · ${groupDigits(c.points)} แต้ม',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Nv.ui(12, color: Nv.ink3),
                ),
                if (tier.discountPercent > 0)
                  Text('ส่วนลดสมาชิก ${tier.discountPercent}%', style: Nv.ui(12, color: Nv.jade, weight: FontWeight.w600)),
              ],
            ),
          ),
          NvIconButton(NvIcons.rightLeft, size: 36, tooltip: 'เปลี่ยนสมาชิก', onPressed: _pickMember),
          const SizedBox(width: 6),
          NvIconButton(
            NvIcons.xmark,
            size: 36,
            tooltip: 'ยกเลิกการผูกสมาชิก',
            onPressed: () => AppScope.read(context).linkCustomer(null),
          ),
        ],
      ),
    );
  }

  Widget _couponCard(PosStore store) {
    final code = store.appliedCouponCode;
    if (code != null) {
      final def = store.couponByCode(code);
      final why = def == null ? 'ไม่พบคูปองนี้แล้ว' : def.blockReason(store.cartSubtotal, DateTime.now());
      final active = store.couponDiscount > 0;
      return NvSheet(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Icon(NvIcons.coupon, size: 17, color: active ? Nv.jade : Nv.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('คูปอง $code', style: Nv.ui(14.5, weight: FontWeight.w700)),
                  Text(
                    active ? 'ลด ${baht(store.couponDiscount)}${def == null ? '' : ' · ${def.name}'}' : (why.isEmpty ? 'ยังใช้กับยอดนี้ไม่ได้' : why),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Nv.ui(12, color: active ? Nv.jade : const Color(0xFF8A5A00), weight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            NvButton.soft('นำออก', icon: NvIcons.xmark, size: NvButtonSize.sm, onPressed: () => AppScope.read(context).removeCoupon()),
          ],
        ),
      );
    }
    return NvSheet(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _coupon,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _applyCoupon(),
              decoration: const InputDecoration(hintText: 'รหัสคูปอง', prefixIcon: Icon(NvIcons.coupon, size: 15)),
            ),
          ),
          const SizedBox(width: 10),
          NvButton.gold('ใช้คูปอง', size: NvButtonSize.sm, onPressed: _applyCoupon),
        ],
      ),
    );
  }

  Widget _payBar(PosStore store) {
    final empty = store.cart.isEmpty;
    final block = empty ? '' : store.checkoutBlockReason;
    final needShift = block.isNotEmpty && store.requireShift && !store.hasOpenShift;
    final where = store.orderType == OrderType.dineIn && store.tableNumber != null ? 'โต๊ะ ${store.tableNumber}' : store.orderType.label;
    final who = store.linkedCustomer?.name;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (block.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(Nv.rSm),
                onTap: needShift ? () => context.go('/shift') : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: Nv.amberTint,
                    borderRadius: BorderRadius.circular(Nv.rSm),
                    border: Border.all(color: Nv.amber.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(NvIcons.warning, size: 13, color: Nv.amber),
                      const SizedBox(width: 8),
                      Expanded(child: Text(block, style: Nv.ui(12.5, color: const Color(0xFF8A5A00), weight: FontWeight.w600))),
                      if (needShift) Text('เปิดกะ ›', style: Nv.ui(12.5, color: Nv.goldInk, weight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        NvNightCard(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      empty ? 'ยังไม่มีรายการ' : '${store.cartItemCount} รายการ · $where${who == null ? '' : ' · $who'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Nv.ui(13, color: Nv.onNight, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    if (store.cartDiscount > 0)
                      Text('ส่วนลด ${baht(store.cartDiscount)}', style: Nv.ui(12, color: Nv.jadeLight, weight: FontWeight.w600))
                    else
                      Text(store.vatEnabled ? 'รวมภาษีมูลค่าเพิ่มแล้ว' : 'ไม่คิดภาษีมูลค่าเพิ่ม', style: Nv.ui(11.5, color: Nv.onNight3)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              NvButton.gold(
                'ชำระเงิน ${baht(store.cartTotal)}',
                icon: NvIcons.moneyBill,
                size: NvButtonSize.lg,
                onPressed: empty ? null : () => mobileGoToPayment(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── member search ─────────────────────────

class _MemberSearch extends StatefulWidget {
  const _MemberSearch();

  @override
  State<_MemberSearch> createState() => _MemberSearchState();
}

class _MemberSearchState extends State<_MemberSearch> {
  final TextEditingController _q = TextEditingController();
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    _name.dispose();
    super.dispose();
  }

  void _create(String phone) {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final store = AppScope.read(context);
    if (store.customerByPhone(phone) != null) {
      nvToast(context, 'เบอร์นี้เป็นสมาชิกอยู่แล้ว', kind: NvToastKind.warning);
      return;
    }
    final c = store.addCustomer(name, phone: phone);
    Navigator.of(context).pop(c);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final q = _q.text.trim();
    final digits = q.replaceAll(RegExp(r'\D'), '');
    final results = q.isEmpty ? store.customers.take(8).toList() : store.searchCustomers(q).take(20).toList();
    final canCreate = q.isNotEmpty && results.isEmpty && digits.length >= 9 && digits.length <= 10 && digits.length == q.replaceAll(RegExp(r'[\s-]'), '').length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _q,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'เบอร์โทร หรือชื่อสมาชิก',
            prefixIcon: Icon(NvIcons.search, size: 15),
          ),
        ),
        const SizedBox(height: 12),
        if (q.isEmpty && results.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('สมาชิกล่าสุด', style: Nv.ui(12, color: Nv.ink3, weight: FontWeight.w600)),
          ),
        if (results.isEmpty && !canCreate)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              q.isEmpty ? 'ยังไม่มีสมาชิกในระบบ — พิมพ์เบอร์โทรเพื่อสมัครใหม่' : 'ไม่พบสมาชิกที่ตรงกับ "$q"',
              textAlign: TextAlign.center,
              style: Nv.ui(13.5, color: Nv.ink3),
            ),
          ),
        for (final c in results)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: NvSheet(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              radius: Nv.rMd,
              color: Nv.paper,
              onTap: () => Navigator.of(context).pop(c),
              child: Row(
                children: [
                  NvAvatar(c.initials, hue: stableHue(c.id), size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(14, weight: FontWeight.w700)),
                        Text(
                          '${c.phone.isEmpty ? 'ไม่มีเบอร์' : phoneFmt(c.phone)} · ${store.tierFor(c).name} · ${groupDigits(c.points)} แต้ม',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Nv.ui(12, color: Nv.ink3),
                        ),
                      ],
                    ),
                  ),
                  const Icon(NvIcons.angleRight, size: 14, color: Nv.ink3),
                ],
              ),
            ),
          ),
        if (canCreate) ...[
          Text('ยังไม่มีเบอร์ ${phoneFmt(digits)} — สมัครสมาชิกใหม่', style: Nv.ui(14, weight: FontWeight.w700)),
          const SizedBox(height: 10),
          NvField(
            label: 'ชื่อสมาชิก',
            controller: _name,
            icon: NvIcons.user,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _create(digits),
          ),
          const SizedBox(height: 10),
          NvButton.gold(
            'สมัครและผูกสมาชิก',
            icon: NvIcons.userPlus,
            expand: true,
            onPressed: _name.text.trim().isEmpty ? null : () => _create(digits),
          ),
        ],
      ],
    );
  }
}
