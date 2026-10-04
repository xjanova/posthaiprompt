// Thaiprompt POS — Receipt document (thermal 58/80 mm), print-ready.
//
// A pure widget (black on white, no AppScope) rendered offscreen by
// PrintService and also shown as the on-screen preview, so what the cashier
// sees is exactly what prints. Short-form tax invoice when VAT is on.
//
// by xman studio

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';

import '../core/format.dart';
import '../models/order_models.dart';
import '../state/pos_store.dart';
import '../theme/nv_tokens.dart';
import '../widgets/nova/nv_art.dart';

/// Shop details printed in the header/footer (snapshot of store settings).
class ShopInfo {
  final String name;
  final String branch;
  final String phone;
  final String address;
  final String taxId;
  final String terminalId;
  final String footer;
  final bool vatEnabled;
  final bool vatInclusive;
  final double vatRate;

  const ShopInfo({
    required this.name,
    required this.branch,
    this.phone = '',
    this.address = '',
    this.taxId = '',
    this.terminalId = '',
    this.footer = '',
    this.vatEnabled = true,
    this.vatInclusive = false,
    this.vatRate = 0.07,
  });

  factory ShopInfo.of(PosStore s) => ShopInfo(
        name: s.shopName,
        branch: s.branch,
        phone: s.shopPhone,
        address: s.shopAddress,
        taxId: s.taxId,
        terminalId: s.terminalId,
        footer: s.receiptFooter,
        vatEnabled: s.vatEnabled,
        vatInclusive: s.vatInclusive,
        vatRate: s.vatRate,
      );
}

class ReceiptDoc extends StatelessWidget {
  final Order order;
  final ShopInfo shop;
  final bool reprint;
  final bool narrow; // 58 mm
  final int? memberPoints; // points balance after this bill

  const ReceiptDoc({super.key, required this.order, required this.shop, this.reprint = false, this.narrow = false, this.memberPoints});

  /// Assets the doc draws (precache before offscreen render).
  static const precache = [NvAssets.logoOnLight];

  @override
  Widget build(BuildContext context) {
    final fs = narrow ? 17.0 : 20.0;
    TextStyle t([double k = 1, FontWeight w = FontWeight.w400]) =>
        TextStyle(fontFamily: Nv.fontUi, fontSize: fs * k, fontWeight: w, color: Colors.black, height: 1.3);
    TextStyle m([double k = 1, FontWeight w = FontWeight.w500]) =>
        TextStyle(fontFamily: Nv.fontMono, fontFamilyFallback: Nv.monoFallback, fontSize: fs * k, fontWeight: w, color: Colors.black, fontFeatures: Nv.tnum, height: 1.3);

    Widget row(String l, String r, {bool bold = false, double k = 1}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(l, style: t(k, bold ? FontWeight.w700 : FontWeight.w400))),
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

    final title = shop.vatEnabled ? 'ใบเสร็จรับเงิน/ใบกำกับภาษีอย่างย่อ' : 'ใบเสร็จรับเงิน';
    final refunded = order.status == OrderStatus.refunded || order.refundAmount > 0;

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
          if (shop.terminalId.isNotEmpty) Text('POS ID ${shop.terminalId}', textAlign: TextAlign.center, style: t(0.8)),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center, style: t(1.05, FontWeight.w700)),
          if (reprint) Text('** สำเนา (พิมพ์ซ้ำ) **', textAlign: TextAlign.center, style: t(0.95, FontWeight.w700)),
          dash(),
          row('เลขที่', order.id),
          row('วันที่', thaiDateTime(order.createdAt)),
          row('พนักงาน', order.cashier),
          row('ประเภท', order.type == OrderType.dineIn && order.tableNumber != null ? 'โต๊ะ ${order.tableNumber} · ${order.guests} ท่าน' : order.type.label),
          if (order.customerName != null) row('สมาชิก', order.customerName!),
          dash(),
          for (final l in order.lines) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: fs * 2.1, child: Text('${l.qty}x', style: m(1, FontWeight.w600))),
                Expanded(child: Text(l.name, style: t(1, FontWeight.w600))),
                Text(groupDigits(l.lineTotal), style: m(1, FontWeight.w600)),
              ],
            ),
            if (l.detail.isNotEmpty)
              Padding(padding: EdgeInsets.only(left: fs * 2.1), child: Text(l.detail, style: t(0.85))),
            if (l.qty > 1)
              Padding(padding: EdgeInsets.only(left: fs * 2.1), child: Text('@ ${groupDigits(l.price)}', style: m(0.85, FontWeight.w400))),
            if (l.refundedQty > 0)
              Padding(padding: EdgeInsets.only(left: fs * 2.1), child: Text('คืนแล้ว ${l.refundedQty} ชิ้น', style: t(0.85, FontWeight.w700))),
            const SizedBox(height: 3),
          ],
          dash(),
          row('รวม ${order.itemCount} รายการ', baht(order.subtotal, decimals: true)),
          if (order.discount > 0) row('ส่วนลด${order.discountNote.isNotEmpty ? ' (${order.discountNote})' : ''}', '-${baht(order.discount, decimals: true)}'),
          if (shop.vatEnabled)
            row(shop.vatInclusive ? 'VAT ${(shop.vatRate * 100).round()}% (รวมในราคา)' : 'VAT ${(shop.vatRate * 100).round()}%', baht(order.tax, decimals: true)),
          const SizedBox(height: 4),
          row('ยอดสุทธิ', baht(order.total, decimals: true), bold: true, k: 1.35),
          const SizedBox(height: 4),
          row('ชำระโดย', order.method.receiptLabel),
          if (order.method == PaymentMethod.cash && order.cashReceived > 0) ...[
            row('รับเงิน', baht(order.cashReceived, decimals: true)),
            row('เงินทอน', baht(order.change, decimals: true), bold: true),
          ],
          if (order.paymentRef != null) row('อ้างอิง', order.paymentRef!),
          if (refunded) ...[
            dash(),
            row('คืนเงินแล้ว', '-${baht(order.refundAmount, decimals: true)}', bold: true),
            if (order.refundReason != null) Text('เหตุผล: ${order.refundReason}', style: t(0.85)),
          ],
          if (memberPoints != null) ...[
            const SizedBox(height: 6),
            Text('แต้มสะสมคงเหลือ ${groupDigits(memberPoints!)} แต้ม', textAlign: TextAlign.center, style: t(0.95, FontWeight.w600)),
          ],
          dash(),
          Center(
            child: BarcodeWidget(
              barcode: Barcode.code128(),
              data: order.reference,
              width: narrow ? 300 : 420,
              height: narrow ? 56 : 70,
              drawText: true,
              style: m(0.8),
            ),
          ),
          const SizedBox(height: 10),
          if (shop.footer.isNotEmpty) Text(shop.footer, textAlign: TextAlign.center, style: t(1, FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Thai Prompt POS · thaiprompt.online', textAlign: TextAlign.center, style: t(0.75)),
        ],
      ),
    );
  }
}
