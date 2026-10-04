// Thaiprompt POS — receipt printer hub (ESC/POS over USB-Windows / LAN / Bluetooth).
//
//   PrinterHub.instance.attach(store);            // once, in main.dart
//   if (PrinterHub.instance.usesEscPos) ...       // settings decide the path
//   await PrinterHub.instance.printPng(png, kickDrawer: true);
//   await PrinterHub.instance.openDrawer();
//
// Settings are read live from the attached PosStore on every call (mode,
// address, queue, paper width, auto-cut), so changes apply immediately. Every
// method also takes an optional [PrinterConfig] so the settings form can test
// a printer before saving. Jobs are serialized: a receipt and a drawer kick
// never interleave on one connection. Failures throw [PrinterException] with
// a Thai message.
//
// by xman studio

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../state/pos_store.dart';
import 'escpos.dart';
import 'printer_transports.dart';

export 'printer_transports.dart' show BluetoothPrinter, PrinterException, parseHostPort;

/// The printer settings as one value — live from the store or a draft.
@immutable
class PrinterConfig {
  /// 'system' · 'windows' · 'network' · 'bluetooth'
  final String mode;

  /// network: host[:port] · bluetooth: MAC (Android) / peripheral UUID (iOS).
  final String address;

  /// Bluetooth device name / Windows queue label.
  final String deviceName;

  /// Windows printer queue (mode 'windows').
  final String queue;
  final int paperWidthMm;
  final bool autoCut;

  const PrinterConfig({
    required this.mode,
    this.address = '',
    this.deviceName = '',
    this.queue = '',
    this.paperWidthMm = 80,
    this.autoCut = true,
  });

  factory PrinterConfig.fromStore(PosStore s) => PrinterConfig(
        mode: s.printerMode,
        address: s.printerAddress,
        deviceName: s.printerDeviceName,
        queue: s.printerName.trim().isNotEmpty ? s.printerName.trim() : s.printerDeviceName.trim(),
        paperWidthMm: s.paperWidthMm,
        autoCut: s.printerAutoCut,
      );

  /// Raw ESC/POS to a Windows queue works on Windows only.
  static bool get windowsRawSupported => !kIsWeb && Platform.isWindows;

  /// print_bluetooth_thermal is used on Android and iOS only.
  static bool get bluetoothSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Printable dots per line (58 mm → 384, 80 mm → 576).
  int get dotWidth => EscPos.dotsForPaper(paperWidthMm);

  /// True when this config prints raw ESC/POS on this platform.
  bool get usesEscPos => switch (mode) {
        'network' => parseHostPort(address) != null,
        'windows' => windowsRawSupported && queue.trim().isNotEmpty,
        'bluetooth' => bluetoothSupported && address.trim().isNotEmpty,
        _ => false,
      };

  /// The link to the printer, or null when [usesEscPos] is false.
  PrinterTransport? get transport {
    if (!usesEscPos) return null;
    switch (mode) {
      case 'network':
        final hp = parseHostPort(address)!;
        return NetworkPrinter(hp.host, port: hp.port);
      case 'windows':
        return WindowsRawPrinter(queue.trim());
      case 'bluetooth':
        return BluetoothPrinter(address.trim(), name: deviceName.trim());
    }
    return null;
  }

  /// Human label for toasts.
  String get label => transport?.label ?? 'เครื่องพิมพ์ของระบบ';

  PrinterConfig copyWith({String? mode, String? address, String? deviceName, String? queue, int? paperWidthMm, bool? autoCut}) =>
      PrinterConfig(
        mode: mode ?? this.mode,
        address: address ?? this.address,
        deviceName: deviceName ?? this.deviceName,
        queue: queue ?? this.queue,
        paperWidthMm: paperWidthMm ?? this.paperWidthMm,
        autoCut: autoCut ?? this.autoCut,
      );
}

class PrinterHub {
  PrinterHub._();
  static final PrinterHub instance = PrinterHub._();

  PosStore? _store;
  Future<void> _tail = Future<void>.value();

  /// Keep a reference to the store; settings are read from it on every call.
  void attach(PosStore store) => _store = store;

  bool get isAttached => _store != null;

  /// Current saved settings (null until [attach]).
  PrinterConfig? get config {
    final s = _store;
    return s == null ? null : PrinterConfig.fromStore(s);
  }

  /// True when receipts go out as raw ESC/POS (mode ≠ system, a printer is
  /// set, and the mode is supported on this platform).
  bool get usesEscPos => config?.usesEscPos ?? false;

  /// Dot width of the configured paper.
  int get dotWidth => config?.dotWidth ?? EscPos.dots80;

  /// Label of the configured printer ('' when not attached).
  String get label => config?.label ?? '';

  /// Print a rendered document: ESC @ → (drawer kick) → GS v 0 raster →
  /// feed 4 → cut (when [cut] and auto-cut are on). The drawer is kicked
  /// first so it opens while the receipt prints.
  Future<void> printPng(
    Uint8List png, {
    bool cut = true,
    bool kickDrawer = false,
    int copies = 1,
    PrinterConfig? config,
  }) async {
    final cfg = _require(config);
    final link = cfg.transport!;
    final MonoImage img;
    try {
      img = await pngToMono(png, targetWidthDots: cfg.dotWidth);
    } catch (e) {
      throw PrinterException('แปลงเอกสารเป็นภาพสำหรับเครื่องพิมพ์ไม่สำเร็จ: $e');
    }
    final job = EscPos()..init();
    if (kickDrawer) job.drawerKick();
    final n = copies.clamp(1, 50);
    for (var i = 0; i < n; i++) {
      // Line spacing 0 while the image streams: a stray LF (some Bluetooth
      // stacks add one per write) then feeds nothing instead of a white gap.
      job
        ..lineSpacing(0)
        ..rasterImage(img, bandRows: link.bandRows)
        ..defaultLineSpacing()
        ..feed(4);
      if (cut && cfg.autoCut) job.cut();
    }
    await _serial(() => link.sendParts(job.parts));
  }

  /// Pulse the cash drawer wired to the receipt printer (pin 2).
  Future<void> openDrawer({PrinterConfig? config}) async {
    final link = _require(config).transport!;
    final job = EscPos()
      ..init()
      ..drawerKick();
    await _serial(() => link.sendParts(job.parts));
  }

  /// Connect and send ESC @ only — proves the path works without using paper.
  Future<void> testConnection({PrinterConfig? config}) async {
    final link = _require(config).transport!;
    final job = EscPos()..init();
    await _serial(() => link.sendParts(job.parts));
  }

  /// Paired (Android) / nearby (iOS) Bluetooth devices. Asks for the Android
  /// "Nearby devices" permission when needed. Throws [PrinterException].
  Future<List<({String name, String mac})>> pairedBluetooth() async {
    if (!PrinterConfig.bluetoothSupported) throw const PrinterException('เครื่องพิมพ์บลูทูธใช้ได้บน Android และ iOS');
    return BluetoothPrinter.paired();
  }

  PrinterConfig _require(PrinterConfig? override) {
    final cfg = override ?? config;
    if (cfg == null || !cfg.usesEscPos) {
      throw const PrinterException('ยังไม่ได้ตั้งค่าเครื่องพิมพ์ใบเสร็จแบบ USB / LAN / บลูทูธ — ตั้งได้ที่ ตั้งค่า › ใบเสร็จและเครื่องพิมพ์');
    }
    return cfg;
  }

  Future<T> _serial<T>(Future<T> Function() task) {
    final run = _tail.then((_) => task());
    _tail = run.then<void>((_) {}, onError: (Object _) {});
    return run;
  }
}
