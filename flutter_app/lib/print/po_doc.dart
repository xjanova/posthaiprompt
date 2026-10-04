// Thaiprompt POS — Purchase order document (A4, black on white).
//
// Shop header, PO number / date / status, supplier block, line table (repeats
// its header on every page), grand total, note and signature lines. Built as
// A4Pages so a long PO flows onto extra pages instead of shrinking.
//
// by xman studio

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../models/extra_models.dart';
import 'receipt_doc.dart' show ShopInfo;
import 'stock_report_doc.dart';

List<Widget> poDocPages({
  required PurchaseOrder po,
  required ShopInfo shop,
  Supplier? supplier,
  required DateTime printedAt,
}) {
  final blocks = <A4Block>[];

  // ── header ──
  blocks.add(A4Block(
    SizedBox(
      height: 112,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shop.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: docText(20, weight: FontWeight.w700)),
                Text(shop.branch, maxLines: 1, overflow: TextOverflow.ellipsis, style: docText(12)),
                if (shop.address.isNotEmpty)
                  Text(shop.address, maxLines: 2, overflow: TextOverflow.ellipsis, style: docText(11, color: kDocGrey)),
                if (shop.phone.isNotEmpty) Text('โทร ${phoneFmt(shop.phone)}', style: docText(11, color: kDocGrey)),
                if (shop.taxId.isNotEmpty) Text('เลขประจำตัวผู้เสียภาษี ${shop.taxId}', style: docText(11, color: kDocGrey)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('ใบสั่งซื้อ', style: docText(26, weight: FontWeight.w700)),
              Text('PURCHASE ORDER', style: docText(10.5, weight: FontWeight.w600, color: kDocGrey)),
              const SizedBox(height: 6),
              Text('เลขที่ ${po.id}', style: docMono(13, weight: FontWeight.w700)),
              Text('วันที่ ${thaiDate(po.createdAt)}', style: docText(11.5)),
              Text('สถานะ: ${po.status.label}', style: docText(11, color: kDocGrey)),
            ],
          ),
        ],
      ),
    ),
    112,
  ));
  blocks.add(const A4Block.gap(10));

  // ── supplier block ──
  Widget kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 78, child: Text(k, style: docText(11, color: kDocGrey))),
            Expanded(child: Text(v.isEmpty ? '—' : v, maxLines: 1, overflow: TextOverflow.ellipsis, style: docText(11.5))),
          ],
        ),
      );
  blocks.add(A4Block(
    Container(
      height: 104,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 0.8), borderRadius: BorderRadius.circular(4)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ผู้ขาย / ซัพพลายเออร์', style: docText(10.5, weight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(po.supplierName, maxLines: 1, overflow: TextOverflow.ellipsis, style: docText(14, weight: FontWeight.w700)),
                kv('ผู้ติดต่อ', supplier?.contact ?? ''),
                kv('โทร', supplier == null || supplier.phone.isEmpty ? '' : phoneFmt(supplier.phone)),
              ],
            ),
          ),
          Container(width: 0.6, color: kDocLine, margin: const EdgeInsets.symmetric(horizontal: 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ข้อมูลการสั่งซื้อ', style: docText(10.5, weight: FontWeight.w700)),
                const SizedBox(height: 3),
                kv('ผู้สั่งซื้อ', po.createdBy),
                kv('หมวดสินค้า', supplier?.category ?? ''),
                kv('รับของ', po.receivedAt == null ? '' : thaiDateTime(po.receivedAt!)),
                kv('พิมพ์เมื่อ', thaiDateTime(printedAt)),
              ],
            ),
          ),
        ],
      ),
    ),
    104,
  ));
  blocks.add(const A4Block.gap(16));

  // ── lines ──
  const cols = [
    DocCol('ลำดับ', width: 40, align: TextAlign.center, mono: true),
    DocCol('รหัส', width: 84, mono: true),
    DocCol('รายการ', flex: 1),
    DocCol('จำนวน', width: 64, align: TextAlign.right, mono: true),
    DocCol('ราคา/หน่วย', width: 92, align: TextAlign.right, mono: true),
    DocCol('จำนวนเงิน', width: 104, align: TextAlign.right, mono: true),
  ];
  final header = docTableRow(cols, [for (final c in cols) c.title], height: 28, header: true, fontSize: 12);
  blocks.add(A4Block(header, 28, keepWithNext: 26));
  for (var i = 0; i < po.lines.length; i++) {
    final l = po.lines[i];
    blocks.add(A4Block(
      docTableRow(cols, [
        '${i + 1}',
        l.code,
        l.name,
        groupDigits(l.qty),
        baht(l.unitCost, decimals: true),
        baht(l.total, decimals: true),
      ], height: 26, fontSize: 12),
      26,
      repeatHeader: header,
      repeatHeaderHeight: 28,
    ));
  }

  // ── total ──
  blocks.add(A4Block(
    Container(
      height: 64,
      padding: const EdgeInsets.only(top: 8),
      alignment: Alignment.topRight,
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.black, width: 1))),
      child: SizedBox(
        width: 300,
        child: Column(
          children: [
            Row(children: [
              Expanded(child: Text('จำนวนรวม', style: docText(12))),
              Text('${groupDigits(po.itemCount)} หน่วย · ${po.lines.length} รายการ', style: docMono(12)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(child: Text('รวมทั้งสิ้น', style: docText(15, weight: FontWeight.w700))),
              Text(baht(po.total, decimals: true), style: docMono(17, weight: FontWeight.w700)),
            ]),
          ],
        ),
      ),
    ),
    64,
  ));

  if (po.note.isNotEmpty) {
    blocks.add(A4Block(
      Container(
        height: 56,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(border: Border.all(color: kDocLine, width: 0.7), borderRadius: BorderRadius.circular(4)),
        child: Text('หมายเหตุ: ${po.note}', maxLines: 2, overflow: TextOverflow.ellipsis, style: docText(11.5)),
      ),
      56,
    ));
  }
  blocks.add(const A4Block.gap(36));

  // ── signatures ──
  Widget sign(String role) => Expanded(
        child: Column(
          children: [
            const SizedBox(height: 34),
            Container(height: 0.8, color: Colors.black, margin: const EdgeInsets.symmetric(horizontal: 14)),
            const SizedBox(height: 6),
            Text(role, style: docText(11.5, weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('วันที่ ____/____/________', style: docText(10.5, color: kDocGrey)),
          ],
        ),
      );
  blocks.add(A4Block(
    SizedBox(
      height: 96,
      child: Row(children: [sign('ผู้สั่งซื้อ'), sign('ผู้อนุมัติ'), sign('ผู้รับสินค้า')]),
    ),
    96,
  ));

  return A4Pages.pack(
    blocks,
    footer: (p, n) => A4Pages.footerRow('${shop.name} · ใบสั่งซื้อ ${po.id} · Thai Prompt POS', p, n),
  );
}
