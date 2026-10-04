// Thaiprompt POS — Shipping label document (100×150 mm), print-ready.
//
// A pure black-on-white widget (no AppScope) rendered offscreen by
// PrintService (PrintMedium.label100x150 → 600×900 logical px, 6 px per mm)
// and shown 1:1 as the on-screen preview. Carries the sender (shop), the
// receiver, provider, COD amount, items/weight, a Code128 barcode of the
// tracking number (or the job id when none) and a QR of the order reference.
//
// by xman studio

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/format.dart';
import '../models/extra_models.dart';
import '../models/order_models.dart';
import '../theme/nv_tokens.dart';
import 'receipt_doc.dart' show ShopInfo;

class ShippingLabelDoc extends StatelessWidget {
  /// Logical size that maps exactly onto a 100×150 mm label.
  static const double width = 600;
  static const double height = 900;

  /// The doc draws no asset images.
  static const precache = <String>[];

  final DeliveryJob job;
  final ShopInfo shop;
  final String providerName;
  final Order? order;

  const ShippingLabelDoc({super.key, required this.job, required this.shop, required this.providerName, this.order});

  /// Amount the rider collects on delivery (order total less any refund).
  // Thai Prompt rider jobs are always prepaid in the app — never COD.
  bool get _cod => job.cod && !job.isTpRider;
  int get codAmount => _cod ? (order?.netTotal ?? 0) : 0;

  String get barcodeData => job.trackingNo.trim().isNotEmpty ? job.trackingNo.trim() : job.id;

  @override
  Widget build(BuildContext context) {
    TextStyle t(double size, [FontWeight w = FontWeight.w400, Color c = Colors.black]) =>
        TextStyle(fontFamily: Nv.fontUi, fontSize: size, fontWeight: w, color: c, height: 1.25);
    TextStyle m(double size, [FontWeight w = FontWeight.w600, Color c = Colors.black]) => TextStyle(
          fontFamily: Nv.fontMono,
          fontFamilyFallback: Nv.monoFallback,
          fontSize: size,
          fontWeight: w,
          color: c,
          fontFeatures: Nv.tnum,
          height: 1.2,
        );
    const line = BorderSide(color: Colors.black, width: 3);

    Widget kv(String k, String v, {bool big = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 118, child: Text(k, style: t(big ? 19 : 17, FontWeight.w600))),
              Expanded(
                child: Text(v, maxLines: 1, overflow: TextOverflow.ellipsis, style: big ? m(24, FontWeight.w800) : m(18)),
              ),
            ],
          ),
        );

    final ref = order?.reference ?? job.orderId;
    final kg = (job.weightGrams / 1000).toStringAsFixed(2);

    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: DecoratedBox(
            decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 3)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── provider + service ──
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                  decoration: const BoxDecoration(border: Border(bottom: line)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(providerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: t(32, FontWeight.w800)),
                            Text(
                                'งานจัดส่ง ${job.id}${job.orderId.isEmpty ? '' : ' · บิล ${job.orderId}'}'
                                '${job.remoteOrderNo.isEmpty ? '' : ' · ${job.remoteOrderNo}'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: m(16, FontWeight.w500)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (job.isTpRider)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 2.5)),
                          child: Column(
                            children: [
                              Text('ชำระแล้ว', style: t(20, FontWeight.w800)),
                              Text('ผ่าน Thai Prompt', style: t(13, FontWeight.w700)),
                            ],
                          ),
                        )
                      else if (_cod)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: Colors.black,
                          child: Column(
                            children: [
                              Text('COD', style: m(30, FontWeight.w800, Colors.white)),
                              Text('เก็บเงินปลายทาง', style: t(14, FontWeight.w700, Colors.white)),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 2.5)),
                          child: Text('ไม่เก็บเงิน', style: t(20, FontWeight.w800)),
                        ),
                    ],
                  ),
                ),
                // ── barcode ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                  child: Column(
                    children: [
                      BarcodeWidget(
                        barcode: Barcode.code128(),
                        data: barcodeData,
                        width: 530,
                        height: 96,
                        drawText: true,
                        style: m(20),
                        errorBuilder: (context, error) => SizedBox(
                          height: 96,
                          child: Center(child: Text(barcodeData, style: m(28, FontWeight.w800))),
                        ),
                      ),
                      if (job.trackingNo.trim().isEmpty)
                        Text('ยังไม่มีเลขพัสดุ — บาร์โค้ดนี้คือรหัสงาน', style: t(13, FontWeight.w600)),
                    ],
                  ),
                ),
                // ── receiver ──
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                    decoration: const BoxDecoration(border: Border(top: line)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ผู้รับ', style: t(17, FontWeight.w800)),
                        Text(job.customerName.isEmpty ? '—' : job.customerName,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: t(31, FontWeight.w800)),
                        if (job.phone.isNotEmpty) Text('โทร ${phoneFmt(job.phone)}', style: m(25, FontWeight.w800)),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Text(
                            job.address.isEmpty ? '(ยังไม่ได้ระบุที่อยู่ผู้รับ)' : job.address,
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                            style: t(23, FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ── sender ──
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                  decoration: const BoxDecoration(border: Border(top: line)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ผู้ส่ง', style: t(14, FontWeight.w800)),
                      Text(shop.branch.isEmpty ? shop.name : '${shop.name} · ${shop.branch}',
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: t(19, FontWeight.w700)),
                      if (shop.phone.isNotEmpty) Text('โทร ${phoneFmt(shop.phone)}', style: m(17)),
                      if (shop.address.isNotEmpty)
                        Text(shop.address, maxLines: 2, overflow: TextOverflow.ellipsis, style: t(15)),
                    ],
                  ),
                ),
                // ── details + QR ──
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 10, 14, 10),
                  decoration: const BoxDecoration(border: Border(top: line)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_cod) kv('ยอดเก็บเงิน', baht(codAmount, decimals: true), big: true),
                            kv('จำนวน', order == null ? '—' : '${order!.itemCount} ชิ้น'),
                            if (job.weightGrams > 0) kv('น้ำหนัก', '$kg กก.'),
                            kv('วันที่', thaiDateTime(job.createdAt)),
                            if (job.riderName.isNotEmpty)
                              kv('ผู้ส่งของ', [job.riderName, if (job.riderPlate.isNotEmpty) job.riderPlate].join(' · ')),
                            if (job.note.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text('หมายเหตุ: ${job.note}', maxLines: 2, overflow: TextOverflow.ellipsis, style: t(15, FontWeight.w600)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        children: [
                          QrImageView(
                            data: ref,
                            size: 132,
                            padding: EdgeInsets.zero,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                          ),
                          const SizedBox(height: 4),
                          Text(ref, style: m(12, FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.black, width: 2))),
                  child: Text('Thai Prompt POS · thaiprompt.online', textAlign: TextAlign.center, style: t(12.5)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
