// Thaiprompt POS — ESC/POS byte builder + PNG → 1-bit raster.
//
// Thai text is never sent as characters (thermal code pages can't stack
// vowels/tone marks). Every document is rendered by Flutter to a PNG at the
// printer's dot width, thresholded to 1 bit and sent as GS v 0 raster bands —
// so what prints is pixel-identical to the on-screen preview.
//
//   final img = await pngToMono(png, targetWidthDots: EscPos.dotsForPaper(80));
//   final job = EscPos()..init()..lineSpacing(0)..rasterImage(img)
//                       ..defaultLineSpacing()..feed(4)..cut()..drawerKick();
//   transport.sendParts(job.parts);   // or job.bytes
//
// The builder keeps every command (and every raster band) as an atomic
// "part", so transports that must split a job (Bluetooth) only split between
// commands — never inside an image band.
//
// by xman studio

import 'dart:typed_data';
import 'dart:ui' as ui;

/// 1-bit image: row-major, MSB first, 1 = black dot, rows padded to whole bytes.
class MonoImage {
  final Uint8List bits;
  final int width;
  final int height;
  const MonoImage(this.bits, this.width, this.height);

  int get bytesPerRow => (width + 7) >> 3;
}

/// Fluent ESC/POS command builder (pure Dart — no I/O).
class EscPos {
  /// Printable dots per line at 203 dpi.
  static const int dots58 = 384;
  static const int dots80 = 576;

  /// Rows per GS v 0 command. Small enough for the receive buffer of cheap
  /// USB/LAN printers, big enough to avoid visible banding.
  static const int defaultBandRows = 128;

  static int dotsForPaper(int paperWidthMm) => paperWidthMm == 58 ? dots58 : dots80;

  final List<Uint8List> _parts = <Uint8List>[];
  int _length = 0;

  /// Atomic commands / raster bands, in order.
  List<Uint8List> get parts => List<Uint8List>.unmodifiable(_parts);

  /// The whole job as one buffer.
  Uint8List get bytes {
    final out = Uint8List(_length);
    var o = 0;
    for (final p in _parts) {
      out.setAll(o, p);
      o += p.length;
    }
    return out;
  }

  int get length => _length;

  void _add(Uint8List part) {
    if (part.isEmpty) return;
    _parts.add(part);
    _length += part.length;
  }

  /// Raw bytes appended as one atomic part.
  EscPos raw(List<int> data) {
    _add(Uint8List.fromList(data));
    return this;
  }

  /// ESC @ — reset the printer and clear its buffer.
  EscPos init() => raw(const [0x1B, 0x40]);

  /// ESC 3 n — line spacing in motion units. 0 makes a stray LF feed nothing.
  EscPos lineSpacing(int n) => raw([0x1B, 0x33, n.clamp(0, 255)]);

  /// ESC 2 — default line spacing (≈ 1/6 inch).
  EscPos defaultLineSpacing() => raw(const [0x1B, 0x32]);

  /// ESC d n — print and feed [lines] lines (0–255).
  EscPos feed(int lines) => raw([0x1B, 0x64, lines.clamp(0, 255)]);

  /// GS V — cut the paper.
  ///  * [feed] = true (default): function B, `GS V 66|65 0` — the printer first
  ///    feeds the last printed line past its own cutter, then cuts.
  ///  * [feed] = false: function A, `GS V 1|0` — cut right where the paper is.
  ///  * [partial] = true (default) leaves a small hinge (`66` / `1`);
  ///    false = full cut (`65` / `0`). Full-cut-only cutters ignore the hinge.
  EscPos cut({bool partial = true, bool feed = true}) {
    if (feed) return raw([0x1D, 0x56, partial ? 66 : 65, 0x00]);
    return raw([0x1D, 0x56, partial ? 0x01 : 0x00]);
  }

  /// ESC p m t1 t2 — pulse the cash drawer. [pin] 0 = connector pin 2
  /// (standard), 1 = pin 5. 50 ms on / 500 ms off.
  EscPos drawerKick({int pin = 0}) => raw([0x1B, 0x70, pin == 1 ? 0x01 : 0x00, 0x19, 0xFA]);

  /// GS v 0 — print a 1-bit image ([monoBits] = MSB-first rows of
  /// ceil(widthPx / 8) bytes), split into bands of at most [bandRows] rows.
  /// Each band (8-byte header + its rows) is one atomic part.
  EscPos raster(Uint8List monoBits, int widthPx, int heightPx, {int bandRows = defaultBandRows}) {
    if (widthPx <= 0 || heightPx < 0) throw ArgumentError('ขนาดภาพไม่ถูกต้อง ($widthPx×$heightPx)');
    final bpr = (widthPx + 7) >> 3;
    if (bpr > 0xFFFF) throw ArgumentError('ภาพกว้างเกินไป ($widthPx จุด)');
    if (monoBits.length < bpr * heightPx) {
      throw ArgumentError('ข้อมูลภาพไม่ครบ: ต้องมี ${bpr * heightPx} ไบต์ แต่มี ${monoBits.length}');
    }
    final band = bandRows.clamp(1, 255);
    for (var y = 0; y < heightPx; y += band) {
      final rows = (heightPx - y) < band ? heightPx - y : band;
      final part = Uint8List(8 + rows * bpr)
        ..setAll(0, [0x1D, 0x76, 0x30, 0x00, bpr & 0xFF, (bpr >> 8) & 0xFF, rows & 0xFF, (rows >> 8) & 0xFF])
        ..setRange(8, 8 + rows * bpr, monoBits, y * bpr);
      _add(part);
    }
    return this;
  }

  EscPos rasterImage(MonoImage img, {int bandRows = defaultBandRows}) => raster(img.bits, img.width, img.height, bandRows: bandRows);
}

/// Pack consecutive atomic [parts] into chunks of at most [maxBytes] without
/// ever splitting a part (a part larger than [maxBytes] becomes its own chunk).
List<Uint8List> groupParts(List<Uint8List> parts, int maxBytes) {
  final out = <Uint8List>[];
  final pending = <Uint8List>[];
  var size = 0;
  void flush() {
    if (pending.isEmpty) return;
    final chunk = Uint8List(size);
    var o = 0;
    for (final p in pending) {
      chunk.setAll(o, p);
      o += p.length;
    }
    out.add(chunk);
    pending.clear();
    size = 0;
  }

  for (final p in parts) {
    if (p.isEmpty) continue;
    if (size > 0 && size + p.length > maxBytes) flush();
    pending.add(p);
    size += p.length;
  }
  flush();
  return out;
}

/// RGBA8888 pixels (premultiplied alpha, as `dart:ui` rawRgba delivers) →
/// 1-bit (luminance below [threshold] = black). Transparency is composited
/// over white paper. Pure — used by [pngToMono] and the tests.
MonoImage monoFromRgba(Uint8List rgba, int width, int height, {int threshold = 160}) {
  if (width <= 0 || height < 0 || rgba.length < width * height * 4) {
    throw ArgumentError('ข้อมูล RGBA ไม่ตรงกับขนาด $width×$height');
  }
  final bpr = (width + 7) >> 3;
  final out = Uint8List(bpr * height);
  // Integer luminance ×1000 (Rec.601) against threshold ×1000 — no floats, so
  // every platform produces identical bits.
  final limit = threshold * 1000;
  var p = 0;
  for (var y = 0; y < height; y++) {
    final row = y * bpr;
    for (var x = 0; x < width; x++, p += 4) {
      final a = rgba[p + 3];
      var lum = rgba[p] * 299 + rgba[p + 1] * 587 + rgba[p + 2] * 114; // 0..255000
      if (a < 255) lum += (255 - a) * 1000; // premultiplied → over white
      if (lum < limit) out[row + (x >> 3)] |= 0x80 >> (x & 7);
    }
  }
  return MonoImage(out, width, height);
}

/// Decode [png] scaled to [targetWidthDots] (aspect kept) and threshold it.
Future<MonoImage> pngToMono(Uint8List png, {required int targetWidthDots, int threshold = 160}) async {
  final codec = await ui.instantiateImageCodec(png, targetWidth: targetWidthDots);
  try {
    final frame = await codec.getNextFrame();
    final image = frame.image;
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) throw StateError('ถอดรหัสภาพใบเสร็จไม่ได้');
      return monoFromRgba(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), image.width, image.height,
          threshold: threshold);
    } finally {
      image.dispose();
    }
  } finally {
    codec.dispose();
  }
}
