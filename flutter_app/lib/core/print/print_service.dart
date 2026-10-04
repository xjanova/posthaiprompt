// Thaiprompt POS — Printing (receipts, Z-reports, labels, invoices, POs).
//
// Thai text needs real OpenType shaping (stacked vowels/tone marks) that PDF
// text drawing doesn't do, so documents are Flutter widgets rendered OFFSCREEN
// to a high-DPI PNG (Flutter's HarfBuzz shaping, bundled Anuphan font), then
// wrapped in a PDF page sized for the medium (58/80 mm roll, A4, 100×150 mm
// label). Printing goes straight to the printer chosen in Settings when it is
// found, otherwise the system print dialog opens. Share/save uses the same PDF.
//
// by xman studio

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../theme/nv_tokens.dart';

/// Paper / medium for a document.
enum PrintMedium { roll58, roll80, a4, label100x150, label50x30 }

extension PrintMediumX on PrintMedium {
  /// Logical render width (px) — tuned so 1 logical px ≈ 1 printer dot at 203 dpi for rolls.
  double get renderWidth => switch (this) {
        PrintMedium.roll58 => 384,
        PrintMedium.roll80 => 560,
        PrintMedium.a4 => 794, // 96 dpi A4 width
        PrintMedium.label100x150 => 600,
        PrintMedium.label50x30 => 400,
      };

  double get widthMm => switch (this) {
        PrintMedium.roll58 => 58,
        PrintMedium.roll80 => 80,
        PrintMedium.a4 => 210,
        PrintMedium.label100x150 => 100,
        PrintMedium.label50x30 => 50,
      };

  /// Fixed height for sheet media (null = grows with content, i.e. rolls).
  double? get heightMm => switch (this) {
        PrintMedium.a4 => 297,
        PrintMedium.label100x150 => 150,
        PrintMedium.label50x30 => 30,
        _ => null,
      };

  bool get isRoll => this == PrintMedium.roll58 || this == PrintMedium.roll80;
}

class PrintResult {
  final bool ok;
  final String message;
  const PrintResult(this.ok, this.message);
}

class PrintService {
  PrintService._();

  /// Render [doc] offscreen to PNG at [width] logical px. Asset images used by
  /// the doc must be listed in [precache] so they are decoded before capture.
  static Future<Uint8List> renderPng(
    BuildContext context,
    Widget doc, {
    required double width,
    double pixelRatio = 2.4,
    List<String> precache = const [],
  }) async {
    for (final a in precache) {
      try {
        await precacheImage(AssetImage(a), context);
      } catch (_) {}
    }
    if (!context.mounted) throw StateError('context unmounted');
    final view = View.of(context);
    final theme = Theme.of(context);

    final boundary = RenderRepaintBoundary();
    final renderView = RenderView(
      view: view,
      child: boundary,
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints(minWidth: width, maxWidth: width, maxHeight: 30000),
        devicePixelRatio: 1,
      ),
    );
    final pipeline = PipelineOwner()..rootNode = renderView;
    renderView.prepareInitialFrame();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    final root = RenderObjectToWidgetAdapter<RenderBox>(
      container: boundary,
      child: MediaQuery(
        data: MediaQueryData(size: Size(width, 30000), devicePixelRatio: 1, textScaler: TextScaler.noScaling),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Theme(
            data: theme,
            child: DefaultTextStyle(
              style: const TextStyle(fontFamily: Nv.fontUi, color: Colors.black, fontSize: 20),
              child: SizedBox(width: width, child: ColoredBox(color: Colors.white, child: doc)),
            ),
          ),
        ),
      ),
    ).attachToRenderTree(buildOwner);

    void pump() {
      buildOwner.buildScope(root);
      buildOwner.finalizeTree();
      pipeline.flushLayout();
      pipeline.flushCompositingBits();
      pipeline.flushPaint();
    }

    pump();
    // second pass after a microtask so cached images / painters settle
    await Future<void>.delayed(const Duration(milliseconds: 30));
    pump();

    final img = await boundary.toImage(pixelRatio: pixelRatio);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    return bytes!.buffer.asUint8List();
  }

  /// Wrap PNG pages into a PDF sized for [medium].
  static Future<Uint8List> pdfFromPngs(List<Uint8List> pngs, PrintMedium medium) async {
    final doc = pw.Document(title: 'Thai Prompt POS', creator: 'Thai Prompt POS');
    for (final png in pngs) {
      final image = pw.MemoryImage(png);
      final w = medium.widthMm * PdfPageFormat.mm;
      final ratio = (image.height ?? 1) / (image.width ?? 1);
      final h = medium.heightMm != null ? medium.heightMm! * PdfPageFormat.mm : w * ratio;
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat(w, h, marginAll: 0),
        build: (_) => pw.Image(image, fit: medium.heightMm == null ? pw.BoxFit.fitWidth : pw.BoxFit.contain),
      ));
    }
    return doc.save();
  }

  /// Render + print. Uses [printerName] directly when it exists, else the
  /// system dialog. Returns a Thai status message for a toast.
  static Future<PrintResult> printDoc(
    BuildContext context,
    Widget doc, {
    required String jobName,
    PrintMedium medium = PrintMedium.roll80,
    String printerName = '',
    List<String> precache = const [],
    int copies = 1,
  }) async {
    try {
      final png = await renderPng(context, doc, width: medium.renderWidth, precache: precache);
      final pdf = await pdfFromPngs(List.filled(copies.clamp(1, 50), png), medium);
      final format = PdfPageFormat(medium.widthMm * PdfPageFormat.mm,
          (medium.heightMm ?? 297) * PdfPageFormat.mm);
      if (printerName.isNotEmpty) {
        try {
          final printers = await Printing.listPrinters();
          final match = printers.where((p) => p.name == printerName);
          if (match.isNotEmpty) {
            final ok = await Printing.directPrintPdf(printer: match.first, onLayout: (_) async => pdf, name: jobName, format: format);
            return ok ? PrintResult(true, 'ส่งงานพิมพ์ไปที่ $printerName แล้ว') : const PrintResult(false, 'เครื่องพิมพ์ปฏิเสธงานพิมพ์');
          }
        } catch (_) {
          // listing unsupported on this platform → fall back to the dialog
        }
      }
      final ok = await Printing.layoutPdf(onLayout: (_) async => pdf, name: jobName, format: format);
      return ok ? const PrintResult(true, 'ส่งงานพิมพ์แล้ว') : const PrintResult(false, 'ยกเลิกการพิมพ์');
    } catch (e) {
      return PrintResult(false, 'พิมพ์ไม่สำเร็จ: ${_friendly(e)}');
    }
  }

  /// Render to PDF and open the platform share / save sheet.
  static Future<PrintResult> shareDoc(
    BuildContext context,
    Widget doc, {
    required String fileName,
    PrintMedium medium = PrintMedium.roll80,
    List<String> precache = const [],
  }) async {
    try {
      final png = await renderPng(context, doc, width: medium.renderWidth, precache: precache);
      final pdf = await pdfFromPngs([png], medium);
      final ok = await Printing.sharePdf(bytes: pdf, filename: fileName.endsWith('.pdf') ? fileName : '$fileName.pdf');
      return ok ? const PrintResult(true, 'บันทึก/แชร์ไฟล์ PDF แล้ว') : const PrintResult(false, 'ยกเลิก');
    } catch (e) {
      return PrintResult(false, 'สร้าง PDF ไม่สำเร็จ: ${_friendly(e)}');
    }
  }

  /// Printers known to the OS (empty when the platform can't list them).
  static Future<List<String>> printers() async {
    try {
      final list = await Printing.listPrinters();
      return list.map((p) => p.name).toList();
    } catch (_) {
      return const [];
    }
  }

  static String _friendly(Object e) {
    final s = e.toString();
    return s.length > 120 ? '${s.substring(0, 120)}…' : s;
  }
}
