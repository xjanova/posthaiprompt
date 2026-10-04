// Thaiprompt POS — Quotation document (ใบเสนอราคา) for the live cart.
//
// A pure black-on-white widget (no AppScope) rendered offscreen by
// PrintService on the receipt roll. It is built from a snapshot of the cart
// (lines, discounts, VAT, total) so the printed prices match the payment
// screen exactly, and it states clearly that it is not a receipt.
//
// by xman studio

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../models/order_models.dart';
import '../theme/nv_tokens.dart';
import '../widgets/nova/nv_art.dart';
import 'receipt_doc.dart' show ShopInfo;

class QuoteDoc extends StatelessWidget {
  final ShopInfo shop;
  final List<OrderLine> lines;
  final int subtotal;
  final int discount;
  final String discountNote;
  final int tax;
  final int total;
  final DateTime date;
  final String reference;
  final String staffName;
  final String orderLabel; // 'ทานที่นี่ · โต๊ะ 4' · 'กลับบ้าน'
  final String? customerName;
  final bool narrow; // 58 mm roll

  const QuoteDoc({
    super.key,
    required this.shop,
    required this.lines,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.date,
    required this.reference,
    required this.staffName,
    this.discountNote = '',
    this.orderLabel = '',
    this.customerName,
    this.narrow = false,
  });

  /// Assets the doc draws (precache before the offscreen render).
  static const precache = [NvAssets.logoOnLight];

  /// Quotation number from the time it was printed: `QT-yyMMdd-HHmmss` (yy = พ.ศ.).
  static String referenceFor(DateTime d) {
    String p2(int v) => v.toString().padLeft(2, '0');
    return 'QT-${p2((d.year + 543) % 100)}${p2(d.month)}${p2(d.day)}-${p2(d.hour)}${p2(d.minute)}${p2(d.second)}';
  }

  int get itemCount => lines.fold(0, (s, l) => s + l.qty);

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

    final vatPct = (shop.vatRate * 100).round();

    return Padding(
      padding: EdgeInsets.fromLTRB(narrow ? 10 : 16, 18, narrow ? 10 : 16, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                0.3, 0.59, 0.11, 0, 0, //
                0.3, 0.59, 0.11, 0, 0,
                0.3, 0.59, 0.11, 0, 0,
                0, 0, 0, 1, 0,
              ]),
              child: Image.asset(NvAssets.logoOnLight, height: narrow ? 46 : 58, errorBuilder: (_, _, _) => const SizedBox()),
            ),
          ),
          const SizedBox(height: 6),
          Text(shop.name, textAlign: TextAlign.center, style: t(1.35, FontWeight.w700)),
          Text(shop.branch, textAlign: TextAlign.center, style: t(0.95)),
          if (shop.address.isNotEmpty) Text(shop.address, textAlign: TextAlign.center, style: t(0.85)),
          if (shop.phone.isNotEmpty) Text('โทร ${phoneFmt(shop.phone)}', textAlign: TextAlign.center, style: t(0.85)),
          if (shop.taxId.isNotEmpty) Text('เลขประจำตัวผู้เสียภาษี ${shop.taxId}', textAlign: TextAlign.center, style: t(0.85)),
          const SizedBox(height: 10),
          Text('ใบเสนอราคา', textAlign: TextAlign.center, style: t(1.4, FontWeight.w700)),
          Text('QUOTATION', textAlign: TextAlign.center, style: m(0.85, FontWeight.w600)),
          dash(),
          row('เลขที่', reference),
          row('วันที่', thaiDateTime(date)),
          row('พนักงาน', staffName),
          if (orderLabel.isNotEmpty) row('ประเภท', orderLabel),
          if (customerName != null && customerName!.isNotEmpty) row('ลูกค้า', customerName!),
          dash(),
          for (final l in lines) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: fs * 2.1, child: Text('${l.qty}x', style: m(1, FontWeight.w600))),
                Expanded(child: Text(l.name, style: t(1, FontWeight.w600))),
                const SizedBox(width: 8),
                Text(groupDigits(l.lineTotal), style: m(1, FontWeight.w600)),
              ],
            ),
            if (l.detail.isNotEmpty)
              Padding(padding: EdgeInsets.only(left: fs * 2.1), child: Text(l.detail, style: t(0.85))),
            if (l.qty > 1)
              Padding(padding: EdgeInsets.only(left: fs * 2.1), child: Text('@ ${groupDigits(l.price)}', style: m(0.85, FontWeight.w400))),
            const SizedBox(height: 3),
          ],
          dash(),
          row('รวม $itemCount รายการ', baht(subtotal, decimals: true)),
          if (discount > 0)
            row('ส่วนลด${discountNote.isNotEmpty ? ' ($discountNote)' : ''}', '-${baht(discount, decimals: true)}'),
          if (shop.vatEnabled)
            row(shop.vatInclusive ? 'VAT $vatPct% (รวมในราคา)' : 'VAT $vatPct%', baht(tax, decimals: true)),
          const SizedBox(height: 4),
          row('ยอดรวมทั้งสิ้น', baht(total, decimals: true), bold: true, k: 1.35),
          dash(),
          Text('เอกสารนี้ไม่ใช่ใบเสร็จรับเงิน', textAlign: TextAlign.center, style: t(1, FontWeight.w700)),
          Text('ราคาและส่วนลดอาจเปลี่ยนแปลงตามสต็อกและโปรโมชั่น ณ วันที่ชำระเงิน', textAlign: TextAlign.center, style: t(0.85)),
          const SizedBox(height: 6),
          Text('Thai Prompt POS · thaiprompt.online', textAlign: TextAlign.center, style: t(0.75)),
        ],
      ),
    );
  }
}
