// Thaiprompt POS — คืนเงิน (Refund) · Nova.
//
// Pick a paid bill (from /refund?id=, or search the recent ones), choose the
// quantities to give back (default: everything still refundable, or tap
// "คืนทั้งบิล"), pick a reason, and confirm. Every refund needs a manager PIN
// and goes through PosStore.refundOrder, which restocks the items, reverses
// loyalty points and keeps the bill with its refund amount. The amount shown
// before confirming mirrors the store's own maths (proportional to the bill's
// discount / VAT); the store's actual result is shown afterwards. Cash
// refunds of bills from an earlier shift are recorded as a drawer pay-out in
// the current shift so the cash count still balances.
//
// by xman studio

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/extra_models.dart';
import '../models/order_models.dart';
import '../print/print_actions.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';

const _reasons = ['ลูกค้าเปลี่ยนใจ', 'สินค้ามีปัญหา', 'คิดเงินผิด', 'อื่น ๆ'];

/// Bill lines that share a product code. PosStore.refundOrder takes quantities
/// per code and applies the same number to every line with that code (capped
/// by what each line has left), so the UI edits per code too.
class _Group {
  final String code;
  final List<OrderLine> lines;
  _Group(this.code, this.lines);

  String get name => lines.first.name;
  int get maxQty => lines.fold(0, (m, l) => math.max(m, l.refundableQty));
  int get sold => lines.fold(0, (s, l) => s + l.qty);
  int get refunded => lines.fold(0, (s, l) => s + l.refundedQty);
  int grossFor(int q) => lines.fold(0, (s, l) => s + math.min(q, l.refundableQty) * l.price);
}

List<_Group> _groupsOf(Order o) {
  final map = <String, List<OrderLine>>{};
  for (final l in o.lines) {
    (map[l.code] ??= <OrderLine>[]).add(l);
  }
  return [for (final e in map.entries) _Group(e.key, e.value)];
}

String _summary(List<OrderLine> lines) {
  if (lines.isEmpty) return '—';
  final head = lines.take(2).map((l) => '${l.name} ×${l.qty}').join(', ');
  return lines.length > 2 ? '$head +${lines.length - 2}' : head;
}

class RefundScreen extends StatefulWidget {
  const RefundScreen({super.key});

  @override
  State<RefundScreen> createState() => _RefundScreenState();
}

class _RefundScreenState extends State<RefundScreen> {
  String? _orderId;
  String? _lastParam;
  bool _init = false;
  String? _missingId;
  final Map<String, int> _qty = <String, int>{};
  String? _reason;
  final _note = TextEditingController();
  String _query = '';
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = GoRouterState.of(context).uri.queryParameters['id'];
    if (!_init || id != _lastParam) {
      _init = true;
      _lastParam = id;
      if (id != null) {
        final o = AppScope.read(context).orderById(id);
        _missingId = o == null ? id : null;
        _pick(o);
      }
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// Select a bill (null = back to the picker). Defaults to refunding
  /// everything that is still refundable.
  void _pick(Order? o) {
    _orderId = o?.id;
    _qty.clear();
    if (o != null) {
      for (final g in _groupsOf(o)) {
        _qty[g.code] = g.maxQty;
      }
    }
    _reason = null;
    _note.clear();
  }

  String _reasonText() {
    final note = _note.text.trim();
    if (_reason == null || _reason == _reasons.last) return note;
    return note.isEmpty ? _reason! : '${_reason!} · $note';
  }

  String _blockReason(int items) {
    if (items == 0) return 'เลือกจำนวนสินค้าที่จะคืนอย่างน้อย 1 ชิ้น';
    if (_reason == null) return 'เลือกเหตุผลการคืนเงิน';
    if (_reason == _reasons.last && _note.text.trim().isEmpty) return 'ระบุเหตุผลการคืนเงิน';
    return '';
  }

  /// Mirrors PosStore.refundOrder so the cashier sees the amount before confirming.
  ({int items, int gross, int amount}) _calc(Order o) {
    final ratio = o.subtotal == 0 ? 1.0 : o.total / o.subtotal;
    var gross = 0;
    var items = 0;
    var allBack = true;
    for (final l in o.lines) {
      final want = (_qty[l.code] ?? 0).clamp(0, l.refundableQty);
      gross += want * l.price;
      items += want;
      if (l.refundableQty - want != 0) allBack = false;
    }
    if (gross == 0) return (items: 0, gross: 0, amount: 0);
    final left = o.total - o.refundAmount;
    var amount = (gross * ratio).round();
    if (allBack) amount = left;
    return (items: items, gross: gross, amount: amount.clamp(0, left));
  }

  Future<void> _submit(Order o) async {
    if (_busy) return; // double-tap guard (covers the confirm + PIN dialogs too)
    _busy = true;
    try {
      await _runRefund(o);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      } else {
        _busy = false;
      }
    }
  }

  Future<void> _runRefund(Order o) async {
    final calc = _calc(o);
    final reason = _reasonText();
    final qty = Map<String, int>.of(_qty)..removeWhere((_, v) => v <= 0);
    final ok = await showNvConfirm(
      context,
      title: 'ยืนยันคืนเงิน ${baht(calc.amount)}?',
      message: 'บิล ${o.id} · ${calc.items} ชิ้น\nเหตุผล: $reason\n\nสินค้าจะถูกคืนเข้าสต็อก และหักแต้มสมาชิก (ถ้ามี)',
      confirmLabel: 'คืนเงิน',
      art: 'refund',
    );
    if (!ok || !mounted) return;
    final mgr = await showManagerPin(context, reason: 'คืนเงินบิล ${o.id} · ${baht(calc.amount)}');
    if (mgr == null || !mounted) return;

    final store = AppScope.read(context);
    final cur = store.currentShift;
    final shiftOpen = cur != null && cur.isOpen;
    final inShift = cur != null && cur.isOpen && store.ordersInShift(cur).any((x) => x.id == o.id);

    int refunded;
    try {
      refunded = store.refundOrder(o, qtyByCode: qty, reason: reason, approvedBy: mgr);
    } on StateError catch (e) {
      nvToast(context, e.message, kind: NvToastKind.error);
      return;
    }

    // A cash bill from an earlier shift is paid out of today's drawer.
    var payoutLogged = false;
    if (refunded > 0 && o.method == PaymentMethod.cash && shiftOpen && !inShift) {
      store.addCashMovement(CashMoveType.payOut, refunded, reason: 'คืนเงินบิล ${o.id} (บิลนอกกะ)');
      payoutLogged = true;
    }

    setState(() {
      for (final k in _qty.keys.toList()) {
        _qty[k] = 0; // never leave a ready-to-go second refund selected
      }
      _reason = null;
      _note.clear();
    });

    if (refunded <= 0) {
      nvToast(context, 'ไม่มีรายการที่คืนได้ในบิลนี้', kind: NvToastKind.warning);
      return;
    }

    final cash = o.method == PaymentMethod.cash;
    final printIt = await showNvDialog<bool>(
      context,
      title: 'คืนเงินสำเร็จ',
      mascot: 'wai',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(baht(refunded), textAlign: TextAlign.center, style: Nv.money(38, color: Nv.lacquerDeep)),
          const SizedBox(height: 4),
          Text('บิล ${o.id} · อนุมัติโดย ${mgr.name}', textAlign: TextAlign.center, style: Nv.ui(13.5, color: Nv.ink3)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: cash ? Nv.amberTint : Nv.sapphireTint, borderRadius: BorderRadius.circular(Nv.rSm)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(cash ? NvIcons.moneyBill : NvIcons.info, size: 16, color: cash ? Nv.amber : Nv.sapphire),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    cash
                        ? 'กรุณาคืนเงินสด ${baht(refunded)} ให้ลูกค้าจากลิ้นชัก'
                            '${payoutLogged ? '\nบิลนี้อยู่นอกกะปัจจุบัน — บันทึก "นำเงินออก ${baht(refunded)}" ในกะนี้ให้แล้ว เพื่อให้ยอดลิ้นชักตรง' : ''}'
                            '${shiftOpen ? '' : '\nยังไม่ได้เปิดกะ — ยอดนี้จึงไม่ถูกหักจากลิ้นชักในระบบ'}'
                        : 'คืนเงินให้ลูกค้าผ่านช่องทางเดิม (${o.method.label})',
                    style: Nv.ui(13.5, color: Nv.ink2, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: (ctx) => [
        NvButton.soft('ปิด', onPressed: () => Navigator.of(ctx).pop(false)),
        NvButton.gold('พิมพ์ใบเสร็จฉบับแก้ไข', icon: NvIcons.print, onPressed: () => Navigator.of(ctx).pop(true)),
      ],
    );
    if (printIt == true && mounted) await printReceipt(context, o);
  }

  // ─────────────────────────── build ───────────────────────────

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final order = _orderId == null ? null : store.orderById(_orderId!);
    return NvScaffold(
      title: 'คืนเงิน',
      eyebrow: 'ต้องอนุมัติโดยผู้จัดการ',
      subtitle: 'คืนทั้งบิลหรือบางรายการ · คืนสต็อกและหักแต้มสมาชิกอัตโนมัติ',
      art: 'refund',
      actions: [
        NvButton.soft('บิลย้อนหลัง', icon: NvIcons.receipt, size: NvButtonSize.sm, onPressed: () => context.go('/orders')),
      ],
      body: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 860;
        final Widget left;
        final Widget right;
        if (order == null) {
          left = _picker(store);
          right = _history(store);
        } else if (order.method == PaymentMethod.thaiprompt) {
          left = _thaiPromptState(order);
          right = _history(store);
        } else if (order.status != OrderStatus.paid || order.lines.every((l) => l.refundableQty == 0)) {
          left = _doneState(order);
          right = _history(store);
        } else {
          left = _billLines(order);
          right = _summaryPanel(order);
        }
        if (!wide) {
          return ListView(padding: const EdgeInsets.only(bottom: 16), children: [left, const SizedBox(height: 16), right]);
        }
        final rw = (c.maxWidth * 0.36).clamp(340.0, 420.0);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: SingleChildScrollView(padding: const EdgeInsets.only(bottom: 16), child: left)),
            const SizedBox(width: 16),
            SizedBox(width: rw, child: SingleChildScrollView(padding: const EdgeInsets.only(bottom: 16), child: right)),
          ],
        );
      }),
    );
  }

  Widget _picker(PosStore store) {
    final q = _query.trim().toLowerCase();
    final all = store.paidOrders;
    final matches = q.isEmpty
        ? all
        : all.where((o) => '${o.id} ${o.reference} ${o.customerName ?? ''} ${o.paymentRef ?? ''}'.toLowerCase().contains(q)).toList();
    final shown = matches.take(60).toList();
    return NvSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NvSectionTitle('เลือกบิลที่จะคืนเงิน', icon: NvIcons.search, trailing: '${matches.length} บิล'),
          if (_missingId != null)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Nv.amberTint, borderRadius: BorderRadius.circular(Nv.rSm)),
              child: Row(
                children: [
                  const Icon(NvIcons.warning, size: 14, color: Nv.amber),
                  const SizedBox(width: 8),
                  Expanded(child: Text('ไม่พบบิล $_missingId ในเครื่องนี้ — เลือกจากรายการด้านล่าง', style: Nv.ui(13, color: Nv.ink2))),
                ],
              ),
            ),
          NvSearchField(hint: 'ค้นหาเลขบิล / ลูกค้า / เลขอ้างอิง', onChanged: (v) => setState(() => _query = v)),
          const SizedBox(height: 12),
          if (all.isEmpty)
            NvEmptyState(
              mascot: 'empty',
              title: 'ยังไม่มีบิลที่คืนเงินได้',
              message: 'บิลที่ชำระแล้วจะแสดงที่นี่',
              actionLabel: 'ไปหน้าขาย',
              actionIcon: NvIcons.cashier,
              onAction: () => context.go('/cashier'),
              size: 120,
            )
          else if (shown.isEmpty)
            const NvEmptyState(mascot: 'search', title: 'ไม่พบบิลที่ค้นหา', message: 'ลองพิมพ์เลขบิล เช่น A1042 หรือชื่อลูกค้า', size: 120)
          else
            for (final o in shown)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PickRow(
                  order: o,
                  onTap: () => setState(() {
                    _missingId = null;
                    _pick(o);
                  }),
                ),
              ),
          if (matches.length > shown.length)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('แสดง ${shown.length} บิลล่าสุด · พิมพ์ค้นหาเพื่อหาบิลที่เก่ากว่า',
                  textAlign: TextAlign.center, style: Nv.ui(12, color: Nv.ink3)),
            ),
        ],
      ),
    );
  }

  Widget _billHeader(Order o) {
    final who = [
      o.cashier,
      if (o.customerName != null && o.customerName!.isNotEmpty) 'ลูกค้า ${o.customerName}',
      if (o.type == OrderType.dineIn && o.tableNumber != null) 'โต๊ะ ${o.tableNumber}' else o.type.label,
    ].join(' · ');
    return NvSheet(
      goldEdge: true,
      child: Row(
        children: [
          NvArt.icon(o.method.art, size: 50),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('บิล ${o.id}', style: Nv.display(21)),
                Text('${thaiDateTime(o.createdAt)} · ${o.method.label}', style: Nv.ui(12.5, color: Nv.ink3)),
                Text(who, maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.ui(12.5, color: Nv.ink3)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              NvMoney(o.total, size: 21),
              if (o.discount > 0) Text('ส่วนลด ${baht(o.discount)}', style: Nv.ui(12, color: Nv.ink3)),
              if (o.refundAmount > 0) Text('คืนแล้ว ${baht(o.refundAmount)}', style: Nv.ui(12, color: Nv.lacquer, weight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _billLines(Order o) {
    final groups = _groupsOf(o);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _billHeader(o),
        const SizedBox(height: 14),
        NvSheet(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const NvSectionTitle('เลือกรายการที่จะคืน', icon: NvIcons.listCheck),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  NvButton.gold('คืนทั้งบิล', icon: NvIcons.listCheck, size: NvButtonSize.sm, onPressed: () => setState(() {
                        for (final g in groups) {
                          _qty[g.code] = g.maxQty;
                        }
                      })),
                  NvButton.soft('ล้างที่เลือก', icon: NvIcons.xmark, size: NvButtonSize.sm, onPressed: () => setState(() {
                        for (final g in groups) {
                          _qty[g.code] = 0;
                        }
                      })),
                  NvButton.soft('เปลี่ยนบิล', icon: NvIcons.rightLeft, size: NvButtonSize.sm, onPressed: () => setState(() => _pick(null))),
                ],
              ),
              const SizedBox(height: 6),
              for (var i = 0; i < groups.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _GroupRow(
                  group: groups[i],
                  qty: _qty[groups[i].code] ?? 0,
                  onChanged: (q) => setState(() => _qty[groups[i].code] = q),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryPanel(Order o) {
    final calc = _calc(o);
    final block = _blockReason(calc.items);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NvSheet(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const NvSectionTitle('เหตุผลการคืนเงิน', icon: NvIcons.comment),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in _reasons) NvChip(r, selected: _reason == r, onTap: () => setState(() => _reason = r)),
                ],
              ),
              const SizedBox(height: 12),
              NvField(
                label: _reason == _reasons.last ? 'ระบุเหตุผล (จำเป็น)' : 'หมายเหตุเพิ่มเติม (ถ้ามี)',
                controller: _note,
                maxLines: 2,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        NvNightCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ยอดคืนเงิน', style: Nv.eyebrow(color: Nv.gold300)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: NvFoilText(baht(calc.amount), style: Nv.money(36)),
              ),
              const SizedBox(height: 10),
              NvKeyValue('จำนวนที่คืน', '${calc.items} ชิ้น', onNight: true),
              NvKeyValue('มูลค่าสินค้าที่เลือก', baht(calc.gross), onNight: true),
              if (o.total != o.subtotal)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('ปรับตามสัดส่วนส่วนลด/VAT ของบิล (จ่ายจริง ${baht(o.total)} จากราคาสินค้า ${baht(o.subtotal)})',
                      style: Nv.ui(11.5, color: Nv.onNight3, height: 1.4)),
                ),
              NvKeyValue('คืนผ่าน', o.method.label, onNight: true, mono: false),
              if (o.refundAmount > 0) NvKeyValue('คืนไปแล้วก่อนหน้า', baht(o.refundAmount), onNight: true),
              if (o.method == PaymentMethod.cash)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(NvIcons.moneyBill, size: 13, color: Nv.gold300),
                      const SizedBox(width: 8),
                      Expanded(child: Text('ต้องคืนเงินสดจากลิ้นชักให้ลูกค้า', style: Nv.ui(12.5, color: Nv.gold200))),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              NvButton.danger(
                'ยืนยันคืนเงิน',
                icon: NvIcons.refund,
                size: NvButtonSize.lg,
                expand: true,
                loading: _busy,
                onPressed: block.isEmpty && !_busy ? () => _submit(o) : null,
              ),
              if (block.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(block, textAlign: TextAlign.center, style: Nv.ui(12.5, color: Nv.onNight2)),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(NvIcons.shield, size: 11, color: Nv.gold300),
                  const SizedBox(width: 6),
                  Flexible(child: Text('ต้องใส่ PIN ผู้จัดการก่อนคืนเงินทุกครั้ง', style: Nv.ui(11.5, color: Nv.onNight3))),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Paid in the Thai Prompt app → refunds go through Thai Prompt, not the till.
  Widget _thaiPromptState(Order o) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _billHeader(o),
          const SizedBox(height: 14),
          NvSheet(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NvArt.icon('delivery', size: 72),
                const SizedBox(height: 8),
                Text('บิลนี้ลูกค้าจ่ายผ่านแอป Thai Prompt', textAlign: TextAlign.center, style: Nv.display(20)),
                const SizedBox(height: 6),
                Text(
                  'เงินอยู่ในระบบ Thai Prompt — ถ้าลูกค้าไม่ได้รับของหรือของมีปัญหา ให้ลูกค้ากด "แจ้งปัญหา" ในแอป '
                  'แอดมิน Thai Prompt จะคืนเงินเข้ากระเป๋าให้ ห้ามคืนเป็นเงินสดจากลิ้นชัก',
                  textAlign: TextAlign.center,
                  style: Nv.ui(13.5, color: Nv.ink3, height: 1.45),
                ),
                if (o.paymentRef != null) ...[
                  const SizedBox(height: 6),
                  Text('อ้างอิง ${o.paymentRef}', style: Nv.money(13, color: Nv.ink2)),
                ],
                const SizedBox(height: 16),
                NvButton.soft('เลือกบิลอื่น', icon: NvIcons.rightLeft, onPressed: () => setState(() => _pick(null))),
              ],
            ),
          ),
        ],
      );

  Widget _doneState(Order o) {
    final full = o.status == OrderStatus.refunded;
    final when = [
      'คืนไป ${baht(o.refundAmount)}',
      if (o.refundedAt != null) 'เมื่อ ${thaiDateTime(o.refundedAt!)}',
      if (o.refundedBy != null) 'อนุมัติโดย ${o.refundedBy}',
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _billHeader(o),
        const SizedBox(height: 14),
        NvSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NvArt.mascot('face', height: 130),
              const SizedBox(height: 8),
              Text(full ? 'บิลนี้คืนเงินครบแล้ว' : 'บิลนี้คืนเงินไม่ได้', textAlign: TextAlign.center, style: Nv.display(20)),
              const SizedBox(height: 6),
              Text(full ? when : 'สถานะบิล: ${o.status.label}',
                  textAlign: TextAlign.center, style: Nv.ui(13.5, color: Nv.ink3, height: 1.45)),
              if (o.refundReason != null)
                Text('เหตุผล: ${o.refundReason}', textAlign: TextAlign.center, style: Nv.ui(13, color: Nv.ink2)),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  NvButton.soft('เลือกบิลอื่น', icon: NvIcons.rightLeft, onPressed: () => setState(() => _pick(null))),
                  NvButton.gold('พิมพ์ใบเสร็จ', icon: NvIcons.print, onPressed: () => printReceipt(context, o)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _history(PosStore store) {
    final hist = store.orders.where((o) => o.refundAmount > 0).toList()
      ..sort((a, b) => (b.refundedAt ?? b.createdAt).compareTo(a.refundedAt ?? a.createdAt));
    final total = hist.fold<int>(0, (s, o) => s + o.refundAmount);
    final shown = hist.take(50).toList();

    Widget mini(String label, String value) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: Nv.paper, borderRadius: BorderRadius.circular(Nv.rSm), border: Border.all(color: Nv.line)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Nv.ui(11.5, color: Nv.ink3)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: Nv.money(17, color: Nv.lacquerDeep)),
              ),
            ],
          ),
        );

    return NvSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NvSectionTitle('ประวัติการคืนเงิน', icon: NvIcons.history, trailing: '${hist.length} บิล'),
          Row(
            children: [
              Expanded(child: mini('คืนวันนี้', baht(store.todayRefunds))),
              const SizedBox(width: 10),
              Expanded(child: mini('รวมทั้งหมด', baht(total))),
            ],
          ),
          const SizedBox(height: 10),
          if (hist.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  NvArt.mascot('cheer', height: 100),
                  const SizedBox(height: 6),
                  Text('ยังไม่มีการคืนเงิน', style: Nv.ui(13.5, color: Nv.ink3)),
                ],
              ),
            )
          else
            for (var i = 0; i < shown.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              _HistRow(order: shown[i], onTap: () => setState(() => _pick(shown[i]))),
            ],
          if (hist.length > shown.length)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('แสดง ${shown.length} รายการล่าสุด', textAlign: TextAlign.center, style: Nv.ui(12, color: Nv.ink3)),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────── pieces ───────────────────────────

class _PickRow extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  const _PickRow({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final o = order;
    return NvSheet(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      color: Nv.paper,
      shadow: const [],
      onTap: onTap,
      child: Row(
        children: [
          NvArt.icon(o.method.art, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(o.id, style: Nv.money(14.5)),
                    const SizedBox(width: 8),
                    Flexible(child: Text(thaiDateTime(o.createdAt), maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(12, color: Nv.ink3))),
                  ],
                ),
                Text(
                  o.customerName != null && o.customerName!.isNotEmpty ? '${o.customerName} · ${_summary(o.lines)}' : _summary(o.lines),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Nv.ui(12.5, color: Nv.ink2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(baht(o.netTotal), style: Nv.money(15)),
              if (o.refundAmount > 0) const NvBadge('คืนบางส่วน', tint: NvTint.amber),
            ],
          ),
          const SizedBox(width: 6),
          const Icon(NvIcons.angleRight, size: 13, color: Nv.ink4),
        ],
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  final _Group group;
  final int qty;
  final ValueChanged<int> onChanged;
  const _GroupRow({required this.group, required this.qty, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final g = group;
    final max = g.maxQty;
    final single = g.lines.length == 1;
    final l0 = g.lines.first;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Thumb(line: l0),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(g.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.ui(14.5, weight: FontWeight.w600)),
                    if (single && l0.detail.isNotEmpty) Text(l0.detail, style: Nv.ui(12, color: Nv.ink3)),
                    Text(
                      single
                          ? 'ขาย ${l0.qty} · คืนแล้ว ${l0.refundedQty} · @${baht(l0.price)}'
                          : '${g.lines.length} ตัวเลือก · ขาย ${g.sold} · คืนแล้ว ${g.refunded}',
                      style: Nv.ui(12, color: Nv.ink3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (max == 0)
                const NvBadge('คืนครบแล้ว', tint: NvTint.neutral)
              else
                NvStepper(
                  value: qty,
                  onMinus: qty > 0 ? () => onChanged(qty - 1) : null,
                  onPlus: qty < max ? () => onChanged(qty + 1) : null,
                ),
              SizedBox(
                width: 80,
                child: Text(baht(g.grossFor(qty)),
                    textAlign: TextAlign.right, style: Nv.money(14.5, color: qty == 0 ? Nv.ink4 : Nv.ink)),
              ),
            ],
          ),
          if (!single)
            Padding(
              padding: const EdgeInsets.only(left: 52, top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final l in g.lines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '• ${l.detail.isEmpty ? 'ปกติ' : l.detail} · ขาย ${l.qty}${l.refundedQty > 0 ? ' · คืนแล้ว ${l.refundedQty}' : ''} · @${baht(l.price)}',
                              style: Nv.ui(12, color: Nv.ink2),
                            ),
                          ),
                          Text('คืน ${math.min(qty, l.refundableQty)}', style: Nv.money(12, color: Nv.goldInk)),
                        ],
                      ),
                    ),
                  Text('สินค้าเดียวกันต่างตัวเลือก: ระบบคืนจำนวนที่เลือกจากทุกตัวเลือก (ไม่เกินที่เหลือของแต่ละตัว)',
                      style: Nv.ui(11.5, color: Nv.amber, height: 1.35)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final OrderLine line;
  const _Thumb({required this.line});

  @override
  Widget build(BuildContext context) {
    final art = line.art;
    if (art != null) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: Nv.paper, borderRadius: BorderRadius.circular(10), border: Border.all(color: Nv.lineSoft)),
        child: NvArt.food(art, size: 38, fallbackIcon: NvIcons.utensils),
      );
    }
    final h = line.hue.toDouble();
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HSLColor.fromAHSL(1, h, 0.45, 0.55).toColor(), HSLColor.fromAHSL(1, h, 0.5, 0.33).toColor()],
        ),
      ),
      child: Text(line.name.isEmpty ? '?' : String.fromCharCode(line.name.runes.first),
          style: Nv.ui(16, color: Colors.white, weight: FontWeight.w700)),
    );
  }
}

class _HistRow extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  const _HistRow({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final o = order;
    final full = o.status == OrderStatus.refunded;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(Nv.rSm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(color: Nv.lacquerTint, shape: BoxShape.circle),
                child: const Icon(NvIcons.refund, size: 13, color: Nv.lacquerDeep),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(o.id, style: Nv.money(13.5)),
                        const SizedBox(width: 8),
                        NvBadge(full ? 'คืนครบ' : 'คืนบางส่วน', tint: full ? NvTint.lacquer : NvTint.amber),
                      ],
                    ),
                    Text(o.refundReason ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(12, color: Nv.ink2)),
                    Text(
                      [
                        if (o.refundedAt != null) thaiDateTime(o.refundedAt!),
                        if (o.refundedBy != null) o.refundedBy!,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Nv.ui(11.5, color: Nv.ink3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('-${baht(o.refundAmount)}', style: Nv.money(14, color: Nv.lacquerDeep)),
            ],
          ),
        ),
      ),
    );
  }
}
