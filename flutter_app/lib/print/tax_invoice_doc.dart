// Thaiprompt POS — Full tax invoice (ใบกำกับภาษีเต็มรูป / ใบเสร็จรับเงิน), A4.
//
// A pure black-on-white widget (no AppScope) rendered offscreen by
// PrintService and shown scaled as the on-screen preview, so what the staff
// sees is exactly what prints. Seller block from the shop settings, buyer
// block from the issued TaxBuyer, the gap-free invoice number from the store,
// VAT shown inclusive/exclusive exactly as it was charged on the bill, and the
// grand total spelled out in Thai words (bahtText).
//
// by xman studio

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../models/order_models.dart';
import '../theme/nv_tokens.dart';
import 'receipt_doc.dart' show ShopInfo;

const _digitWords = ['ศูนย์', 'หนึ่ง', 'สอง', 'สาม', 'สี่', 'ห้า', 'หก', 'เจ็ด', 'แปด', 'เก้า'];
const _placeWords = ['', 'สิบ', 'ร้อย', 'พัน', 'หมื่น', 'แสน'];

String _readBelowMillion(int n, {required bool hasHigher}) {
  final s = n.toString();
  final len = s.length;
  final buf = StringBuffer();
  for (var i = 0; i < len; i++) {
    final d = s.codeUnitAt(i) - 48;
    final place = len - i - 1;
    if (d == 0) continue;
    if (place == 1 && d == 1) {
      buf.write('สิบ');
      continue;
    }
    if (place == 1 && d == 2) {
      buf.write('ยี่สิบ');
      continue;
    }
    if (place == 0 && d == 1 && (n > 9 || hasHigher)) {
      buf.write('เอ็ด');
      continue;
    }
    buf
      ..write(_digitWords[d])
      ..write(_placeWords[place]);
  }
  return buf.toString();
}

/// Whole number in Thai words: 1250 → 'หนึ่งพันสองร้อยห้าสิบ', 21 → 'ยี่สิบเอ็ด',
/// 1000001 → 'หนึ่งล้านเอ็ด' (same rules as Excel BAHTTEXT).
String thaiNumberText(int n) {
  if (n == 0) return _digitWords[0];
  if (n < 0) return 'ลบ${thaiNumberText(-n)}';
  if (n < 1000000) return _readBelowMillion(n, hasHigher: false);
  final high = n ~/ 1000000;
  final low = n % 1000000;
  return '${thaiNumberText(high)}ล้าน${low == 0 ? '' : _readBelowMillion(low, hasHigher: true)}';
}

/// Amount in Thai words for documents:
/// 1250 → 'หนึ่งพันสองร้อยห้าสิบบาทถ้วน' · 12.5 → 'สิบสองบาทห้าสิบสตางค์'.
String bahtText(num amount) {
  final neg = amount < 0;
  final cents = (amount.abs() * 100).round();
  final b = cents ~/ 100;
  final s = cents % 100;
  final body = s == 0
      ? '${thaiNumberText(b)}บาทถ้วน'
      : '${b > 0 ? '${thaiNumberText(b)}บาท' : ''}${thaiNumberText(s)}สตางค์';
  return neg ? 'ลบ$body' : body;
}

/// 13-digit tax id → 0-1055-12345-67-8 (any other length is returned as-is).
String formatTaxId(String raw) {
  final d = raw.replaceAll(RegExp(r'\D'), '');
  if (d.length != 13) return raw;
  return '${d.substring(0, 1)}-${d.substring(1, 5)}-${d.substring(5, 10)}-${d.substring(10, 12)}-${d.substring(12)}';
}

class TaxInvoiceDoc extends StatelessWidget {
  final Order order;
  final ShopInfo shop;
  final TaxBuyer buyer;
  final String invoiceNo;
  final bool copy; // สำเนา instead of ต้นฉบับ
  final bool draft; // preview before a number is issued (never printed)

  const TaxInvoiceDoc({
    super.key,
    required this.order,
    required this.shop,
    required this.buyer,
    required this.invoiceNo,
    this.copy = false,
    this.draft = false,
  });

  /// A4 at 96 dpi — matches PrintMedium.a4.renderWidth.
  static const double pageWidth = 794;
  static const double pageHeight = 1123;

  /// Assets the doc draws (none — text only).
  static const precache = <String>[];

  /// True when the bill's VAT was already inside the prices. Inferred from the
  /// bill itself (total == subtotal − discount) so an old bill still prints
  /// the way it was charged even after the VAT setting changes.
  static bool vatIncludedIn(Order o) => o.tax > 0 && o.total == o.subtotal - o.discount;

  static String _pct(double rate) {
    final p = rate * 100;
    return p == p.roundToDouble() ? p.round().toString() : p.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    const black = Colors.black;
    TextStyle t(double size, [FontWeight w = FontWeight.w400]) =>
        TextStyle(fontFamily: Nv.fontUi, fontSize: size, fontWeight: w, color: black, height: 1.38);
    TextStyle m(double size, [FontWeight w = FontWeight.w500]) =>
        TextStyle(fontFamily: Nv.fontMono, fontFamilyFallback: Nv.monoFallback, fontSize: size, fontWeight: w, color: black, fontFeatures: Nv.tnum, height: 1.38);

    Widget field(String label, String value, {double labelWidth = 128}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: labelWidth, child: Text(label, style: t(13, FontWeight.w600))),
              Expanded(child: Text(value.trim().isEmpty ? '—' : value, style: t(13))),
            ],
          ),
        );

    Widget cell(Widget child, {Alignment align = Alignment.centerLeft}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Align(alignment: align, child: child),
        );

    Widget sumRow(String label, int value, {bool bold = false, bool boxed = false}) {
      final row = Padding(
        padding: EdgeInsets.symmetric(vertical: boxed ? 7 : 3, horizontal: boxed ? 10 : 0),
        child: Row(
          children: [
            Expanded(child: Text(label, style: t(bold ? 14.5 : 13.5, bold ? FontWeight.w700 : FontWeight.w500))),
            Text(num2(value), style: m(bold ? 15 : 13.5, bold ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      );
      return boxed ? Container(decoration: BoxDecoration(border: Border.all(color: black, width: 1.2)), child: row) : row;
    }

    final inclusive = vatIncludedIn(order);
    final vatLabel = 'ภาษีมูลค่าเพิ่ม ${_pct(shop.vatRate)}%';
    final net = order.subtotal - order.discount;

    final page = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: pageHeight),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(52, 46, 52, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Seller + title ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shop.name, style: t(21, FontWeight.w700)),
                      if (shop.address.isNotEmpty) Text(shop.address, style: t(13)),
                      if (shop.phone.isNotEmpty) Text('โทร ${phoneFmt(shop.phone)}', style: t(13)),
                      Text('เลขประจำตัวผู้เสียภาษีอากร ${shop.taxId.isEmpty ? '—' : formatTaxId(shop.taxId)}', style: t(13, FontWeight.w600)),
                      if (shop.branch.isNotEmpty) Text('สาขา ${shop.branch}', style: t(13)),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Container(
                  width: 250,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(border: Border.all(color: black, width: 1.4)),
                  child: Column(
                    children: [
                      Text('ใบกำกับภาษี / ใบเสร็จรับเงิน', textAlign: TextAlign.center, style: t(16.5, FontWeight.w700)),
                      Text('TAX INVOICE / RECEIPT', textAlign: TextAlign.center, style: t(11.5, FontWeight.w600)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        decoration: BoxDecoration(border: Border.all(color: black)),
                        child: Text(draft ? 'ตัวอย่าง · ยังไม่ออกเลขที่' : (copy ? 'สำเนา' : 'ต้นฉบับ'), style: t(13, FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ── Buyer + document info ──
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(border: Border.all(color: black, width: 0.9)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ผู้ซื้อ / ลูกค้า', style: t(13.5, FontWeight.w700)),
                          const SizedBox(height: 3),
                          field('ชื่อ', buyer.name, labelWidth: 112),
                          field('ที่อยู่', buyer.address, labelWidth: 112),
                          field('เลขผู้เสียภาษี', formatTaxId(buyer.taxId), labelWidth: 112),
                          field('สาขา', buyer.branch, labelWidth: 112),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(border: Border.all(color: black, width: 0.9)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          field('เลขที่', invoiceNo, labelWidth: 86),
                          field('วันที่', thaiDateLong(order.createdAt), labelWidth: 86),
                          field('อ้างอิงบิล', order.id, labelWidth: 86),
                          field('ชำระโดย', order.method.label, labelWidth: 86),
                          field('พนักงาน', order.cashier, labelWidth: 86),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ── Lines ──
            Table(
              border: TableBorder.all(color: black, width: 0.8),
              columnWidths: const {
                0: FixedColumnWidth(50),
                1: FlexColumnWidth(),
                2: FixedColumnWidth(70),
                3: FixedColumnWidth(110),
                4: FixedColumnWidth(120),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFEDEDED)),
                  children: [
                    cell(Text('ลำดับ', style: t(13, FontWeight.w700)), align: Alignment.center),
                    cell(Text('รายการ', style: t(13, FontWeight.w700))),
                    cell(Text('จำนวน', style: t(13, FontWeight.w700)), align: Alignment.center),
                    cell(Text('ราคาต่อหน่วย', style: t(13, FontWeight.w700)), align: Alignment.centerRight),
                    cell(Text('จำนวนเงิน', style: t(13, FontWeight.w700)), align: Alignment.centerRight),
                  ],
                ),
                for (var i = 0; i < order.lines.length; i++)
                  TableRow(
                    children: [
                      cell(Text('${i + 1}', style: m(13)), align: Alignment.center),
                      cell(Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(order.lines[i].name, style: t(13.5)),
                          if (order.lines[i].detail.isNotEmpty) Text(order.lines[i].detail, style: t(11.5)),
                        ],
                      )),
                      cell(Text(groupDigits(order.lines[i].qty), style: m(13)), align: Alignment.center),
                      cell(Text(num2(order.lines[i].price), style: m(13)), align: Alignment.centerRight),
                      cell(Text(num2(order.lines[i].lineTotal), style: m(13)), align: Alignment.centerRight),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 14),
            // ── Totals + amount in words ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(border: Border.all(color: black, width: 0.9)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('จำนวนเงินรวมทั้งสิ้น (ตัวอักษร)', style: t(12.5, FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('(${bahtText(order.total)})', style: t(14.5, FontWeight.w700)),
                        if (order.discountNote.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('ส่วนลด: ${order.discountNote}', style: t(12)),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 320,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      sumRow('รวมเป็นเงิน', order.subtotal),
                      if (order.discount > 0) sumRow('หักส่วนลด', order.discount),
                      if (inclusive) ...[
                        if (order.discount > 0) sumRow('ยอดหลังหักส่วนลด', order.total),
                        sumRow('ราคาก่อนภาษี', order.total - order.tax),
                        sumRow(vatLabel, order.tax),
                      ] else ...[
                        sumRow('มูลค่าก่อนภาษี', net),
                        sumRow(vatLabel, order.tax),
                      ],
                      const SizedBox(height: 6),
                      sumRow('จำนวนเงินรวมทั้งสิ้น', order.total, bold: true, boxed: true),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            // ── Signatures ──
            Row(
              children: [
                for (final role in const ['ผู้รับเงิน', 'ผู้มีอำนาจลงนาม'])
                  Expanded(
                    child: Column(
                      children: [
                        Text('.......................................................', style: t(13)),
                        const SizedBox(height: 4),
                        Text(role, style: t(13, FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('วันที่ ........ / ........ / ........', style: t(12.5)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 26),
            Text('เอกสารออกโดยระบบ Thai Prompt POS · thaiprompt.online', textAlign: TextAlign.center, style: t(11)),
          ],
        ),
      ),
    );

    return ColoredBox(
      color: Colors.white,
      child: draft
          ? Stack(
              children: [
                page,
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Transform.rotate(
                        angle: -0.5,
                        child: Text('ตัวอย่าง', style: t(150, FontWeight.w700).copyWith(color: const Color(0x12000000))),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : page,
    );
  }
}
