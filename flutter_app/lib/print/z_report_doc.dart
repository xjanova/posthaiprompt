// Thaiprompt POS — Z-Report (shift close-out) for 58/80 mm thermal rolls.
//
// A pure black-on-white widget (no AppScope) rendered offscreen by
// PrintService and shown as the on-screen preview. Everything comes from the
// closed Shift snapshot the store took at close time (sales by method,
// refunds, drawer movements, expected vs counted cash, variance), so a
// reprint months later shows exactly what was closed.
//
// by xman studio

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../models/extra_models.dart';
import '../models/order_models.dart';
import '../theme/nv_tokens.dart';
import 'receipt_doc.dart' show ShopInfo;

class ZReportDoc extends StatelessWidget {
  final Shift shift;
  final ShopInfo shop;
  final bool narrow; // 58 mm
  final bool reprint;
  final DateTime? printedAt;

  const ZReportDoc({
    super.key,
    required this.shift,
    required this.shop,
    this.narrow = false,
    this.reprint = false,
    this.printedAt,
  });

  /// Assets the doc draws (none — text only).
  static const precache = <String>[];

  static String zLabel(Shift s) => 'Z#${s.zNumber.toString().padLeft(4, '0')}';

  static String _duration(DateTime a, DateTime b) {
    final d = b.difference(a);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return h > 0 ? '$h ชม. $m นาที' : '$m นาที';
  }

  @override
  Widget build(BuildContext context) {
    final fs = narrow ? 17.0 : 20.0;
    TextStyle t([double k = 1, FontWeight w = FontWeight.w400]) =>
        TextStyle(fontFamily: Nv.fontUi, fontSize: fs * k, fontWeight: w, color: Colors.black, height: 1.3);
    TextStyle m([double k = 1, FontWeight w = FontWeight.w500]) => TextStyle(
          fontFamily: Nv.fontMono,
          fontFamilyFallback: Nv.monoFallback,
          fontSize: fs * k,
          fontWeight: w,
          color: Colors.black,
          fontFeatures: Nv.tnum,
          height: 1.3,
        );

    Widget row(String l, String r, {bool bold = false, double k = 1}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(l, style: t(k, bold ? FontWeight.w700 : FontWeight.w400))),
              const SizedBox(width: 8),
              Text(r, style: m(k, bold ? FontWeight.w700 : FontWeight.w500)),
            ],
          ),
        );

    Widget dash() => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: LayoutBuilder(
            builder: (_, c) => Text('-' * (c.maxWidth / (fs * 0.6)).floor(),
                maxLines: 1, overflow: TextOverflow.clip, style: m(1, FontWeight.w400)),
          ),
        );

    Widget head(String s) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(s, style: t(1.05, FontWeight.w700)),
        );

    final s = shift;
    final closed = s.closedAt;
    final expected = s.expectedCash ?? 0;
    final counted = s.countedCash ?? expected;
    final variance = counted - expected;
    final net = s.salesTotal - s.refundTotal;
    final cashNet = s.byMethod[PaymentMethod.cash.name] ?? 0;
    final varianceText = variance == 0 ? 'ตรง' : (variance > 0 ? 'เกิน ${baht(variance, decimals: true)}' : 'ขาด ${baht(-variance, decimals: true)}');

    return Padding(
      padding: EdgeInsets.fromLTRB(narrow ? 10 : 16, 18, narrow ? 10 : 16, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(shop.name, textAlign: TextAlign.center, style: t(1.35, FontWeight.w700)),
          Text(shop.branch, textAlign: TextAlign.center, style: t(0.95)),
          if (shop.terminalId.isNotEmpty) Text('POS ID ${shop.terminalId}', textAlign: TextAlign.center, style: t(0.8)),
          const SizedBox(height: 8),
          Text('รายงานปิดกะ (Z-Report)', textAlign: TextAlign.center, style: t(1.1, FontWeight.w700)),
          Text(zLabel(s), textAlign: TextAlign.center, style: m(1.3, FontWeight.w700)),
          if (reprint) Text('** สำเนา (พิมพ์ซ้ำ) **', textAlign: TextAlign.center, style: t(0.95, FontWeight.w700)),
          dash(),
          row('เปิดกะ', thaiDateTime(s.openedAt)),
          row('ปิดกะ', closed == null ? '—' : thaiDateTime(closed)),
          if (closed != null) row('ระยะเวลา', _duration(s.openedAt, closed)),
          row('พนักงานเปิดกะ', s.cashier),
          if (s.closedBy.isNotEmpty) row('ปิดกะโดย', s.closedBy),
          dash(),
          head('สรุปยอดขาย'),
          row('จำนวนบิล', groupDigits(s.orderCount)),
          row('ยอดขายรวม', baht(s.salesTotal, decimals: true)),
          row('คืนเงิน', s.refundTotal == 0 ? baht(0, decimals: true) : '-${baht(s.refundTotal, decimals: true)}'),
          row('ยอดขายสุทธิ', baht(net, decimals: true), bold: true, k: 1.15),
          const SizedBox(height: 6),
          head('แยกตามช่องทาง (สุทธิ)'),
          for (final pm in PaymentMethod.values) row(pm.receiptLabel, baht(s.byMethod[pm.name] ?? 0, decimals: true)),
          dash(),
          head('เงินสดในลิ้นชัก'),
          row('เงินทอนตั้งต้น', baht(s.openingCash, decimals: true)),
          row('ขายเงินสด (สุทธิ)', baht(cashNet, decimals: true)),
          for (final mv in s.movements)
            row(
              '${mv.type.label}${mv.reason.isNotEmpty ? ' · ${mv.reason}' : ''} (${hm(mv.at)})',
              '${mv.type.sign > 0 ? '+' : '-'}${baht(mv.amount, decimals: true)}',
              k: 0.9,
            ),
          if (s.movements.isEmpty) row('เงินเข้า–ออก', baht(0, decimals: true)),
          const SizedBox(height: 4),
          row('ยอดที่ควรมี', baht(expected, decimals: true), bold: true),
          row('นับได้จริง', baht(counted, decimals: true), bold: true),
          row('ส่วนต่าง', varianceText, bold: true, k: 1.1),
          if (s.note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('หมายเหตุ: ${s.note}', style: t(0.9)),
          ],
          dash(),
          const SizedBox(height: 18),
          Text('ลงชื่อผู้ปิดกะ ..............................', style: t(0.95)),
          const SizedBox(height: 18),
          Text('ลงชื่อผู้ตรวจสอบ ..........................', style: t(0.95)),
          const SizedBox(height: 14),
          Text('พิมพ์เมื่อ ${thaiDateTime(printedAt ?? DateTime.now())}', textAlign: TextAlign.center, style: t(0.8)),
          Text('Thai Prompt POS · thaiprompt.online', textAlign: TextAlign.center, style: t(0.75)),
        ],
      ),
    );
  }
}
