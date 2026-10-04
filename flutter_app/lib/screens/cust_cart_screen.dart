// Thaiprompt POS — Customer cart (/cust/cart) · self-order kiosk.
//
// Shows the store's SELF cart (never the counter cart): picture, options and
// note, a big qty stepper (stock-checked), remove with confirmation, a note
// to the kitchen and the number of guests. Lines that went out of stock since
// they were added are flagged and block sending. "ยืนยันสั่งอาหาร" asks once,
// then submitSelfOrder() turns the cart into an unpaid kitchen ticket and the
// customer lands on /cust/confirm?ticket=… (payment happens at the counter).
//
// by xman studio

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/order_models.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';
import 'cust_menu_screen.dart';

class CustCartScreen extends StatefulWidget {
  const CustCartScreen({super.key});

  @override
  State<CustCartScreen> createState() => _CustCartScreenState();
}

class _CustCartScreenState extends State<CustCartScreen> {
  final _note = TextEditingController();
  int? _guests;
  bool _submitting = false;
  bool _asking = false; // confirm dialog open — ignore repeat taps

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// Guests default to the party already seated at the table, else 1.
  int _guestsFor(PosStore store) {
    final g = _guests;
    if (g != null) return g;
    final t = store.selfTable == null ? null : store.tableByNumber(store.selfTable!);
    return (t != null && t.guests > 0) ? t.guests.clamp(1, 30) : 1;
  }

  /// Why [l] can't be sent right now (null = fine). Checks the LIVE product,
  /// since staff may have 86'd it or stock ran out after it was added.
  String? _problem(PosStore store, CartLine l) {
    final p = store.productByCode(l.product.code);
    if (p == null) return 'เมนูนี้ถูกนำออกแล้ว';
    if (!p.canSell) return 'หมดแล้ว';
    final want = custQtyInSelfCart(store, p.code);
    if (p.trackStock && want > p.stock) return 'เหลือเพียง ${p.stock}';
    return null;
  }

  void _inc(CartLine l) {
    final store = AppScope.read(context);
    final p = store.productByCode(l.product.code) ?? l.product;
    final want = custQtyInSelfCart(store, p.code) + 1;
    if (!p.canSell || (p.trackStock && want > p.stock)) {
      nvToast(context, 'ขออภัย “${p.name}” มีไม่พอแล้ว', kind: NvToastKind.warning);
      return;
    }
    store.selfInc(l);
  }

  Future<void> _dec(CartLine l) async {
    if (l.qty <= 1) {
      await _remove(l);
      return;
    }
    AppScope.read(context).selfDec(l);
  }

  Future<void> _remove(CartLine l) async {
    final ok = await showNvConfirm(
      context,
      title: 'นำรายการออก?',
      message: 'นำ “${l.product.name}” ออกจากตะกร้า',
      confirmLabel: 'นำออก',
    );
    if (!ok || !mounted) return;
    final store = AppScope.read(context);
    if (store.selfCart.contains(l)) store.selfRemove(l);
  }

  Future<void> _clearAll() async {
    final ok = await showNvConfirm(
      context,
      title: 'ล้างตะกร้าทั้งหมด?',
      message: 'รายการทั้งหมดในตะกร้าจะถูกนำออก',
      confirmLabel: 'ล้างตะกร้า',
    );
    if (!ok || !mounted) return;
    final store = AppScope.read(context);
    for (final l in List.of(store.selfCart)) {
      store.selfRemove(l);
    }
  }

  Future<void> _submit() async {
    if (_submitting || _asking) return;
    final store = AppScope.read(context);
    if (store.selfCart.isEmpty) return;
    final bad = [
      for (final l in store.selfCart)
        if (_problem(store, l) != null) l.product.name,
    ];
    if (bad.isNotEmpty) {
      nvToast(context, 'กรุณานำรายการที่หมดออกก่อน: ${bad.toSet().join(', ')}', kind: NvToastKind.error);
      return;
    }
    final table = store.selfTable;
    _asking = true;
    final ok = await showNvConfirm(
      context,
      title: 'ส่งออเดอร์เข้าครัว?',
      message: '${table != null ? 'โต๊ะ $table' : 'ไม่ระบุโต๊ะ · รับที่เคาน์เตอร์'} · '
          '${store.selfCartCount} รายการ · ${baht(store.selfCartTotal)}\nเมื่อส่งแล้วครัวจะเริ่มทำทันที',
      confirmLabel: 'ส่งเข้าครัว',
      danger: false,
      art: 'kitchen',
    );
    _asking = false;
    if (!ok || !mounted || _submitting) return;
    setState(() => _submitting = true);
    final t = store.submitSelfOrder(note: _note.text.trim(), guests: _guestsFor(store));
    if (t == null) {
      setState(() => _submitting = false);
      nvToast(context, 'ส่งออเดอร์ไม่สำเร็จ · ตะกร้าว่างอยู่', kind: NvToastKind.error);
      return;
    }
    context.go('/cust/confirm?ticket=${Uri.encodeQueryComponent(t.id)}');
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final table = store.selfTable;
    final lines = store.selfCart;

    final header = CustTopBar(
      eyebrow: 'ตะกร้าของฉัน',
      title: store.shopName,
      subtitle: table != null ? 'โต๊ะ $table · ตรวจสอบรายการก่อนส่งเข้าครัว' : 'ไม่ระบุโต๊ะ · รับที่เคาน์เตอร์',
      onBack: () => context.go('/cust/menu'),
      actions: [if (table != null) CustCallWaiterButton(table: table, compact: true)],
    );

    if (lines.isEmpty) {
      return NvKiosk(
        child: Column(
          children: [
            header,
            Expanded(
              child: _submitting
                  ? const NvEmptyState(onNight: true, mascot: 'chef', title: 'กำลังส่งออเดอร์เข้าครัว…')
                  : NvEmptyState(
                      onNight: true,
                      mascot: 'empty',
                      title: 'ตะกร้ายังว่างอยู่',
                      message: 'เลือกเมนูที่ชอบแล้วกด “ใส่ตะกร้า” ได้เลย',
                      actionLabel: 'กลับไปเลือกเมนู',
                      actionIcon: NvIcons.utensils,
                      onAction: () => context.go('/cust/menu'),
                    ),
            ),
          ],
        ),
      );
    }

    final guests = _guestsFor(store);
    final anyProblem = lines.any((l) => _problem(store, l) != null);
    final vatPct = store.vatRate * 100;
    final vatText = (vatPct - vatPct.round()).abs() < 0.001 ? vatPct.round().toString() : vatPct.toStringAsFixed(1);
    final priceNote = store.vatEnabled && !store.vatInclusive
        ? 'ราคายังไม่รวม VAT $vatText% · ส่วนลดสมาชิก/โปรโมชัน (ถ้ามี) คำนวณตอนชำระเงิน'
        : 'ส่วนลดสมาชิก/โปรโมชัน (ถ้ามี) คำนวณตอนชำระเงินที่เคาน์เตอร์';

    final noteField = TextField(
      controller: _note,
      maxLength: 120,
      maxLines: 2,
      minLines: 1,
      style: Nv.ui(16, color: Nv.onNight),
      cursorColor: Nv.gold400,
      decoration: custNightInput('เช่น เสิร์ฟพร้อมกัน แพ้ถั่ว ขอช้อนเด็ก', icon: NvIcons.comment),
    );
    final guestsRow = Row(
      children: [
        const Icon(NvIcons.users, size: 16, color: Nv.gold300),
        const SizedBox(width: 10),
        Expanded(child: Text('จำนวนผู้ทาน', style: Nv.ui(16.5, color: Nv.onNight, weight: FontWeight.w600))),
        CustStepper(
          value: guests,
          onMinus: guests > 1 ? () => setState(() => _guests = guests - 1) : null,
          onPlus: guests < 30 ? () => setState(() => _guests = guests + 1) : null,
        ),
      ],
    );
    final confirmBtn = NvButton.gold(
      'ยืนยันสั่งอาหาร',
      icon: NvIcons.fire,
      size: NvButtonSize.xl,
      expand: true,
      loading: _submitting,
      onPressed: anyProblem ? null : _submit,
    );
    final problemNote = anyProblem
        ? Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text('มีบางรายการหมดแล้ว กรุณานำออกก่อนส่งเข้าครัว',
                style: Nv.ui(14, color: Nv.lacquerLight, weight: FontWeight.w600)),
          )
        : null;

    return NvKiosk(
      child: Column(
        children: [
          header,
          Expanded(
            child: LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth >= 900;
              final compact = c.maxWidth < 560;
              final listHead = Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: NvSectionTitle('รายการในตะกร้า', trailing: '${store.selfCartCount} รายการ', onNight: true, icon: NvIcons.basket),
                    ),
                    const SizedBox(width: 10),
                    NvButton.ghost('ล้างตะกร้า', onNight: true, icon: NvIcons.trash, size: NvButtonSize.xl, onPressed: _clearAll),
                  ],
                ),
              );
              Widget tile(CartLine l) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LineTile(
                      line: l,
                      compact: compact,
                      problem: _problem(store, l),
                      icon: custCategoryIcon(store, store.productByCode(l.product.code) ?? l.product),
                      onMinus: () => _dec(l),
                      onPlus: () => _inc(l),
                      onRemove: () => _remove(l),
                    ),
                  );

              if (wide) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ListView(
                          children: [listHead, for (final l in lines) tile(l)],
                        ),
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: 410,
                        child: NvNightCard(
                          padding: const EdgeInsets.all(20),
                          glow: true,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const NvSectionTitle('ข้อความถึงครัว', onNight: true, icon: NvIcons.comment),
                                noteField,
                                const SizedBox(height: 8),
                                guestsRow,
                                const SizedBox(height: 12),
                                const NvKanokDivider(width: 220, thin: true, opacity: 0.85),
                                const SizedBox(height: 8),
                                NvKeyValue('จำนวนรายการ', '${store.selfCartCount}', onNight: true),
                                NvKeyValue('โต๊ะ', table != null ? '$table' : 'รับที่เคาน์เตอร์', onNight: true),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(child: Text('ยอดรวม', style: Nv.ui(17, color: Nv.onNight, weight: FontWeight.w700))),
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerRight,
                                        child: NvFoilText(baht(store.selfCartTotal), style: Nv.money(36)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(priceNote, style: Nv.ui(12.5, color: Nv.onNight3, height: 1.4)),
                                const SizedBox(height: 16),
                                ?problemNote,
                                confirmBtn,
                                const SizedBox(height: 10),
                                NvButton.ghost('เลือกเมนูเพิ่ม',
                                    onNight: true, icon: NvIcons.plus, size: NvButtonSize.xl, expand: true, onPressed: () => context.go('/cust/menu')),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                      children: [
                        listHead,
                        for (final l in lines) tile(l),
                        const SizedBox(height: 6),
                        const NvSectionTitle('ข้อความถึงครัว', onNight: true, icon: NvIcons.comment),
                        noteField,
                        const SizedBox(height: 8),
                        guestsRow,
                        const SizedBox(height: 14),
                        NvButton.ghost('เลือกเมนูเพิ่ม',
                            onNight: true, icon: NvIcons.plus, size: NvButtonSize.xl, expand: true, onPressed: () => context.go('/cust/menu')),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    decoration: BoxDecoration(
                      color: Nv.navy900.withValues(alpha: 0.94),
                      border: const Border(top: BorderSide(color: Nv.lineNight)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('ยอดรวม · ${store.selfCartCount} รายการ',
                                  style: Nv.ui(15.5, color: Nv.onNight, weight: FontWeight.w700)),
                            ),
                            FittedBox(fit: BoxFit.scaleDown, child: NvFoilText(baht(store.selfCartTotal), style: Nv.money(30))),
                          ],
                        ),
                        Text(priceNote, maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.ui(12, color: Nv.onNight3)),
                        const SizedBox(height: 10),
                        ?problemNote,
                        confirmBtn,
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _LineTile extends StatelessWidget {
  final CartLine line;
  final bool compact;
  final String? problem;
  final IconData icon;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onRemove;

  const _LineTile({
    required this.line,
    required this.compact,
    required this.problem,
    required this.icon,
    required this.onMinus,
    required this.onPlus,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l = line;
    final detail = custLineDetail(l);
    final soldOut = problem != null;
    final picture = SizedBox(
      width: compact ? 76 : 92,
      height: compact ? 76 : 92,
      child: CustFoodPicture.product(l.product, icon: icon, soldOut: soldOut),
    );
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l.product.name,
            maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.ui(17, color: Nv.onNight, weight: FontWeight.w700, height: 1.3)),
        if (detail.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.ui(13.5, color: Nv.gold300, height: 1.35)),
        ],
        const SizedBox(height: 4),
        Text('${baht(l.unitPrice)} / ที่', style: Nv.money(13.5, color: Nv.onNight3, weight: FontWeight.w500)),
        if (problem != null) ...[const SizedBox(height: 6), NvBadge(problem!, tint: NvTint.lacquer, icon: NvIcons.warning)],
      ],
    );
    final stepper = CustStepper(value: l.qty, onMinus: onMinus, onPlus: soldOut ? null : onPlus);
    final remove = NvIconButton(NvIcons.trash, size: 56, onNight: true, tooltip: 'นำออกจากตะกร้า', onPressed: onRemove);
    final total = Text(baht(l.lineTotal), style: Nv.money(compact ? 20 : 22, color: Nv.gold200));

    return NvNightCard(
      padding: const EdgeInsets.all(12),
      radius: Nv.rLg,
      selected: soldOut,
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [picture, const SizedBox(width: 12), Expanded(child: info), const SizedBox(width: 6), remove],
                ),
                const SizedBox(height: 10),
                Row(children: [Expanded(child: total), stepper]),
              ],
            )
          : Row(
              children: [
                picture,
                const SizedBox(width: 14),
                Expanded(child: info),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [total, const SizedBox(height: 8), stepper],
                ),
                const SizedBox(width: 10),
                remove,
              ],
            ),
    );
  }
}
