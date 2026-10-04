// Thaiprompt POS — Profit & loss summary + printable A4 statement.
//
// PnlSummary — one place that turns a list of settled orders into the numbers
//   the dashboard and the accounting screen show (and print). It starts from
//   `PosStore.summarize` and adds what a P&L needs on top: VAT that left again
//   with refunds (so a fully refunded bill nets to zero), VAT charged on top of
//   exclusive prices, per-day rows, and which sold lines had no unit cost.
// PnlDoc — pure black-on-white A4 statement (no AppScope) rendered offscreen
//   by PrintService for printing / PDF sharing.
//
// by xman studio

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../models/order_models.dart';
import '../state/pos_store.dart';
import '../theme/nv_tokens.dart';
import 'receipt_doc.dart' show ShopInfo;

/// One day (or month, when grouped) of the sales journal.
class PnlDay {
  final DateTime day;
  int bills = 0; // paid bills (incl. partially refunded)
  int gross = 0; // before discounts
  int discounts = 0;
  int addOnVat = 0; // VAT charged on top of exclusive prices
  int refunds = 0;
  int vat = 0; // output VAT net of refunds
  int net = 0; // money kept, incl. VAT

  PnlDay(this.day);

  int get exVat => net - vat;

  void add(PnlDay o) {
    bills += o.bills;
    gross += o.gross;
    discounts += o.discounts;
    addOnVat += o.addOnVat;
    refunds += o.refunds;
    vat += o.vat;
    net += o.net;
  }
}

class PnlSummary {
  final DateTime from;
  final DateTime to; // exclusive
  final int bills; // paid bills (status paid, incl. partial refunds)
  final int refundedBills; // bills fully refunded
  final int partialRefundBills;
  final int items; // pieces sold (net of refunds)
  final int gross;
  final int discounts;
  final int addOnVat;
  final int refunds;
  final int net;
  final int vatCharged;
  final int vatOnRefunds;
  final int cogs;
  final int missingCostLines;
  final List<String> missingCostNames;
  final List<PnlDay> days;

  const PnlSummary({
    required this.from,
    required this.to,
    required this.bills,
    required this.refundedBills,
    required this.partialRefundBills,
    required this.items,
    required this.gross,
    required this.discounts,
    required this.addOnVat,
    required this.refunds,
    required this.net,
    required this.vatCharged,
    required this.vatOnRefunds,
    required this.cogs,
    required this.missingCostLines,
    required this.missingCostNames,
    required this.days,
  });

  /// Output VAT that stays with the shop (charged − refunded share).
  int get vat => vatCharged - vatOnRefunds;

  /// Revenue before VAT.
  int get revenueExVat => net - vat;

  int get profit => revenueExVat - cogs;

  double get marginPct => revenueExVat > 0 ? profit * 100 / revenueExVat : 0;

  int get avgBill => bills == 0 ? 0 : (net / bills).round();

  bool get isEmpty => bills == 0 && refundedBills == 0;

  /// VAT on [o] that remains after its refunds.
  static int vatKept(Order o) {
    if (o.tax <= 0 || o.total <= 0) return 0;
    if (o.status == OrderStatus.refunded || o.refundAmount >= o.total) return 0;
    final back = (o.refundAmount * o.tax / o.total).round();
    return (o.tax - back).clamp(0, o.tax);
  }

  factory PnlSummary.of(PosStore store, List<Order> list, {required DateTime from, required DateTime to}) {
    final s = store.summarize(list);
    var bills = 0, refundedBills = 0, partial = 0, items = 0, addOn = 0, vatBack = 0, missing = 0;
    final missingNames = <String>{};
    final byDay = <DateTime, PnlDay>{};
    for (final o in list) {
      if (o.status != OrderStatus.paid && o.status != OrderStatus.refunded) continue;
      final day = DateTime(o.createdAt.year, o.createdAt.month, o.createdAt.day);
      final d = byDay.putIfAbsent(day, () => PnlDay(day));
      final kept = vatKept(o);
      final onTop = (o.total - (o.subtotal - o.discount)).clamp(0, o.total);
      if (o.status == OrderStatus.paid) {
        bills++;
        d.bills++;
        if (o.refundAmount > 0) partial++;
      } else {
        refundedBills++;
      }
      vatBack += o.tax - kept;
      addOn += onTop;
      d.gross += o.subtotal;
      d.discounts += o.discount;
      d.addOnVat += onTop;
      d.refunds += o.refundAmount;
      d.vat += kept;
      d.net += o.total - o.refundAmount;
      for (final l in o.lines) {
        final q = l.qty - l.refundedQty;
        if (q <= 0) continue;
        items += q;
        if (l.cost <= 0) {
          missing++;
          missingNames.add(l.name);
        }
      }
    }
    final days = byDay.values.toList()..sort((a, b) => a.day.compareTo(b.day));
    return PnlSummary(
      from: from,
      to: to,
      bills: bills,
      refundedBills: refundedBills,
      partialRefundBills: partial,
      items: items,
      gross: s.gross,
      discounts: s.discounts,
      addOnVat: addOn,
      refunds: s.refunds,
      net: s.net,
      vatCharged: s.tax,
      vatOnRefunds: vatBack,
      cogs: s.cogs,
      missingCostLines: missing,
      missingCostNames: missingNames.toList()..sort(),
      days: days,
    );
  }

  /// Journal rows for print: per day, or per month when the range is long.
  List<({String label, PnlDay d})> journalRows({int maxDays = 31}) {
    if (days.length <= maxDays) {
      return [for (final d in days) (label: thaiDate(d.day), d: d)];
    }
    final months = <DateTime, PnlDay>{};
    for (final d in days) {
      final k = DateTime(d.day.year, d.day.month);
      months.putIfAbsent(k, () => PnlDay(k)).add(d);
    }
    final keys = months.keys.toList()..sort();
    return [for (final k in keys) (label: '${thaiMonthShort(k.month)} ${beYear(k)}', d: months[k]!)];
  }
}

/// A4 profit & loss statement (black on white, 794 px wide = A4 @ 96 dpi).
class PnlDoc extends StatelessWidget {
  final PnlSummary summary;
  final ShopInfo shop;
  final DateTime printedAt;
  final String printedBy;

  const PnlDoc({super.key, required this.summary, required this.shop, required this.printedAt, required this.printedBy});

  /// A4 height at the doc's render width (keeps content top-aligned on the page).
  static const double pageHeight = 1123;

  @override
  Widget build(BuildContext context) {
    TextStyle t(double size, [FontWeight w = FontWeight.w400]) =>
        TextStyle(fontFamily: Nv.fontUi, fontSize: size, fontWeight: w, color: Colors.black, height: 1.35);
    TextStyle m(double size, [FontWeight w = FontWeight.w500]) => TextStyle(
        fontFamily: Nv.fontMono,
        fontFamilyFallback: Nv.monoFallback,
        fontSize: size,
        fontWeight: w,
        color: Colors.black,
        fontFeatures: Nv.tnum,
        height: 1.35);

    final s = summary;
    final lastDay = s.to.subtract(const Duration(days: 1));
    final rows = s.journalRows();
    final grouped = s.days.length > 31;

    Widget line(String label, int amount, {bool strong = false, bool minus = false, String? note}) => Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: strong
              ? const BoxDecoration(border: Border(top: BorderSide(color: Colors.black, width: 1)))
              : const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFDDDDDD), width: 0.6))),
          child: Row(
            children: [
              Expanded(
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: label, style: t(13, strong ? FontWeight.w700 : FontWeight.w400)),
                  if (note != null) TextSpan(text: '  $note', style: t(10.5)),
                ])),
              ),
              Text(minus && amount != 0 ? baht(-amount, decimals: true) : baht(amount, decimals: true),
                  style: m(13, strong ? FontWeight.w700 : FontWeight.w500)),
            ],
          ),
        );

    Widget cell(String v, {bool head = false, bool right = true}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
          child: Text(v,
              textAlign: right ? TextAlign.right : TextAlign.left,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: head ? t(10.5, FontWeight.w700) : m(10.5, FontWeight.w400)),
        );

    String n(int v) => groupDigits(v);

    final total = PnlDay(s.from);
    for (final r in rows) {
      total.add(r.d);
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: pageHeight),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(44, 40, 44, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shop.name, style: t(20, FontWeight.w700)),
                      Text(shop.branch, style: t(12.5)),
                      if (shop.address.isNotEmpty) Text(shop.address, style: t(11)),
                      if (shop.phone.isNotEmpty) Text('โทร ${phoneFmt(shop.phone)}', style: t(11)),
                      if (shop.taxId.isNotEmpty) Text('เลขประจำตัวผู้เสียภาษี ${shop.taxId}', style: t(11)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('งบกำไรขาดทุน (อย่างย่อ)', style: t(17, FontWeight.w700)),
                    Text('${thaiDate(s.from)} – ${thaiDate(lastDay)}', style: m(12)),
                    Text('พิมพ์เมื่อ ${thaiDateTime(printedAt)}', style: t(10.5)),
                    Text('โดย $printedBy', style: t(10.5)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(height: 1.4, color: Colors.black),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('กำไรขาดทุน', style: t(14, FontWeight.w700)),
                      const SizedBox(height: 4),
                      line('ยอดขายรวม (ก่อนส่วนลด)', s.gross),
                      line('หัก ส่วนลด', s.discounts, minus: true),
                      if (s.addOnVat != 0) line('บวก VAT ที่เรียกเก็บเพิ่มจากราคา', s.addOnVat),
                      line('หัก คืนเงิน', s.refunds, minus: true),
                      line('ยอดขายสุทธิ (รวม VAT)', s.net, strong: true),
                      line('หัก ภาษีขาย (VAT)', s.vat, minus: true),
                      line('รายได้ก่อนภาษี', s.revenueExVat, strong: true),
                      line('หัก ต้นทุนขาย (COGS)', s.cogs, minus: true),
                      line('กำไรขั้นต้น', s.profit, strong: true, note: 'อัตรากำไร ${s.marginPct.toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 0.8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('สรุป', style: t(13, FontWeight.w700)),
                        const SizedBox(height: 4),
                        _kv('จำนวนบิล', '${n(s.bills)} บิล', t, m),
                        _kv('บิลที่คืนทั้งบิล', '${n(s.refundedBills)} บิล', t, m),
                        _kv('บิลที่คืนบางส่วน', '${n(s.partialRefundBills)} บิล', t, m),
                        _kv('สินค้าที่ขาย', '${n(s.items)} ชิ้น', t, m),
                        _kv('เฉลี่ยต่อบิล', baht(s.avgBill), t, m),
                        _kv('VAT เรียกเก็บ', baht(s.vatCharged), t, m),
                        _kv('VAT คืนตามการคืนเงิน', baht(s.vatOnRefunds), t, m),
                        _kv('ภาษีขายสุทธิ', baht(s.vat), t, m),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(grouped ? 'สมุดรายวันขาย / ภาษีขาย (สรุปรายเดือน)' : 'สมุดรายวันขาย / ภาษีขาย (รายวัน)', style: t(14, FontWeight.w700)),
            const SizedBox(height: 6),
            if (rows.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('ไม่มีรายการขายในช่วงนี้', style: t(12)))
            else
              Table(
                border: const TableBorder(
                  top: BorderSide(color: Colors.black, width: 1),
                  bottom: BorderSide(color: Colors.black, width: 1),
                  horizontalInside: BorderSide(color: Color(0xFFDDDDDD), width: 0.6),
                ),
                columnWidths: const {
                  0: FlexColumnWidth(1.5),
                  1: FlexColumnWidth(0.7),
                  2: FlexColumnWidth(1.3),
                  3: FlexColumnWidth(1.1),
                  4: FlexColumnWidth(1.1),
                  5: FlexColumnWidth(1.3),
                  6: FlexColumnWidth(1.1),
                  7: FlexColumnWidth(1.3),
                },
                children: [
                  TableRow(children: [
                    cell(grouped ? 'เดือน' : 'วันที่', head: true, right: false),
                    cell('บิล', head: true),
                    cell('ยอดขายรวม', head: true),
                    cell('ส่วนลด', head: true),
                    cell('คืนเงิน', head: true),
                    cell('ก่อน VAT', head: true),
                    cell('VAT', head: true),
                    cell('สุทธิ', head: true),
                  ]),
                  for (final r in rows)
                    TableRow(children: [
                      cell(r.label, right: false),
                      cell(n(r.d.bills)),
                      cell(n(r.d.gross)),
                      cell(n(r.d.discounts)),
                      cell(n(r.d.refunds)),
                      cell(n(r.d.exVat)),
                      cell(n(r.d.vat)),
                      cell(n(r.d.net)),
                    ]),
                  TableRow(
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.black, width: 1))),
                    children: [
                      cell('รวม', head: true, right: false),
                      cell(n(total.bills), head: true),
                      cell(n(total.gross), head: true),
                      cell(n(total.discounts), head: true),
                      cell(n(total.refunds), head: true),
                      cell(n(total.exVat), head: true),
                      cell(n(total.vat), head: true),
                      cell(n(total.net), head: true),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 14),
            Text(
              'หมายเหตุ: จำนวนเงินเป็นบาท · คืนเงินนับตามวันที่ของบิล · ต้นทุนใช้ราคาทุน ณ เวลาขาย'
              '${s.missingCostLines > 0 ? ' · มี ${n(s.missingCostLines)} รายการที่ขายโดยไม่มีต้นทุน (กำไรอาจสูงกว่าความจริง)' : ''}',
              style: t(10.5),
            ),
            const SizedBox(height: 4),
            Text('Thai Prompt POS · thaiprompt.online', style: t(10)),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v, TextStyle Function(double, [FontWeight]) t, TextStyle Function(double, [FontWeight]) m) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.5),
        child: Row(
          children: [
            Expanded(child: Text(k, style: t(11.5))),
            Text(v, style: m(11.5)),
          ],
        ),
      );
}
