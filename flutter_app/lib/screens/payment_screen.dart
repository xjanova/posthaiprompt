// Thaiprompt POS — Payment (/payment): take the money for the live cart.
//
// Cart summary (lines, every discount, VAT, total) beside four method tiles
// with 3D art. Cash: keypad + quick notes → change (short = red, confirm
// disabled). PromptPay: a real EMVCo QR for the exact amount from the shop's
// PromptPay id (or a setup prompt when it is missing); staff confirms after
// seeing the money arrive. Card: done on the EDC terminal, the 6-character
// approval code is required. Wallet: optional reference. Confirm →
// store.checkout (shift / role guarded) → optional auto-print → /receipt.
// "ส่งด้วยไรเดอร์ Thai Prompt": the customer pays goods + delivery in the
// Thai Prompt app instead (tp_rider_dialog.dart) — the bill is booked when
// the payment lands, then the receipt opens.
// Cash sales kick the cash drawer when an ESC/POS receipt printer is set up
// (inside the receipt job when auto-print is on).
// Also prints a quotation (ใบเสนอราคา) of the current cart.
//
// by xman studio

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/hardware/printer_hub.dart';
import '../core/payments/promptpay.dart';
import '../core/print/print_service.dart';
import '../models/extra_models.dart';
import '../models/order_models.dart';
import '../print/print_actions.dart';
import '../print/quote_doc.dart';
import '../print/receipt_doc.dart' show ShopInfo;
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';
import 'tp_rider_dialog.dart';

const _methods = [PaymentMethod.cash, PaymentMethod.promptpay, PaymentMethod.card, PaymentMethod.wallet];

bool _isShiftBlock(PosStore s) =>
    s.cart.isNotEmpty &&
    s.currentStaff != null &&
    s.currentStaff!.role.canSell &&
    s.requireShift &&
    !s.hasOpenShift;

bool _promptReady(PosStore s) => s.promptPayId.isNotEmpty && PromptPay.isValidId(s.promptPayId);

/// Ask for the opening float and open the shift. True when a shift is open now.
Future<bool> _offerOpenShift(BuildContext context) async {
  final store = AppScope.read(context);
  if (store.hasOpenShift) return true;
  final amount = await showNvAmountDialog(
    context,
    title: 'เปิดกะการขาย',
    subtitle: 'ร้านกำหนดให้เปิดกะก่อนรับชำระเงิน · ใส่เงินทอนตั้งต้นในลิ้นชัก',
    art: 'drawer',
    confirmLabel: 'เปิดกะ',
    initial: store.shiftHistory.isNotEmpty ? store.shiftHistory.first.openingCash : null,
  );
  if (amount == null || !context.mounted) return false;
  store.openShift(openingCash: amount);
  nvToast(context, 'เปิดกะแล้ว · เงินทอนตั้งต้น ${baht(amount)}', kind: NvToastKind.success);
  return true;
}

/// Next round amounts above [total] (100 / 500 / 1,000 steps).
List<int> _quickAmounts(int total) {
  if (total <= 0) return const [];
  final out = <int>{};
  for (final step in const [100, 500, 1000]) {
    final v = ((total + step - 1) ~/ step) * step;
    if (v > total) out.add(v);
  }
  return out.toList()..sort();
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _method = PaymentMethod.cash;
  String _cash = ''; // digits of the cash tendered
  final _approval = TextEditingController();
  final _ref = TextEditingController();
  final _cashFocus = FocusNode(debugLabel: 'cash-keypad');
  bool _busy = false;
  bool _printingQuote = false;
  Order? _paid; // set right after checkout so the emptied cart never flashes the empty state

  int get _tendered => int.tryParse(_cash) ?? 0;

  @override
  void dispose() {
    _approval.dispose();
    _ref.dispose();
    _cashFocus.dispose();
    super.dispose();
  }

  void _select(PaymentMethod m) {
    if (_busy) return;
    setState(() => _method = m);
    if (m == PaymentMethod.cash) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _method == PaymentMethod.cash) _cashFocus.requestFocus();
      });
    }
  }

  // ── cash keypad ──

  void _cashInput(String k) {
    if (_busy) return;
    setState(() {
      switch (k) {
        case 'back':
          _cash = _cash.isEmpty ? '' : _cash.substring(0, _cash.length - 1);
        case 'clear':
          _cash = '';
        case '00':
          if (_cash.isNotEmpty && _cash.length <= 5) _cash += '00';
        default:
          if (_cash.length >= 7) return;
          _cash = (_cash == '0' ? '' : _cash) + k;
      }
    });
  }

  KeyEventResult _cashKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final ch = e.character;
    if (ch != null && RegExp(r'^\d$').hasMatch(ch)) {
      _cashInput(ch);
      return KeyEventResult.handled;
    }
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.backspace) {
      _cashInput('back');
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.escape || k == LogicalKeyboardKey.delete) {
      _cashInput('clear');
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      _confirm();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ── actions ──

  bool _canConfirm(PosStore store, int total) => switch (_method) {
        PaymentMethod.cash => total <= 0 || (_cash.isNotEmpty && _tendered >= total),
        PaymentMethod.promptpay => total > 0 && _promptReady(store),
        PaymentMethod.card => total > 0 && _approval.text.trim().length == 6,
        // thaiprompt is never a tile here — it is booked by the rider flow (_tpRider).
        PaymentMethod.wallet || PaymentMethod.thaiprompt => total > 0,
      };

  Future<void> _confirm() async {
    if (_busy) return;
    final store = AppScope.read(context);
    if (store.cart.isEmpty) return;
    if (_isShiftBlock(store)) {
      nvToast(context, store.checkoutBlockReason, kind: NvToastKind.warning);
      final opened = await _offerOpenShift(context);
      if (!opened || !mounted) return;
    }
    final block = store.checkoutBlockReason;
    if (block.isNotEmpty) {
      nvToast(context, block, kind: NvToastKind.warning);
      return;
    }
    final total = store.cartTotal;
    var cash = 0;
    String? ref;
    switch (_method) {
      case PaymentMethod.cash:
        if (_cash.isEmpty && total > 0) {
          nvToast(context, 'ใส่จำนวนเงินที่รับมา หรือกด "พอดี"', kind: NvToastKind.info);
          return;
        }
        cash = _cash.isEmpty ? total : _tendered;
        if (cash < total) {
          nvToast(context, 'เงินไม่พอ · ขาดอีก ${baht(total - cash)}', kind: NvToastKind.error);
          return;
        }
      case PaymentMethod.promptpay:
        if (!_promptReady(store)) {
          nvToast(context, 'ยังไม่ได้ตั้งค่าพร้อมเพย์ของร้าน', kind: NvToastKind.warning);
          return;
        }
        final r = _ref.text.trim();
        ref = r.isEmpty ? null : 'PromptPay $r';
      case PaymentMethod.card:
        final code = _approval.text.trim().toUpperCase();
        if (code.length != 6) {
          nvToast(context, 'กรอกรหัสอนุมัติ 6 ตัวจากสลิปเครื่อง EDC', kind: NvToastKind.warning);
          return;
        }
        ref = 'EDC $code';
      case PaymentMethod.wallet || PaymentMethod.thaiprompt:
        final r = _ref.text.trim();
        ref = r.isEmpty ? null : r;
    }
    setState(() => _busy = true);
    final order = store.checkout(method: _method, cashReceived: cash, paymentRef: ref);
    if (order == null) {
      setState(() => _busy = false);
      final r = store.checkoutBlockReason;
      nvToast(context, r.isNotEmpty ? r : 'เงินไม่พอ', kind: NvToastKind.error);
      return;
    }
    setState(() => _paid = order);
    // Cash sale + ESC/POS printer → open the drawer. With auto-print the kick
    // rides in the receipt job (one connection); otherwise it is sent alone.
    final kick = order.method == PaymentMethod.cash && store.drawerOnCash && PrinterHub.instance.usesEscPos;
    // The root navigator outlives this page, so a late drawer error can still toast.
    final rootNav = Navigator.of(context, rootNavigator: true);
    if (store.autoPrintReceipt) {
      final printed = await printReceipt(context, order, quiet: true, kickDrawer: kick);
      if (kick && !printed) _kickDrawer(rootNav); // the print job (and its kick) failed
      if (!mounted) return;
    } else if (kick) {
      _kickDrawer(rootNav);
    }
    if (!mounted) return;
    context.go('/receipt?id=${order.id}');
  }

  /// Customer pays goods + delivery in the Thai Prompt app; a rider collects.
  Future<void> _tpRider() async {
    if (_busy) return;
    final store = AppScope.read(context);
    if (_isShiftBlock(store)) {
      nvToast(context, store.checkoutBlockReason, kind: NvToastKind.warning);
      final opened = await _offerOpenShift(context);
      if (!opened || !mounted) return;
    }
    final block = tpRiderBlockReason(store);
    if (block.isNotEmpty) {
      nvToast(context, block, kind: NvToastKind.warning);
      return;
    }
    final res = await showTpRiderDialog(context);
    if (!mounted || res == null) return;
    switch (res.outcome) {
      case TpRiderOutcome.paid:
        final order = store.orderById(res.job?.orderId ?? '');
        if (order == null) return;
        setState(() => _paid = order);
        if (store.autoPrintReceipt) {
          await printReceipt(context, order, quiet: true);
          if (!mounted) return;
        }
        context.go('/receipt?id=${order.id}');
      case TpRiderOutcome.parked:
        context.go('/cashier');
      case TpRiderOutcome.closed:
        break;
    }
  }

  /// Fire-and-forget drawer kick; failures toast via the root navigator.
  void _kickDrawer(NavigatorState rootNav) {
    unawaited(PrinterHub.instance.openDrawer().catchError((Object e) {
      if (rootNav.mounted) {
        nvToast(rootNav.context, 'เปิดลิ้นชักเงินสดไม่สำเร็จ: ${e is PrinterException ? e.message : e}', kind: NvToastKind.error);
      }
    }));
  }

  Future<void> _printQuote() async {
    if (_printingQuote || _busy) return;
    final store = AppScope.read(context);
    if (store.cart.isEmpty) return;
    final now = DateTime.now();
    final doc = QuoteDoc(
      shop: ShopInfo.of(store),
      lines: store.cart.map((l) => l.toOrderLine()).toList(),
      subtotal: store.cartSubtotal,
      discount: store.cartDiscount,
      discountNote: store.discountNote,
      tax: store.cartTax,
      total: store.cartTotal,
      date: now,
      reference: QuoteDoc.referenceFor(now),
      staffName: store.actorName,
      orderLabel: store.orderType == OrderType.dineIn && store.tableNumber != null
          ? '${store.orderType.label} · โต๊ะ ${store.tableNumber}'
          : store.orderType.label,
      customerName: store.customerName,
      narrow: store.paperWidthMm == 58,
    );
    setState(() => _printingQuote = true);
    final res = await PrintService.printDoc(
      context,
      doc,
      jobName: 'ใบเสนอราคา ${doc.reference}',
      medium: rollMedium(store.paperWidthMm),
      printerName: store.printerName,
      precache: QuoteDoc.precache,
    );
    if (!mounted) return;
    setState(() => _printingQuote = false);
    if (res.ok) store.log('quote', '${doc.reference} ฿${doc.total}');
    nvToast(context, res.ok ? 'พิมพ์ใบเสนอราคา ${doc.reference} แล้ว' : res.message,
        kind: res.ok ? NvToastKind.success : NvToastKind.warning);
  }

  // ── build ──

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final paid = _paid;
    if (paid != null) {
      return NvScaffold(title: 'ชำระเงิน', art: 'payment', body: _PaidState(order: paid, printing: store.autoPrintReceipt));
    }
    if (store.cart.isEmpty) {
      return NvScaffold(
        title: 'ชำระเงิน',
        art: 'payment',
        body: NvEmptyState(
          mascot: 'empty',
          title: 'ไม่มีรายการรอชำระ',
          message: 'เพิ่มสินค้าในหน้าขายก่อน แล้วกด "ชำระเงิน"',
          actionLabel: 'กลับไปหน้าขาย',
          actionIcon: NvIcons.arrowLeft,
          onAction: () => context.go('/cashier'),
        ),
      );
    }
    final total = store.cartTotal;
    final where = store.orderType == OrderType.dineIn && store.tableNumber != null
        ? 'โต๊ะ ${store.tableNumber} · ${store.guests} ท่าน'
        : store.orderType.label;
    return NvScaffold(
      title: 'ชำระเงิน',
      eyebrow: 'ออเดอร์ ${store.openOrderId} · $where',
      art: 'payment',
      actions: [
        NvButton.ghost('แก้ไขรายการ',
            icon: NvIcons.arrowLeft, size: NvButtonSize.sm, onPressed: _busy ? null : () => context.go('/cashier')),
        NvButton.soft('พิมพ์ใบเสนอราคา',
            icon: NvIcons.print, size: NvButtonSize.sm, loading: _printingQuote, onPressed: _busy ? null : _printQuote),
      ],
      body: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 900;
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: (c.maxWidth * 0.36).clamp(320.0, 430.0), child: _Summary(store: store, fill: true)),
              const SizedBox(width: 16),
              Expanded(child: _work(store, total, fill: true)),
            ],
          );
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            _work(store, total, fill: false),
            const SizedBox(height: 16),
            _Summary(store: store, fill: false),
          ],
        );
      }),
    );
  }

  Widget _work(PosStore store, int total, {required bool fill}) {
    final banner = _blockBanner(store);
    final panel = NvSheet(
      padding: const EdgeInsets.all(18),
      child: switch (_method) {
        PaymentMethod.cash => _cashPanel(total),
        PaymentMethod.promptpay => _promptPanel(store, total),
        PaymentMethod.card => _cardPanel(total),
        PaymentMethod.wallet || PaymentMethod.thaiprompt => _walletPanel(total),
      },
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (banner != null) ...[banner, const SizedBox(height: 12)],
        Row(
          children: [
            for (var i = 0; i < _methods.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _MethodTile(
                  method: _methods[i],
                  selected: _method == _methods[i],
                  warn: _methods[i] == PaymentMethod.promptpay && !_promptReady(store),
                  enabled: total > 0 || _methods[i] == PaymentMethod.cash,
                  onTap: () => _select(_methods[i]),
                ),
              ),
            ],
          ],
        ),
        if (total > 0) ...[const SizedBox(height: 10), _TpRiderEntry(onTap: _busy ? null : _tpRider)],
        const SizedBox(height: 12),
        if (fill) Expanded(child: SingleChildScrollView(child: panel)) else panel,
        const SizedBox(height: 12),
        _confirmButton(store, total),
      ],
    );
  }

  Widget? _blockBanner(PosStore store) {
    final reason = store.checkoutBlockReason;
    if (reason.isEmpty) return null;
    final shift = _isShiftBlock(store);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: Nv.amberTint,
        borderRadius: BorderRadius.circular(Nv.rMd),
        border: Border.all(color: Nv.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(NvIcons.warning, size: 16, color: Nv.amber),
          const SizedBox(width: 10),
          Expanded(child: Text(reason, style: Nv.ui(13.5, color: const Color(0xFF8A5A00), weight: FontWeight.w600))),
          if (shift) NvButton.gold('เปิดกะ', icon: NvIcons.clock, size: NvButtonSize.sm, onPressed: () => _offerOpenShift(context)),
        ],
      ),
    );
  }

  Widget _confirmButton(PosStore store, int total) {
    final ok = _canConfirm(store, total);
    final label = switch (_method) {
      PaymentMethod.cash => total <= 0
          ? 'ปิดบิล ฿0'
          : _cash.isEmpty
              ? 'ใส่จำนวนเงินที่รับมา'
              : _tendered < total
                  ? 'เงินไม่พอ · ขาดอีก ${baht(total - _tendered)}'
                  : 'รับเงิน ${baht(_tendered)} · ทอน ${baht(_tendered - total)}',
      PaymentMethod.promptpay => 'ได้รับเงินแล้ว ${baht(total)}',
      PaymentMethod.card => _approval.text.trim().length == 6 ? 'ยืนยันชำระด้วยบัตร ${baht(total)}' : 'กรอกรหัสอนุมัติก่อนยืนยัน',
      PaymentMethod.wallet || PaymentMethod.thaiprompt => 'ยืนยันรับชำระ ${baht(total)}',
    };
    return NvButton.gold(
      label,
      icon: NvIcons.checkCircle,
      size: NvButtonSize.xl,
      expand: true,
      loading: _busy,
      onPressed: ok && !_busy ? _confirm : null,
    );
  }

  // ── method panels ──

  Widget _cashPanel(int total) {
    final entered = _cash.isNotEmpty;
    final t = _tendered;
    final change = t - total;
    final display = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Nv.paper,
        borderRadius: BorderRadius.circular(Nv.rMd),
        border: Border.all(color: Nv.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('รับเงินมา', style: Nv.ui(13, color: Nv.ink3, weight: FontWeight.w600)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(entered ? baht(t) : '฿0', style: Nv.money(40, color: entered ? Nv.ink : Nv.ink4)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(!entered || change >= 0 ? 'เงินทอน' : 'ขาดอีก',
                  style: Nv.ui(14, color: Nv.ink2, weight: FontWeight.w700)),
              const Spacer(),
              Text(
                entered ? baht(change.abs()) : '—',
                style: Nv.money(26, color: !entered ? Nv.ink4 : (change >= 0 ? Nv.jade : Nv.lacquer)),
              ),
            ],
          ),
        ],
      ),
    );
    final quick = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        NvButton.navy('พอดี ${baht(total)}', size: NvButtonSize.sm, onPressed: () => setState(() => _cash = '$total')),
        for (final q in _quickAmounts(total))
          NvButton.soft(baht(q), size: NvButtonSize.sm, onPressed: () => setState(() => _cash = '$q')),
      ],
    );
    final pad = _CashPad(onKey: _cashInput);
    return Focus(
      focusNode: _cashFocus,
      autofocus: true,
      onKeyEvent: _cashKey,
      child: LayoutBuilder(builder: (context, c) {
        final side = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            display,
            const SizedBox(height: 14),
            Text('ปุ่มด่วน', style: Nv.ui(13, color: Nv.ink3, weight: FontWeight.w600)),
            const SizedBox(height: 8),
            quick,
            const SizedBox(height: 10),
            Text('พิมพ์ตัวเลขด้วยคีย์บอร์ดได้ · Enter = ยืนยัน · Esc = ล้าง', style: Nv.ui(11.5, color: Nv.ink4)),
          ],
        );
        if (c.maxWidth >= 500) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 240, child: pad),
              const SizedBox(width: 18),
              Expanded(child: side),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [side, const SizedBox(height: 14), Center(child: SizedBox(width: 280, child: pad))],
        );
      }),
    );
  }

  Widget _promptPanel(PosStore store, int total) {
    final id = store.promptPayId;
    if (!_promptReady(store)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              NvArt.icon('promptpay', size: 60),
              const SizedBox(width: 12),
              Expanded(child: Text('ยังไม่ได้ตั้งค่าพร้อมเพย์ของร้าน', style: Nv.display(18))),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            id.isEmpty
                ? 'ตั้งหมายเลขพร้อมเพย์ของร้าน (เบอร์มือถือ / เลขประจำตัวผู้เสียภาษี 13 หลัก / e-Wallet ID 15 หลัก) ที่หน้าตั้งค่า เพื่อสร้าง QR รับเงินตามยอดจริงของแต่ละบิล'
                : 'หมายเลขพร้อมเพย์ที่ตั้งไว้ไม่ถูกต้อง กรุณาแก้ไขที่หน้าตั้งค่า',
            style: Nv.ui(13.5, color: Nv.ink2, height: 1.5),
          ),
          const SizedBox(height: 14),
          if (store.isManager)
            NvButton.gold('ไปตั้งค่าพร้อมเพย์', icon: NvIcons.settings, onPressed: () => context.go('/settings'))
          else
            Text('ให้ผู้จัดการตั้งค่าที่หน้า "ตั้งค่า" (ข้อมูลร้าน) หรือเลือกวิธีชำระอื่น', style: Nv.ui(13, color: Nv.ink3)),
        ],
      );
    }
    if (total <= 0) {
      return Text('ยอด ฿0 ไม่ต้องสแกน QR — เลือก "เงินสด" เพื่อปิดบิล', style: Nv.ui(14, color: Nv.ink2));
    }
    String? payload;
    try {
      payload = PromptPay.payload(id, amountBaht: total.toDouble());
    } on ArgumentError {
      payload = null;
    }
    if (payload == null) {
      return Text('สร้าง QR พร้อมเพย์ไม่ได้ — ตรวจหมายเลขพร้อมเพย์ที่หน้าตั้งค่า', style: Nv.ui(14, color: Nv.lacquer));
    }
    final data = payload;
    return LayoutBuilder(builder: (context, c) {
      final qrSize = (c.maxWidth * 0.42).clamp(180.0, 250.0);
      final qr = Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Nv.rLg),
          border: Border.all(color: Nv.line),
          boxShadow: Nv.shadowSheet,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('PromptPay', style: Nv.ui(14, color: Nv.sapphire, weight: FontWeight.w800)),
            QrImageView(
              data: data,
              version: QrVersions.auto,
              size: qrSize,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
              errorStateBuilder: (_, _) => SizedBox(
                width: qrSize,
                height: qrSize,
                child: Center(child: Text('สร้าง QR ไม่ได้', style: Nv.ui(13, color: Nv.lacquer))),
              ),
            ),
            Text(baht(total, decimals: true), style: Nv.money(20)),
          ],
        ),
      );
      final info = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('ให้ลูกค้าสแกนด้วยแอปธนาคาร', style: Nv.display(18)),
          const SizedBox(height: 8),
          NvKeyValue('พร้อมเพย์ร้าน', PromptPay.mask(id)),
          NvKeyValue('ชื่อร้าน', store.shopName, mono: false),
          NvKeyValue('ยอดชำระ', baht(total, decimals: true), strong: true),
          const SizedBox(height: 10),
          const _Step(n: 1, text: 'ลูกค้าสแกน QR แล้วตรวจชื่อบัญชีปลายทาง'),
          const _Step(n: 2, text: 'รอลูกค้าโอนสำเร็จ (ยอดถูกใส่ใน QR แล้ว)'),
          const _Step(n: 3, text: 'ตรวจยอดเงินเข้าในแอปของร้าน แล้วกด "ได้รับเงินแล้ว"'),
          const SizedBox(height: 6),
          Text('เครื่อง POS ไม่ได้เชื่อมต่อธนาคาร — ต้องตรวจยอดเงินเข้าเองทุกครั้ง',
              style: Nv.ui(12, color: Nv.amber, weight: FontWeight.w600)),
          const SizedBox(height: 10),
          TextField(
            controller: _ref,
            decoration: const InputDecoration(
              hintText: 'เลขอ้างอิงการโอน (ไม่บังคับ)',
              prefixIcon: Icon(NvIcons.receipt, size: 15),
            ),
          ),
        ],
      );
      if (c.maxWidth >= 560) {
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [qr, const SizedBox(width: 18), Expanded(child: info)]);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [Center(child: qr), const SizedBox(height: 14), info],
      );
    });
  }

  Widget _cardPanel(int total) {
    final code = _approval.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            NvArt.icon('card', size: 64),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('ทำรายการที่เครื่อง EDC', style: Nv.display(18)),
                  Text('POS นี้ไม่ได้เชื่อมต่อเครื่องรูดบัตรโดยตรง', style: Nv.ui(13, color: Nv.ink3)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Step(n: 1, text: 'ใส่ยอด ${baht(total, decimals: true)} ที่เครื่อง EDC'),
        const _Step(n: 2, text: 'ให้ลูกค้าแตะ / เสียบ / รูดบัตร แล้วรอสลิป'),
        const _Step(n: 3, text: 'กรอกรหัสอนุมัติ (Approval Code) 6 ตัวจากสลิป'),
        const SizedBox(height: 12),
        TextField(
          controller: _approval,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
            LengthLimitingTextInputFormatter(6),
            _UpperCaseFormatter(),
          ],
          style: Nv.money(22),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {
            if (_approval.text.trim().length == 6) _confirm();
          },
          decoration: const InputDecoration(
            labelText: 'รหัสอนุมัติ (Approval Code)',
            hintText: 'เช่น 123456',
            prefixIcon: Icon(NvIcons.key, size: 15),
          ),
        ),
        if (code.isNotEmpty && code.length < 6)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('ต้องมี 6 ตัว (ตอนนี้ ${code.length})', style: Nv.ui(12.5, color: Nv.lacquer, weight: FontWeight.w600)),
          ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: NvButton.ghost('เปิดหน้ารับชำระบัตร (EDC) เต็มจอ',
              icon: NvIcons.nfc, size: NvButtonSize.sm, onPressed: () => context.go('/payment/nfc')),
        ),
      ],
    );
  }

  Widget _walletPanel(int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            NvArt.icon('wallet', size: 64),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('รับชำระผ่านอีวอลเล็ท', style: Nv.display(18)),
                  Text('ให้ลูกค้าชำระผ่านแอปหรือเครื่องรับชำระของร้าน แล้วตรวจยอดเข้าก่อนยืนยัน',
                      style: Nv.ui(13, color: Nv.ink3, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        NvKeyValue('ยอดชำระ', baht(total, decimals: true), strong: true),
        const SizedBox(height: 12),
        TextField(
          controller: _ref,
          decoration: const InputDecoration(
            labelText: 'เลขอ้างอิงรายการ (ไม่บังคับ)',
            prefixIcon: Icon(NvIcons.receipt, size: 15),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── pieces ───────────────────────────

class _Summary extends StatelessWidget {
  final PosStore store;
  final bool fill;
  const _Summary({required this.store, required this.fill});

  @override
  Widget build(BuildContext context) {
    final s = store;
    final lines = [for (final l in s.cart) _SummaryLine(line: l)];
    final c = s.linkedCustomer;
    final tier = c == null ? null : s.tierFor(c);
    final points = tier == null ? 0 : (s.cartTotal * tier.pointsPer100 / 100).floor();
    final pct = (s.vatRate * 100).round();
    return NvSheet(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
        children: [
          NvSectionTitle('สรุปรายการ', icon: NvIcons.receipt, trailing: '${s.cartItemCount} ชิ้น'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              NvBadge(s.orderType.label, tint: NvTint.neutral, dot: false),
              if (s.orderType == OrderType.dineIn && s.tableNumber != null)
                NvBadge('โต๊ะ ${s.tableNumber} · ${s.guests} ท่าน', tint: NvTint.sapphire, icon: NvIcons.chair),
              if (c != null && tier != null) NvBadge('${c.name} · ${tier.name}', tint: NvTint.gold, icon: NvIcons.crown),
              if (s.activeTicketIds.isNotEmpty) NvBadge('บิลจากครัว ${s.activeTicketIds.join(', ')}', tint: NvTint.amber, dot: false),
            ],
          ),
          const SizedBox(height: 8),
          if (fill)
            Expanded(
              child: ListView.separated(
                itemCount: lines.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: Nv.lineSoft),
                itemBuilder: (_, i) => lines[i],
              ),
            )
          else
            ...lines,
          const Divider(height: 20, color: Nv.line),
          NvKeyValue('ยอดรวม', baht(s.cartSubtotal)),
          if (s.couponDiscount > 0)
            NvKeyValue('คูปอง ${s.appliedCouponCode}', '-${baht(s.couponDiscount)}', valueColor: Nv.jade),
          if (s.appliedPromotion != null && s.promoDiscount > 0)
            NvKeyValue('โปรโมชั่น · ${s.appliedPromotion!.name}', '-${baht(s.promoDiscount)}', valueColor: Nv.jade),
          if (tier != null && s.memberDiscount > 0)
            NvKeyValue('สมาชิก ${tier.name} -${tier.discountPercent}%', '-${baht(s.memberDiscount)}', valueColor: Nv.jade),
          if (s.vatEnabled) NvKeyValue(s.vatInclusive ? 'VAT $pct% (รวมในราคาแล้ว)' : 'VAT $pct%', baht(s.cartTax)),
          if (tier != null && points > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('${c!.name} จะได้รับ ${groupDigits(points)} แต้มจากบิลนี้',
                  style: Nv.ui(12, color: Nv.jade, weight: FontWeight.w600)),
            ),
          const SizedBox(height: 12),
          NvNightCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            radius: Nv.rMd,
            child: Row(
              children: [
                Text('ยอดที่ต้องชำระ', style: Nv.ui(14, color: Nv.onNight2, weight: FontWeight.w600)),
                const SizedBox(width: 10),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: NvFoilText(baht(s.cartTotal), style: Nv.money(32)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final CartLine line;
  const _SummaryLine({required this.line});

  @override
  Widget build(BuildContext context) {
    final detail = [...line.options, if (line.note.isNotEmpty) line.note].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 38, child: Text('${line.qty}×', style: Nv.money(13.5, color: Nv.ink3, weight: FontWeight.w600))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(line.product.name, style: Nv.ui(14, weight: FontWeight.w600)),
                if (detail.isNotEmpty) Text(detail, style: Nv.ui(12, color: Nv.ink3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(baht(line.lineTotal), style: Nv.money(14)),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final PaymentMethod method;
  final bool selected;
  final bool warn;
  final bool enabled;
  final VoidCallback onTap;
  const _MethodTile({required this.method, required this.selected, required this.warn, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: NvSheet(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
        radius: Nv.rMd,
        selected: selected,
        onTap: enabled ? onTap : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: NvArt.icon(method.art, size: 50)),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(method.label,
                      style: Nv.ui(13, color: selected ? Nv.ink : Nv.ink2, weight: selected ? FontWeight.w700 : FontWeight.w600)),
                ),
              ],
            ),
            if (warn)
              const Positioned(
                top: -4,
                right: -2,
                child: Tooltip(message: 'ยังไม่ได้ตั้งค่า', child: Icon(NvIcons.warning, size: 13, color: Nv.amber)),
              ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int n;
  final String text;
  const _Step({required this.n, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: Nv.btnGold),
              child: Text('$n', style: Nv.money(11.5, color: const Color(0xFF1A1405))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: Nv.ui(13.5, color: Nv.ink2, height: 1.4))),
          ],
        ),
      );
}

class _CashPad extends StatelessWidget {
  final ValueChanged<String> onKey;
  const _CashPad({required this.onKey});

  @override
  Widget build(BuildContext context) {
    Widget key(String label, {IconData? icon, String? value, bool soft = false}) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: SizedBox(
              height: 54,
              child: Material(
                color: soft ? Nv.ivoryDeep : Nv.paper,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Nv.rMd),
                  side: const BorderSide(color: Nv.line),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onKey(value ?? label),
                  child: Center(
                    child: icon != null
                        ? Icon(icon, size: 18, color: Nv.ink2)
                        : Text(label, style: Nv.money(22, weight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          ),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [key('1'), key('2'), key('3')]),
        Row(children: [key('4'), key('5'), key('6')]),
        Row(children: [key('7'), key('8'), key('9')]),
        Row(children: [key('00'), key('0'), key('', icon: NvIcons.backspace, value: 'back', soft: true)]),
        Padding(
          padding: const EdgeInsets.all(4),
          child: NvButton.soft('ล้างจำนวน', icon: NvIcons.xmark, size: NvButtonSize.sm, expand: true, onPressed: () => onKey('clear')),
        ),
      ],
    );
  }
}

class _PaidState extends StatelessWidget {
  final Order order;
  final bool printing;
  const _PaidState({required this.order, required this.printing});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NvArt.mascot('cheer', height: 160),
            const SizedBox(height: 10),
            Text('ชำระเงินสำเร็จ · ${order.id}', style: Nv.display(22)),
            const SizedBox(height: 4),
            Text(printing ? 'กำลังพิมพ์ใบเสร็จ…' : 'กำลังเปิดใบเสร็จ…', style: Nv.ui(14, color: Nv.ink3)),
            const SizedBox(height: 14),
            const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.4)),
            const SizedBox(height: 16),
            NvButton.gold('ดูใบเสร็จ', icon: NvIcons.receipt, onPressed: () => context.go('/receipt?id=${order.id}')),
          ],
        ),
      ),
    );
  }
}

/// "ส่งด้วยไรเดอร์ Thai Prompt" — the customer pays in the Thai Prompt app.
class _TpRiderEntry extends StatelessWidget {
  final VoidCallback? onTap;
  const _TpRiderEntry({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NvSheet(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      radius: Nv.rMd,
      onTap: onTap,
      child: Row(
        children: [
          NvArt.icon('delivery', size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ส่งด้วยไรเดอร์ Thai Prompt', style: Nv.ui(14.5, weight: FontWeight.w700)),
                Text('ลูกค้าสแกน QR จ่ายค่าสินค้า + ค่าส่งในแอป Thai Prompt',
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.ui(12, color: Nv.ink3)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(NvIcons.angleRight, size: 13, color: Nv.ink4),
        ],
      ),
    );
  }
}
