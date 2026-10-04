// Thaiprompt POS — Card / EDC payment (/payment/nfc).
//
// An honest external-terminal flow: the POS does not read cards itself and
// gets no result back from the EDC, so the cashier keys the amount on the
// EDC, the customer taps / inserts the card there, and the approval code from
// the slip (required) plus optional last-4 digits are recorded with the sale
// as the payment reference. Nothing is marked paid without that code.
//
// by xman studio

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../models/extra_models.dart';
import '../models/order_models.dart';
import '../print/print_actions.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';

bool _isShiftBlock(PosStore s) =>
    s.cart.isNotEmpty &&
    s.currentStaff != null &&
    s.currentStaff!.role.canSell &&
    s.requireShift &&
    !s.hasOpenShift;

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

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}

class NfcScanScreen extends StatefulWidget {
  const NfcScanScreen({super.key});

  @override
  State<NfcScanScreen> createState() => _NfcScanScreenState();
}

class _NfcScanScreenState extends State<NfcScanScreen> {
  final _code = TextEditingController();
  final _last4 = TextEditingController();
  bool _busy = false;
  Order? _paid;

  @override
  void dispose() {
    _code.dispose();
    _last4.dispose();
    super.dispose();
  }

  String get _approval => _code.text.trim().toUpperCase();
  String get _digits => _last4.text.trim();
  bool get _codeOk => _approval.length >= 6 && _approval.length <= 12;
  bool get _last4Ok => _digits.isEmpty || _digits.length == 4;

  Future<void> _confirm() async {
    if (_busy) return;
    final store = AppScope.read(context);
    if (store.cart.isEmpty) return;
    if (!_codeOk) {
      nvToast(context, 'กรอกรหัสอนุมัติจากสลิปเครื่อง EDC (อย่างน้อย 6 ตัว)', kind: NvToastKind.warning);
      return;
    }
    if (!_last4Ok) {
      nvToast(context, 'เลขท้ายบัตรต้องมี 4 หลัก หรือเว้นว่างไว้', kind: NvToastKind.warning);
      return;
    }
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
    setState(() => _busy = true);
    final ref = 'EDC $_approval${_digits.isNotEmpty ? ' · ****$_digits' : ''}';
    final order = store.checkout(method: PaymentMethod.card, paymentRef: ref);
    if (order == null) {
      setState(() => _busy = false);
      final r = store.checkoutBlockReason;
      nvToast(context, r.isNotEmpty ? r : 'บันทึกการชำระไม่สำเร็จ', kind: NvToastKind.error);
      return;
    }
    setState(() => _paid = order);
    if (store.autoPrintReceipt) {
      await printReceipt(context, order, quiet: true);
      if (!mounted) return;
    }
    context.go('/receipt?id=${order.id}');
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final paid = _paid;
    if (paid != null) {
      return NvScaffold(
        title: 'รับชำระบัตร (EDC)',
        art: 'nfc',
        body: NvEmptyState(
          mascot: 'cheer',
          title: 'บันทึกการชำระด้วยบัตรแล้ว · ${paid.id}',
          message: store.autoPrintReceipt ? 'กำลังพิมพ์ใบเสร็จ…' : 'กำลังเปิดใบเสร็จ…',
          actionLabel: 'ดูใบเสร็จ',
          actionIcon: NvIcons.receipt,
          onAction: () => context.go('/receipt?id=${paid.id}'),
        ),
      );
    }
    if (store.cart.isEmpty) {
      return NvScaffold(
        title: 'รับชำระบัตร (EDC)',
        art: 'nfc',
        body: NvEmptyState(
          mascot: 'empty',
          title: 'ไม่มียอดรอชำระ',
          message: 'เพิ่มสินค้าในหน้าขายก่อน แล้วเลือกชำระด้วยบัตร',
          actionLabel: 'ไปหน้าขาย',
          actionIcon: NvIcons.cashier,
          onAction: () => context.go('/cashier'),
        ),
      );
    }
    final total = store.cartTotal;
    return NvScaffold(
      title: 'รับชำระบัตร (EDC)',
      eyebrow: 'ออเดอร์ ${store.openOrderId}',
      art: 'nfc',
      actions: [
        NvButton.ghost('วิธีชำระอื่น',
            icon: NvIcons.arrowLeft, size: NvButtonSize.sm, onPressed: _busy ? null : () => context.go('/payment')),
        NvButton.soft('แก้ไขรายการ', icon: NvIcons.edit, size: NvButtonSize.sm, onPressed: _busy ? null : () => context.go('/cashier')),
      ],
      body: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 860;
        final hero = _Hero(store: store, total: total, compact: !wide);
        final form = _form(store, total);
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: SingleChildScrollView(child: hero)),
              const SizedBox(width: 18),
              SizedBox(width: (c.maxWidth * 0.4).clamp(360.0, 460.0), child: SingleChildScrollView(child: form)),
            ],
          );
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [hero, const SizedBox(height: 16), form],
        );
      }),
    );
  }

  Widget _form(PosStore store, int total) {
    final code = _approval;
    final shiftBlocked = _isShiftBlock(store);
    final otherBlock = !shiftBlocked && store.checkoutBlockReason.isNotEmpty ? store.checkoutBlockReason : null;
    return NvSheet(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const NvSectionTitle('บันทึกผลจากสลิป EDC', icon: NvIcons.receipt),
          TextField(
            controller: _code,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(12),
              _UpperCaseFormatter(),
            ],
            style: Nv.money(22),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (_codeOk && _last4Ok) _confirm();
            },
            decoration: const InputDecoration(
              labelText: 'รหัสอนุมัติ (Approval Code) *',
              hintText: 'เช่น 123456',
              prefixIcon: Icon(NvIcons.key, size: 15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              code.isNotEmpty && !_codeOk ? 'ต้องมีอย่างน้อย 6 ตัว (ตอนนี้ ${code.length})' : 'พิมพ์ตามที่สลิปแสดง "APPR CODE" หรือ "รหัสอนุมัติ"',
              style: Nv.ui(12, color: code.isNotEmpty && !_codeOk ? Nv.lacquer : Nv.ink3, weight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _last4,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
            style: Nv.money(18),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (_codeOk && _last4Ok) _confirm();
            },
            decoration: const InputDecoration(
              labelText: 'เลขท้ายบัตร 4 หลัก (ไม่บังคับ)',
              hintText: '1234',
              prefixIcon: Icon(NvIcons.creditCard, size: 15),
            ),
          ),
          if (!_last4Ok)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text('ต้องมี 4 หลัก หรือเว้นว่างไว้', style: Nv.ui(12, color: Nv.lacquer, weight: FontWeight.w600)),
            ),
          const SizedBox(height: 16),
          if (shiftBlocked || otherBlock != null) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              decoration: BoxDecoration(
                color: Nv.amberTint,
                borderRadius: BorderRadius.circular(Nv.rMd),
                border: Border.all(color: Nv.amber.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(NvIcons.warning, size: 15, color: Nv.amber),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(otherBlock ?? store.checkoutBlockReason,
                        style: Nv.ui(13, color: const Color(0xFF8A5A00), weight: FontWeight.w600)),
                  ),
                  if (shiftBlocked)
                    NvButton.gold('เปิดกะ', icon: NvIcons.clock, size: NvButtonSize.sm, onPressed: () => _offerOpenShift(context)),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          NvButton.gold(
            _codeOk ? 'ยืนยันรับชำระ ${baht(total)}' : 'กรอกรหัสอนุมัติก่อนยืนยัน',
            icon: NvIcons.checkCircle,
            size: NvButtonSize.xl,
            expand: true,
            loading: _busy,
            onPressed: _codeOk && _last4Ok && !_busy ? _confirm : null,
          ),
          const SizedBox(height: 10),
          Text(
            'ถ้าเครื่อง EDC ปฏิเสธรายการ ห้ามกดยืนยัน — กด "วิธีชำระอื่น" เพื่อเปลี่ยนวิธีชำระ',
            textAlign: TextAlign.center,
            style: Nv.ui(12, color: Nv.ink3, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final PosStore store;
  final int total;
  final bool compact;
  const _Hero({required this.store, required this.total, required this.compact});

  @override
  Widget build(BuildContext context) {
    final c = store.linkedCustomer;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Nv.rXl),
      child: Container(
        decoration: BoxDecoration(
          gradient: Nv.night,
          borderRadius: BorderRadius.circular(Nv.rXl),
          border: Border.all(color: Nv.lineNightStrong),
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(compact ? 18 : 28, 22, compact ? 18 : 28, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      NvArt.icon('card', size: compact ? 84 : 110),
                      const SizedBox(width: 6),
                      NvArt.icon('nfc', size: compact ? 70 : 92),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('ยอดที่ต้องชำระด้วยบัตร', style: Nv.ui(13, color: Nv.onNight3, weight: FontWeight.w600)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: NvFoilText(baht(total, decimals: true), style: Nv.money(compact ? 38 : 48)),
                  ),
                  Text(
                    '${store.cartItemCount} ชิ้น${c != null ? ' · สมาชิก ${c.name}' : ''}${store.cartDiscount > 0 ? ' · ส่วนลด ${baht(store.cartDiscount)}' : ''}',
                    textAlign: TextAlign.center,
                    style: Nv.ui(12.5, color: Nv.onNight3),
                  ),
                  const SizedBox(height: 14),
                  const NvKanokDivider(width: 220, thin: true, opacity: 0.8),
                  const SizedBox(height: 12),
                  _NightStep(n: 1, text: 'ใส่ยอด ${baht(total, decimals: true)} ที่เครื่อง EDC'),
                  const _NightStep(n: 2, text: 'ให้ลูกค้าแตะบัตร / มือถือ (NFC) หรือเสียบ / รูดบัตรที่เครื่อง EDC'),
                  const _NightStep(n: 3, text: 'เมื่อสลิปขึ้นว่า "อนุมัติ" ให้กรอกรหัสอนุมัติแล้วกดยืนยัน'),
                  const SizedBox(height: 12),
                  Text(
                    'เครื่อง POS ไม่ได้อ่านบัตรเอง และไม่ได้รับผลจากเครื่อง EDC อัตโนมัติ — บันทึกการชำระเฉพาะเมื่อสลิปแสดงว่าอนุมัติแล้วเท่านั้น',
                    textAlign: TextAlign.center,
                    style: Nv.ui(12, color: Nv.onNight3, height: 1.45),
                  ),
                ],
              ),
            ),
            const NvKanokCorners(size: 64, opacity: 0.55, inset: EdgeInsets.all(4)),
          ],
        ),
      ),
    );
  }
}

class _NightStep extends StatelessWidget {
  final int n;
  final String text;
  const _NightStep({required this.n, required this.text});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: Nv.btnGold, boxShadow: Nv.goldGlow(0.5)),
                child: Text('$n', style: Nv.money(12, color: const Color(0xFF1A1405))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: Nv.ui(14, color: Nv.onNight, height: 1.45))),
            ],
          ),
        ),
      );
}
