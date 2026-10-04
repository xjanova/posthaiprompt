// Thaiprompt POS — Stock movement report (A4, black on white) + A4 pager.
//
// [A4Pages] packs fixed-height blocks into real 794×1123 px A4 pages (table
// headers repeat on every page, headings stay with their first row), then
// prints / shares them as ONE multi-page PDF through PrintService's renderer —
// a long ledger never gets squeezed onto a single sheet. Single-page documents
// go straight through PrintService.printDoc / shareDoc.
//
// stockReportPages() builds the ledger report: shop header, period + filters,
// per-type summary, per-product totals and the filtered movement table.
//
// by xman studio

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../core/format.dart';
import '../core/print/print_service.dart';
import '../models/extra_models.dart';
import '../theme/nv_tokens.dart';

// ───────────────────────────── shared doc styles ─────────────────────────────

const Color kDocGrey = Color(0xFF555555);
const Color kDocLine = Color(0xFFBBBBBB);
const Color kDocShade = Color(0xFFF2F2F2);

TextStyle docText(double size, {FontWeight weight = FontWeight.w400, Color color = Colors.black}) =>
    TextStyle(fontFamily: Nv.fontUi, fontSize: size, fontWeight: weight, color: color, height: 1.25);

TextStyle docMono(double size, {FontWeight weight = FontWeight.w500, Color color = Colors.black}) =>
    TextStyle(
        fontFamily: Nv.fontMono,
        fontFamilyFallback: Nv.monoFallback, // JetBrains Mono has no ฿ / Thai glyphs
        fontSize: size,
        fontWeight: weight,
        color: color,
        fontFeatures: Nv.tnum,
        height: 1.25);

/// One column of a printed table: fixed [width] or a [flex] share.
class DocCol {
  final String title;
  final int flex;
  final double? width;
  final TextAlign align;
  final bool mono;
  const DocCol(this.title, {this.flex = 1, this.width, this.align = TextAlign.left, this.mono = false});
}

/// A fixed-height table row (header when [header] is true).
Widget docTableRow(List<DocCol> cols, List<String> values,
    {required double height, bool header = false, bool shade = false, bool bold = false, double fontSize = 10.5}) {
  return Container(
    height: height,
    padding: const EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(
      color: header ? const Color(0xFFE6E6E6) : (shade ? kDocShade : null),
      border: Border(
        top: header ? const BorderSide(color: Colors.black, width: 0.8) : BorderSide.none,
        bottom: BorderSide(color: header ? Colors.black : kDocLine, width: header ? 0.8 : 0.5),
      ),
    ),
    child: Row(
      children: [
        for (var i = 0; i < cols.length; i++)
          () {
            final c = cols[i];
            final text = Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                i < values.length ? values[i] : '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: c.align,
                style: header
                    ? docText(fontSize, weight: FontWeight.w700)
                    : (c.mono
                        ? docMono(fontSize, weight: bold ? FontWeight.w700 : FontWeight.w500)
                        : docText(fontSize, weight: bold ? FontWeight.w700 : FontWeight.w400)),
              ),
            );
            return c.width != null ? SizedBox(width: c.width, child: text) : Expanded(flex: c.flex, child: text);
          }(),
      ],
    ),
  );
}

// ───────────────────────────── A4 pager ─────────────────────────────

/// A block of known height placed on an A4 page.
class A4Block {
  final Widget child;
  final double height;

  /// Drawn first when this block has to open a new page (repeated table header).
  final Widget? repeatHeader;
  final double repeatHeaderHeight;

  /// Extra room that must remain below this block on the same page
  /// (keeps a heading / table header together with its first row).
  final double keepWithNext;
  final bool isGap;

  const A4Block(this.child, this.height,
      {this.repeatHeader, this.repeatHeaderHeight = 0, this.keepWithNext = 0})
      : isGap = false;

  const A4Block.gap(this.height)
      : child = const SizedBox.shrink(),
        repeatHeader = null,
        repeatHeaderHeight = 0,
        keepWithNext = 0,
        isGap = true;
}

class A4Pages {
  A4Pages._();

  static const double width = 794; // PrintMedium.a4.renderWidth
  static const double height = 1123; // 297/210 × 794
  static const EdgeInsets margin = EdgeInsets.fromLTRB(44, 40, 44, 26);
  static const double footerHeight = 22;
  static double get bodyHeight => height - margin.vertical - footerHeight;

  /// Pack [blocks] into pages; [footer] gets (page, total).
  static List<Widget> pack(List<A4Block> blocks, {required Widget Function(int page, int total) footer}) {
    final pages = <List<Widget>>[];
    var cur = <Widget>[];
    var used = 0.0;
    for (final b in blocks) {
      if (b.isGap && cur.isEmpty) continue;
      if (cur.isNotEmpty && used + b.height + b.keepWithNext > bodyHeight) {
        pages.add(cur);
        cur = <Widget>[];
        used = 0;
        if (b.isGap) continue;
        if (b.repeatHeader != null) {
          cur.add(b.repeatHeader!);
          used += b.repeatHeaderHeight;
        }
      }
      cur.add(b.isGap ? SizedBox(height: b.height) : b.child);
      used += b.height;
    }
    if (cur.isNotEmpty || pages.isEmpty) pages.add(cur);
    final n = pages.length;
    return [for (var i = 0; i < n; i++) _page(pages[i], footer(i + 1, n))];
  }

  static Widget _page(List<Widget> children, Widget footer) => SizedBox(
        width: width,
        height: height,
        child: ColoredBox(
          color: Colors.white,
          child: Padding(
            padding: margin,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.topCenter,
                      maxHeight: double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: children,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: footerHeight, child: footer),
              ],
            ),
          ),
        ),
      );

  /// Standard footer: left text + "หน้า i/n".
  static Widget footerRow(String left, int page, int total) => Container(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: kDocLine, width: 0.5))),
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Expanded(child: Text(left, maxLines: 1, overflow: TextOverflow.ellipsis, style: docText(9.5, color: kDocGrey))),
            Text('หน้า $page/$total', style: docText(9.5, color: kDocGrey)),
          ],
        ),
      );

  /// Print [pages] (A4) — direct to [printerName] when it exists, else the system dialog.
  static Future<PrintResult> printPages(BuildContext context, List<Widget> pages,
      {required String jobName, String printerName = ''}) async {
    if (pages.length == 1) {
      return PrintService.printDoc(context, pages.first, jobName: jobName, medium: PrintMedium.a4, printerName: printerName);
    }
    try {
      final pdf = await _pdf(context, pages);
      if (pdf == null) return const PrintResult(false, 'ยกเลิกการพิมพ์');
      if (printerName.isNotEmpty) {
        try {
          final printers = await Printing.listPrinters();
          final match = printers.where((p) => p.name == printerName);
          if (match.isNotEmpty) {
            final ok = await Printing.directPrintPdf(
                printer: match.first, onLayout: (_) async => pdf, name: jobName, format: PdfPageFormat.a4);
            return ok
                ? PrintResult(true, 'ส่งงานพิมพ์ ${pages.length} หน้าไปที่ $printerName แล้ว')
                : const PrintResult(false, 'เครื่องพิมพ์ปฏิเสธงานพิมพ์');
          }
        } catch (_) {
          // listing unsupported on this platform → system dialog below
        }
      }
      final ok = await Printing.layoutPdf(onLayout: (_) async => pdf, name: jobName, format: PdfPageFormat.a4);
      return ok ? PrintResult(true, 'ส่งงานพิมพ์ ${pages.length} หน้าแล้ว') : const PrintResult(false, 'ยกเลิกการพิมพ์');
    } catch (e) {
      return PrintResult(false, 'พิมพ์ไม่สำเร็จ: ${_short(e)}');
    }
  }

  /// Render [pages] to one PDF and open the share / save sheet.
  static Future<PrintResult> sharePages(BuildContext context, List<Widget> pages, {required String fileName}) async {
    if (pages.length == 1) {
      return PrintService.shareDoc(context, pages.first, fileName: fileName, medium: PrintMedium.a4);
    }
    try {
      final pdf = await _pdf(context, pages);
      if (pdf == null) return const PrintResult(false, 'ยกเลิก');
      final ok = await Printing.sharePdf(bytes: pdf, filename: fileName.endsWith('.pdf') ? fileName : '$fileName.pdf');
      return ok ? const PrintResult(true, 'บันทึก/แชร์ไฟล์ PDF แล้ว') : const PrintResult(false, 'ยกเลิก');
    } catch (e) {
      return PrintResult(false, 'สร้าง PDF ไม่สำเร็จ: ${_short(e)}');
    }
  }

  static Future<Uint8List?> _pdf(BuildContext context, List<Widget> pages) async {
    final pngs = <Uint8List>[];
    for (final p in pages) {
      if (!context.mounted) return null;
      pngs.add(await PrintService.renderPng(context, p, width: width, pixelRatio: 2.0));
    }
    return PrintService.pdfFromPngs(pngs, PrintMedium.a4);
  }

  static String _short(Object e) {
    final s = e.toString();
    return s.length > 120 ? '${s.substring(0, 120)}…' : s;
  }
}

// ───────────────────────────── stock report ─────────────────────────────

/// Everything the stock report prints (a snapshot — no store access).
class StockReportData {
  final String shopName;
  final String branch;
  final String phone;
  final String address;
  final String periodLabel; // 'วันนี้ · 04 ต.ค. 2569'
  final String typeLabel; // 'ทุกประเภท' | 'ขาย' …
  final String search; // '' = none
  final DateTime printedAt;
  final String printedBy;
  final List<StockMovement> moves; // newest first

  const StockReportData({
    required this.shopName,
    required this.branch,
    this.phone = '',
    this.address = '',
    required this.periodLabel,
    required this.typeLabel,
    this.search = '',
    required this.printedAt,
    required this.printedBy,
    required this.moves,
  });
}

class _ProductTotal {
  final String code;
  final String name;
  int sale = 0;
  int refund = 0;
  int receive = 0;
  int waste = 0;
  int adjust = 0; // adjust + count
  int net = 0;
  final int balance; // newest balance seen in the filtered moves
  _ProductTotal(this.code, this.name, this.balance);
}

String _signed(int v) => v > 0 ? '+${groupDigits(v)}' : (v == 0 ? '0' : groupDigits(v));

/// Max movement rows printed (keeps the PDF a sane size).
const int kStockReportMaxRows = 1500;

List<Widget> stockReportPages(StockReportData d) {
  // ── per-product + per-type totals ──
  final totals = <String, _ProductTotal>{};
  final byType = <StockMoveType, int>{for (final t in StockMoveType.values) t: 0};
  for (final m in d.moves) {
    final t = totals.putIfAbsent(m.code, () => _ProductTotal(m.code, m.name, m.balance));
    switch (m.type) {
      case StockMoveType.sale:
        t.sale += m.delta;
      case StockMoveType.refund:
        t.refund += m.delta;
      case StockMoveType.receive:
        t.receive += m.delta;
      case StockMoveType.waste:
        t.waste += m.delta;
      case StockMoveType.adjust:
      case StockMoveType.count:
        t.adjust += m.delta;
    }
    t.net += m.delta;
    byType[m.type] = byType[m.type]! + m.delta;
  }
  final productRows = totals.values.toList()..sort((a, b) => a.name.compareTo(b.name));

  final blocks = <A4Block>[];

  // ── header ──
  blocks.add(A4Block(
    SizedBox(
      height: 96,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.shopName, maxLines: 1, overflow: TextOverflow.ellipsis, style: docText(19, weight: FontWeight.w700)),
                Text(d.branch, maxLines: 1, overflow: TextOverflow.ellipsis, style: docText(11.5)),
                if (d.address.isNotEmpty)
                  Text(d.address, maxLines: 2, overflow: TextOverflow.ellipsis, style: docText(10.5, color: kDocGrey)),
                if (d.phone.isNotEmpty) Text('โทร ${phoneFmt(d.phone)}', style: docText(10.5, color: kDocGrey)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('รายงานความเคลื่อนไหวสต็อก', style: docText(18, weight: FontWeight.w700)),
              Text('ช่วง: ${d.periodLabel}', style: docText(11)),
              Text('พิมพ์ ${thaiDateTime(d.printedAt)} · โดย ${d.printedBy}', style: docText(10, color: kDocGrey)),
            ],
          ),
        ],
      ),
    ),
    96,
  ));
  blocks.add(A4Block(
    Container(
      height: 26,
      alignment: Alignment.centerLeft,
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.black, width: 1))),
      child: Text(
        'ประเภท: ${d.typeLabel}'
        '${d.search.isEmpty ? '' : ' · ค้นหา "${d.search}"'}'
        ' · ${groupDigits(d.moves.length)} รายการ · ${groupDigits(productRows.length)} สินค้า',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: docText(10.5, color: kDocGrey),
      ),
    ),
    26,
  ));

  // ── per-type summary boxes ──
  Widget box(String label, int v) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 0.7), borderRadius: BorderRadius.circular(4)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: docText(10, color: kDocGrey)),
              Text('${_signed(v)} ชิ้น', style: docMono(14, weight: FontWeight.w700)),
            ],
          ),
        ),
      );
  blocks.add(A4Block(
    SizedBox(
      height: 54,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          box('ขาย', byType[StockMoveType.sale]!),
          box('คืนสินค้า', byType[StockMoveType.refund]!),
          box('รับเข้า', byType[StockMoveType.receive]!),
          box('ของเสีย', byType[StockMoveType.waste]!),
          box('ปรับยอด/ตรวจนับ', byType[StockMoveType.adjust]! + byType[StockMoveType.count]!),
        ],
      ),
    ),
    54,
  ));
  blocks.add(const A4Block.gap(14));

  Widget section(String t) => SizedBox(
        height: 28,
        child: Align(alignment: Alignment.bottomLeft, child: Text(t, style: docText(13, weight: FontWeight.w700))),
      );

  // ── per-product totals ──
  const totCols = [
    DocCol('สินค้า', flex: 4),
    DocCol('รหัส', width: 70),
    DocCol('ขาย', width: 56, align: TextAlign.right, mono: true),
    DocCol('คืน', width: 50, align: TextAlign.right, mono: true),
    DocCol('รับเข้า', width: 56, align: TextAlign.right, mono: true),
    DocCol('ของเสีย', width: 56, align: TextAlign.right, mono: true),
    DocCol('ปรับ/นับ', width: 56, align: TextAlign.right, mono: true),
    DocCol('สุทธิ', width: 56, align: TextAlign.right, mono: true),
    DocCol('คงเหลือ', width: 58, align: TextAlign.right, mono: true),
  ];
  final totHeader = docTableRow(totCols, [for (final c in totCols) c.title], height: 24, header: true);
  blocks.add(A4Block(section('สรุปตามสินค้า'), 28, keepWithNext: 24 + 20));
  blocks.add(A4Block(totHeader, 24, keepWithNext: 20));
  for (var i = 0; i < productRows.length; i++) {
    final t = productRows[i];
    blocks.add(A4Block(
      docTableRow(totCols, [
        t.name,
        t.code,
        _signed(t.sale),
        _signed(t.refund),
        _signed(t.receive),
        _signed(t.waste),
        _signed(t.adjust),
        _signed(t.net),
        groupDigits(t.balance),
      ], height: 20, shade: i.isOdd),
      20,
      repeatHeader: totHeader,
      repeatHeaderHeight: 24,
    ));
  }
  blocks.add(const A4Block.gap(18));

  // ── movement table ──
  const moveCols = [
    DocCol('วันที่ · เวลา', width: 112),
    DocCol('สินค้า', flex: 3),
    DocCol('ประเภท', width: 58),
    DocCol('จำนวน', width: 52, align: TextAlign.right, mono: true),
    DocCol('คงเหลือ', width: 52, align: TextAlign.right, mono: true),
    DocCol('เหตุผล', flex: 2),
    DocCol('โดย', width: 70),
    DocCol('อ้างอิง', width: 62),
  ];
  final moveHeader = docTableRow(moveCols, [for (final c in moveCols) c.title], height: 24, header: true);
  final shown = d.moves.length > kStockReportMaxRows ? d.moves.sublist(0, kStockReportMaxRows) : d.moves;
  blocks.add(A4Block(
    section(d.moves.length > shown.length
        ? 'รายการเคลื่อนไหว (แสดง ${groupDigits(shown.length)} รายการล่าสุดจาก ${groupDigits(d.moves.length)})'
        : 'รายการเคลื่อนไหว'),
    28,
    keepWithNext: 24 + 20,
  ));
  blocks.add(A4Block(moveHeader, 24, keepWithNext: 20));
  for (var i = 0; i < shown.length; i++) {
    final m = shown[i];
    blocks.add(A4Block(
      docTableRow(moveCols, [
        thaiDateTime(m.at),
        '${m.name} (${m.code})',
        m.type.label,
        _signed(m.delta),
        groupDigits(m.balance),
        m.reason.isEmpty ? '—' : m.reason,
        m.by.isEmpty ? '—' : m.by,
        m.ref.isEmpty ? '—' : m.ref,
      ], height: 20, shade: i.isOdd),
      20,
      repeatHeader: moveHeader,
      repeatHeaderHeight: 24,
    ));
  }
  if (d.moves.isEmpty) {
    blocks.add(A4Block(
      SizedBox(height: 40, child: Center(child: Text('ไม่มีรายการในช่วงที่เลือก', style: docText(11, color: kDocGrey)))),
      40,
    ));
  }

  return A4Pages.pack(
    blocks,
    footer: (p, n) => A4Pages.footerRow('${d.shopName} · รายงานสต็อก ${d.periodLabel} · Thai Prompt POS', p, n),
  );
}
