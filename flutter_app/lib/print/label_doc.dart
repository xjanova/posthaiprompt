// Thaiprompt POS — Product barcode label (50×30 mm sticker), print-ready.
//
// A pure black-on-white widget sized exactly to the label (400×240 logical px
// = PrintMedium.label50x30 render width), used both as the on-screen preview
// and for PrintService.printDoc. Symbology is automatic: EAN-13 when the scan
// code is a 13-digit EAN with a valid check digit, otherwise Code 128.
//
// by xman studio

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';

import '../core/format.dart';
import '../theme/nv_tokens.dart';

enum LabelSymbology { ean13, code128 }

extension LabelSymbologyX on LabelSymbology {
  String get label => switch (this) {
        LabelSymbology.ean13 => 'EAN-13',
        LabelSymbology.code128 => 'Code 128',
      };
}

/// True for a 13-digit EAN with a correct check digit.
bool isValidEan13(String s) {
  if (!RegExp(r'^\d{13}$').hasMatch(s)) return false;
  var sum = 0;
  for (var i = 0; i < 12; i++) {
    final d = s.codeUnitAt(i) - 48;
    sum += i.isEven ? d : d * 3;
  }
  return (10 - sum % 10) % 10 == s.codeUnitAt(12) - 48;
}

LabelSymbology symbologyFor(String data) => isValidEan13(data) ? LabelSymbology.ean13 : LabelSymbology.code128;

/// Code 128 only encodes ASCII — non-ASCII codes can't be printed as bars.
bool canEncodeLabel(String data) =>
    data.isNotEmpty && (isValidEan13(data) || Barcode.code128().isValid(data));

class LabelDoc extends StatelessWidget {
  static const double width = 400;
  static const double height = 240;

  final String name;
  final int price;
  final String data; // scan code (barcode, or product code when none)
  final bool showPrice;
  final bool showShop;
  final String shopName;

  const LabelDoc({
    super.key,
    required this.name,
    required this.price,
    required this.data,
    this.showPrice = true,
    this.showShop = false,
    this.shopName = '',
  });

  LabelSymbology get symbology => symbologyFor(data);

  @override
  Widget build(BuildContext context) {
    TextStyle t(double s, [FontWeight w = FontWeight.w600]) =>
        TextStyle(fontFamily: Nv.fontUi, fontSize: s, fontWeight: w, color: Colors.black, height: 1.2);
    TextStyle m(double s, [FontWeight w = FontWeight.w700]) =>
        TextStyle(
            fontFamily: Nv.fontMono,
            fontFamilyFallback: Nv.monoFallback, // ฿ glyph comes from Anuphan
            fontSize: s,
            fontWeight: w,
            color: Colors.black,
            fontFeatures: Nv.tnum,
            height: 1.1);

    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showShop && shopName.isNotEmpty)
                Text(shopName, maxLines: 1, overflow: TextOverflow.ellipsis, style: t(13, FontWeight.w500)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: t(19, FontWeight.w700))),
                  if (showPrice) ...[
                    const SizedBox(width: 10),
                    Text(baht(price), style: m(28, FontWeight.w800)),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) => BarcodeWidget(
                    barcode: symbology == LabelSymbology.ean13 ? Barcode.ean13() : Barcode.code128(),
                    data: data,
                    width: c.maxWidth,
                    height: c.maxHeight,
                    drawText: true,
                    style: m(15, FontWeight.w500),
                    errorBuilder: (_, _) => Center(
                      child: Text('พิมพ์บาร์โค้ดนี้ไม่ได้: $data', textAlign: TextAlign.center, style: t(13)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
