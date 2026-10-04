// ESC/POS builder, raster banding, 1-bit packing, part grouping, printer
// address parsing, and the LAN / Windows transports against loopback / a
// missing queue — byte-level, no printer hardware needed.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_thaiprompt/core/hardware/escpos.dart';
import 'package:pos_thaiprompt/core/hardware/printer_hub.dart';
import 'package:pos_thaiprompt/core/hardware/printer_transports.dart';
import 'package:pos_thaiprompt/core/print/print_service.dart';

/// Loopback "printer": collects everything one client sends until it closes.
Future<({int port, Future<List<int>> received})> fakePrinter() async {
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final done = Completer<List<int>>();
  server.listen((client) {
    final got = <int>[];
    client.listen(got.addAll, onDone: () {
      client.destroy();
      server.close();
      if (!done.isCompleted) done.complete(got);
    });
  });
  return (port: server.port, received: done.future.timeout(const Duration(seconds: 10)));
}

int indexOfSeq(List<int> hay, List<int> needle, [int from = 0]) {
  for (var i = from; i <= hay.length - needle.length; i++) {
    var ok = true;
    for (var j = 0; j < needle.length; j++) {
      if (hay[i + j] != needle[j]) {
        ok = false;
        break;
      }
    }
    if (ok) return i;
  }
  return -1;
}

/// Opaque RGBA buffer from a per-pixel luminance function (0 = black, 255 = white).
Uint8List rgbaFrom(int w, int h, int Function(int x, int y) lum) {
  final out = Uint8List(w * h * 4);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = (y * w + x) * 4;
      final v = lum(x, y);
      out[i] = v;
      out[i + 1] = v;
      out[i + 2] = v;
      out[i + 3] = 255;
    }
  }
  return out;
}

void main() {
  group('EscPos commands', () {
    test('init = ESC @', () {
      expect((EscPos()..init()).bytes, [0x1B, 0x40]);
    });

    test('feed = ESC d n, clamped to 0–255', () {
      expect((EscPos()..feed(4)).bytes, [0x1B, 0x64, 4]);
      expect((EscPos()..feed(999)).bytes, [0x1B, 0x64, 255]);
      expect((EscPos()..feed(-3)).bytes, [0x1B, 0x64, 0]);
    });

    test('line spacing: ESC 3 n / ESC 2', () {
      expect((EscPos()..lineSpacing(0)).bytes, [0x1B, 0x33, 0]);
      expect((EscPos()..defaultLineSpacing()).bytes, [0x1B, 0x32]);
    });

    test('cut: GS V 66 0 (feed + partial) by default, GS V 1 without feed', () {
      expect((EscPos()..cut()).bytes, [0x1D, 0x56, 66, 0]);
      expect((EscPos()..cut(feed: false)).bytes, [0x1D, 0x56, 1]);
      expect((EscPos()..cut(partial: false)).bytes, [0x1D, 0x56, 65, 0]);
      expect((EscPos()..cut(partial: false, feed: false)).bytes, [0x1D, 0x56, 0]);
    });

    test('drawer kick: ESC p m 25 250', () {
      expect((EscPos()..drawerKick()).bytes, [0x1B, 0x70, 0x00, 0x19, 0xFA]);
      expect((EscPos()..drawerKick(pin: 1)).bytes, [0x1B, 0x70, 0x01, 0x19, 0xFA]);
    });

    test('a job concatenates its parts in order', () {
      final job = EscPos()
        ..init()
        ..drawerKick()
        ..feed(4)
        ..cut();
      expect(job.parts.length, 4);
      expect(job.length, 2 + 5 + 3 + 4);
      expect(job.bytes, [0x1B, 0x40, 0x1B, 0x70, 0x00, 0x19, 0xFA, 0x1B, 0x64, 4, 0x1D, 0x56, 66, 0]);
    });

    test('paper width → dots', () {
      expect(EscPos.dotsForPaper(58), 384);
      expect(EscPos.dotsForPaper(80), 576);
    });
  });

  group('GS v 0 raster', () {
    test('header = GS v 0 m xL xH yL yH followed by the rows', () {
      final bits = Uint8List.fromList([0xF0, 0x0F, 0xAA, 0x55, 0xFF, 0x00]); // 16 px × 3 rows
      final job = EscPos()..raster(bits, 16, 3);
      expect(job.bytes, [0x1D, 0x76, 0x30, 0x00, 2, 0, 3, 0, 0xF0, 0x0F, 0xAA, 0x55, 0xFF, 0x00]);
    });

    test('row bytes = ceil(width / 8)', () {
      final job = EscPos()..raster(Uint8List(2 * 4), 10, 4);
      expect(job.bytes.sublist(0, 8), [0x1D, 0x76, 0x30, 0x00, 2, 0, 4, 0]);
    });

    test('80 mm width: xL = 72, xH = 0 · wide images use xH', () {
      expect((EscPos()..raster(Uint8List(72), 576, 1)).bytes.sublist(4, 8), [72, 0, 1, 0]);
      final bpr = (2100 + 7) >> 3; // 263 bytes = 0x0107
      expect((EscPos()..raster(Uint8List(bpr), 2100, 1)).bytes.sublist(4, 8), [0x07, 0x01, 1, 0]);
    });

    test('splits into bands of at most bandRows rows, each band one part', () {
      const w = 8, h = 300;
      final bits = Uint8List.fromList(List.generate(h, (i) => i & 0xFF));
      final job = EscPos()..raster(bits, w, h, bandRows: 128);
      expect(job.parts.length, 3);
      expect(job.length, 3 * 8 + h);
      final rows = <int>[];
      var offset = 0;
      for (final p in job.parts) {
        expect(p.sublist(0, 6), [0x1D, 0x76, 0x30, 0x00, 1, 0]);
        final n = p[6] | (p[7] << 8);
        rows.add(n);
        expect(p.length, 8 + n); // 1 byte per row
        expect(p.sublist(8), bits.sublist(offset, offset + n)); // rows stay in order
        offset += n;
      }
      expect(rows, [128, 128, 44]);
    });

    test('band height is clamped to 1–255', () {
      final job = EscPos()..raster(Uint8List(600), 8, 600, bandRows: 1000);
      expect([for (final p in job.parts) p[6] | (p[7] << 8)], [255, 255, 90]);
      final tiny = EscPos()..raster(Uint8List(3), 8, 3, bandRows: 0);
      expect(tiny.parts.length, 3);
    });

    test('default band height', () {
      final job = EscPos()..raster(Uint8List(72 * 300), 576, 300);
      expect([for (final p in job.parts) p[6] | (p[7] << 8)], [128, 128, 44]);
    });

    test('zero-height image adds nothing; short data throws', () {
      expect((EscPos()..raster(Uint8List(0), 8, 0)).length, 0);
      expect(() => EscPos().raster(Uint8List(5), 16, 3), throwsArgumentError);
      expect(() => EscPos().raster(Uint8List(5), 0, 3), throwsArgumentError);
    });
  });

  group('groupParts', () {
    test('packs whole parts up to maxBytes and never splits one', () {
      final parts = [
        Uint8List.fromList([1, 1]),
        Uint8List.fromList([2, 2, 2]),
        Uint8List.fromList([3]),
        Uint8List.fromList(List.filled(9, 4)), // bigger than max → alone
        Uint8List.fromList([5, 5]),
      ];
      final chunks = groupParts(parts, 6);
      expect(chunks.map((c) => c.toList()).toList(), [
        [1, 1, 2, 2, 2, 3],
        [4, 4, 4, 4, 4, 4, 4, 4, 4],
        [5, 5],
      ]);
    });

    test('raster bands stay intact when grouped for Bluetooth', () {
      final job = EscPos()
        ..init()
        ..lineSpacing(0)
        ..raster(Uint8List(72 * 100), 576, 100, bandRows: 24)
        ..defaultLineSpacing()
        ..feed(4)
        ..cut();
      final chunks = groupParts(job.parts, 2048);
      expect(chunks.expand((c) => c).toList(), job.bytes.toList());
      // Every chunk after the first starts exactly at a command boundary.
      for (final c in chunks.skip(1)) {
        expect(c[0] == 0x1D || c[0] == 0x1B, isTrue);
      }
      expect(chunks.every((c) => c.length <= 2048), isTrue);
    });
  });

  group('monoFromRgba', () {
    test('packs MSB first, 1 = black, rows padded to whole bytes', () {
      // 10 × 2: row 0 black at x = 0, 2, 9 · row 1 black at x = 1, 8
      const blacks = {(0, 0), (2, 0), (9, 0), (1, 1), (8, 1)};
      final rgba = rgbaFrom(10, 2, (x, y) => blacks.contains((x, y)) ? 0 : 255);
      final m = monoFromRgba(rgba, 10, 2);
      expect(m.width, 10);
      expect(m.height, 2);
      expect(m.bytesPerRow, 2);
      expect(m.bits, [0xA0, 0x40, 0x40, 0x80]);
    });

    test('luminance threshold: below = black, at/above = white', () {
      final m = monoFromRgba(rgbaFrom(2, 1, (x, _) => x == 0 ? 159 : 160), 2, 1, threshold: 160);
      expect(m.bits, [0x80]);
      final lower = monoFromRgba(rgbaFrom(2, 1, (x, _) => x == 0 ? 159 : 160), 2, 1, threshold: 100);
      expect(lower.bits, [0x00]);
    });

    test('uses Rec.601 weights (pure red / green / blue)', () {
      // red 255 → lum 76.2 (black) · green 255 → 149.7 (black) · blue 255 → 29 (black)
      // red+green → 225.9 (white)
      final rgba = Uint8List.fromList([
        255, 0, 0, 255, //
        0, 255, 0, 255,
        0, 0, 255, 255,
        255, 255, 0, 255,
      ]);
      expect(monoFromRgba(rgba, 4, 1).bits, [0xE0]);
    });

    test('premultiplied transparency composites over white paper', () {
      final rgba = Uint8List.fromList([
        0, 0, 0, 0, // fully transparent → white
        0, 0, 0, 128, // 50 % black → lum 127 → black
        0, 0, 0, 64, // 25 % black → lum 191 → white
        0, 0, 0, 255, // black
      ]);
      expect(monoFromRgba(rgba, 4, 1).bits, [0x50]);
    });

    test('feeds raster() directly', () {
      final m = monoFromRgba(rgbaFrom(16, 2, (x, y) => x < 8 ? 0 : 255), 16, 2);
      final job = EscPos()..rasterImage(m);
      expect(job.bytes, [0x1D, 0x76, 0x30, 0x00, 2, 0, 2, 0, 0xFF, 0x00, 0xFF, 0x00]);
    });

    test('rejects a buffer that does not match the size', () {
      expect(() => monoFromRgba(Uint8List(10), 4, 4), throwsArgumentError);
    });
  });

  testWidgets('pngToMono decodes and scales a real PNG to the dot width', (tester) async {
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(const Rect.fromLTWH(0, 0, 80, 20), Paint()..color = Colors.white);
      canvas.drawRect(const Rect.fromLTWH(0, 0, 40, 20), Paint()..color = Colors.black);
      final image = await recorder.endRecording().toImage(80, 20);
      final png = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
      image.dispose();

      final m = await pngToMono(png, targetWidthDots: 40);
      expect(m.width, 40);
      expect(m.height, 10);
      expect(m.bytesPerRow, 5);
      for (var y = 0; y < m.height; y++) {
        final row = m.bits.sublist(y * 5, y * 5 + 5);
        expect(row.sublist(0, 2), [0xFF, 0xFF], reason: 'left half black (row $y)');
        expect(row.sublist(3), [0x00, 0x00], reason: 'right half white (row $y)');
      }
    });
  });

  group('printer config', () {
    test('parseHostPort', () {
      expect(parseHostPort('192.168.1.50'), (host: '192.168.1.50', port: 9100));
      expect(parseHostPort(' 192.168.1.50:9101 '), (host: '192.168.1.50', port: 9101));
      expect(parseHostPort('printer.local'), (host: 'printer.local', port: 9100));
      expect(parseHostPort('[fe80::1]:9100'), (host: 'fe80::1', port: 9100));
      expect(parseHostPort('fe80::1'), (host: 'fe80::1', port: 9100));
      expect(parseHostPort(''), isNull);
      expect(parseHostPort('1.2.3.4:0'), isNull);
      expect(parseHostPort('1.2.3.4:70000'), isNull);
      expect(parseHostPort('1.2.3.4:abc'), isNull);
      expect(parseHostPort('bad host'), isNull);
    });

    test('usesEscPos: system never, network only with a valid address', () {
      expect(const PrinterConfig(mode: 'system', address: '1.2.3.4').usesEscPos, isFalse);
      expect(const PrinterConfig(mode: 'network', address: '').usesEscPos, isFalse);
      expect(const PrinterConfig(mode: 'network', address: '1.2.3.4:99999').usesEscPos, isFalse);
      const net = PrinterConfig(mode: 'network', address: '10.0.0.7:9100', paperWidthMm: 58);
      expect(net.usesEscPos, isTrue);
      expect(net.dotWidth, 384);
      expect(net.label, '10.0.0.7:9100');
      expect(const PrinterConfig(mode: 'windows').usesEscPos, isFalse); // no queue
      expect(const PrinterConfig(mode: 'bluetooth').usesEscPos, isFalse); // no device
    });

    test('hub without a store falls back to the system path', () async {
      expect(PrinterHub.instance.usesEscPos, isFalse);
      await expectLater(PrinterHub.instance.openDrawer(), throwsA(isA<PrinterException>()));
    });
  });

  group('transports (no hardware)', () {
    test('NetworkPrinter delivers the exact bytes over TCP', () async {
      final fake = await fakePrinter();
      final job = EscPos()
        ..init()
        ..raster(Uint8List.fromList(List.generate(72 * 40, (i) => i & 0xFF)), 576, 40)
        ..feed(4)
        ..cut()
        ..drawerKick();
      await NetworkPrinter('127.0.0.1', port: fake.port).sendParts(job.parts);
      expect(await fake.received, job.bytes.toList());
    });

    test('NetworkPrinter: closed port → Thai PrinterException', () async {
      final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = s.port;
      await s.close();
      await expectLater(
        NetworkPrinter('127.0.0.1', port: port).send(const [0x1B, 0x40]),
        throwsA(isA<PrinterException>().having((e) => e.message, 'message', contains('127.0.0.1:$port'))),
      );
    });

    test('WindowsRawPrinter: missing queue → Thai PrinterException, nothing printed', () async {
      await expectLater(
        const WindowsRawPrinter('TP-POS no such printer 7f3a').send(const [0x1B, 0x40]),
        throwsA(isA<PrinterException>().having((e) => e.message, 'message', contains('TP-POS no such printer 7f3a'))),
      );
    }, skip: !Platform.isWindows);

    testWidgets('PrinterHub.printPng → init, kick, raster bands, feed, cut over LAN', (tester) async {
      await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        Canvas(recorder)
          ..drawRect(const Rect.fromLTWH(0, 0, 560, 300), Paint()..color = Colors.white)
          ..drawRect(const Rect.fromLTWH(20, 20, 200, 60), Paint()..color = Colors.black);
        final image = await recorder.endRecording().toImage(560, 300);
        final png = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
        image.dispose();

        final fake = await fakePrinter();
        final cfg = PrinterConfig(mode: 'network', address: '127.0.0.1:${fake.port}', paperWidthMm: 80, autoCut: true);
        await PrinterHub.instance.printPng(png, kickDrawer: true, config: cfg);
        final got = await fake.received;

        expect(got.sublist(0, 7), [0x1B, 0x40, 0x1B, 0x70, 0x00, 0x19, 0xFA]); // init + drawer first
        expect(got.sublist(7, 10), [0x1B, 0x33, 0x00]); // line spacing 0 while streaming
        // 560 px scaled to 576 dots → 72 bytes/row, 300 × 576/560 ≈ 309 rows in 128-row bands.
        final first = indexOfSeq(got, const [0x1D, 0x76, 0x30, 0x00]);
        expect(first, 10);
        expect(got.sublist(first + 4, first + 8), [72, 0, 128, 0]);
        var rows = 0, at = first;
        while (at >= 0) {
          rows += got[at + 6] | (got[at + 7] << 8);
          at = indexOfSeq(got, const [0x1D, 0x76, 0x30, 0x00], at + 8 + 72 * (got[at + 6] | (got[at + 7] << 8)));
        }
        expect(rows, inInclusiveRange(308, 310));
        expect(got.sublist(got.length - 9), [0x1B, 0x32, 0x1B, 0x64, 4, 0x1D, 0x56, 66, 0]); // ESC 2 · feed 4 · cut
      });
    });

    testWidgets('PrinterHub.printPng without auto-cut sends no GS V', (tester) async {
      await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 384, 50), Paint()..color = Colors.white);
        final image = await recorder.endRecording().toImage(384, 50);
        final png = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
        image.dispose();

        final fake = await fakePrinter();
        final cfg = PrinterConfig(mode: 'network', address: '127.0.0.1:${fake.port}', paperWidthMm: 58, autoCut: false);
        await PrinterHub.instance.printPng(png, config: cfg);
        final got = await fake.received;
        expect(got.sublist(got.length - 5), [0x1B, 0x32, 0x1B, 0x64, 4]);
        expect(got.sublist(5, 11), [0x1D, 0x76, 0x30, 0x00, 48, 0]); // 58 mm → 384 dots → 48 bytes/row
        expect(indexOfSeq(got, const [0x1D, 0x56]), -1);
      });
    });
    testWidgets('PrintService.printDoc routes roll media through the hub (80 mm → 576 dots)', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(home: Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      })));
      await tester.runAsync(() async {
        final fake = await fakePrinter();
        final cfg = PrinterConfig(mode: 'network', address: '127.0.0.1:${fake.port}', paperWidthMm: 80);
        final res = await PrintService.printDoc(
          ctx,
          const Padding(padding: EdgeInsets.all(16), child: SizedBox(height: 120, child: ColoredBox(color: Colors.black))),
          jobName: 'test',
          medium: PrintMedium.roll80,
          hardware: cfg,
        );
        expect(res.ok, isTrue, reason: res.message);
        expect(res.message, contains('127.0.0.1:${fake.port}'));
        final got = await fake.received;
        final first = indexOfSeq(got, const [0x1D, 0x76, 0x30, 0x00]);
        expect(first, greaterThan(0));
        expect(got.sublist(first + 4, first + 6), [72, 0]);
      });
    });

    testWidgets('PrintService.printDoc turns a dead printer into a Thai PrintResult', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(home: Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      })));
      await tester.runAsync(() async {
        final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
        final port = s.port;
        await s.close();
        final res = await PrintService.printDoc(ctx, const SizedBox(height: 40), jobName: 'x', medium: PrintMedium.roll58,
            hardware: PrinterConfig(mode: 'network', address: '127.0.0.1:$port', paperWidthMm: 58));
        expect(res.ok, isFalse);
        expect(res.message, startsWith('พิมพ์ไม่สำเร็จ'));
      });
    });
  });
}
