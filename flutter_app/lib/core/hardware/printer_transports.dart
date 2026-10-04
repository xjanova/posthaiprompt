// Thaiprompt POS — where ESC/POS bytes go.
//
//   NetworkPrinter     LAN / Wi-Fi printers, raw TCP (port 9100)
//   WindowsRawPrinter  any Windows printer queue (USB thermal printers) via the
//                      spooler with the RAW datatype — no driver rendering
//   BluetoothPrinter   Android SPP / iOS BLE via print_bluetooth_thermal
//                      (Sunmi's built-in printer = paired "InnerPrinter")
//
// Every failure surfaces as a PrinterException with a Thai message that can
// go straight into a toast.
//
// by xman studio

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:win32/win32.dart' as w32;

import 'escpos.dart';

class PrinterException implements Exception {
  final String message;
  const PrinterException(this.message);

  @override
  String toString() => message;
}

abstract class PrinterTransport {
  const PrinterTransport();

  /// Deliver [bytes] to the printer. Throws [PrinterException].
  Future<void> send(List<int> bytes);

  /// Human label for toasts ("192.168.1.50:9100", "POS-80", "InnerPrinter").
  String get label;

  /// Raster band height that suits this link (see [EscPos.raster]).
  int get bandRows => EscPos.defaultBandRows;

  /// Deliver a job given as atomic command parts ([EscPos.parts]). Links that
  /// must split a job override this and split only between parts.
  Future<void> sendParts(List<Uint8List> parts) {
    final all = BytesBuilder(copy: false);
    for (final p in parts) {
      all.add(p);
    }
    return send(all.takeBytes());
  }
}

bool get _isWindows => !kIsWeb && Platform.isWindows;
bool get _isAndroid => !kIsWeb && Platform.isAndroid;
bool get _isIOS => !kIsWeb && Platform.isIOS;

// ─────────────────────────── network (TCP 9100) ───────────────────────────

/// "host", "host:port", "[v6]:port" or a bare IPv6 → (host, port). Null when
/// the host is empty / has spaces or the port is outside 1–65535.
({String host, int port})? parseHostPort(String raw, {int defaultPort = 9100}) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  String host;
  var port = defaultPort;
  if (t.startsWith('[')) {
    final end = t.indexOf(']');
    if (end <= 1) return null;
    host = t.substring(1, end);
    final rest = t.substring(end + 1);
    if (rest.isNotEmpty) {
      if (!rest.startsWith(':')) return null;
      final p = int.tryParse(rest.substring(1));
      if (p == null) return null;
      port = p;
    }
  } else if (':'.allMatches(t).length == 1) {
    final i = t.indexOf(':');
    host = t.substring(0, i);
    final p = int.tryParse(t.substring(i + 1));
    if (p == null) return null;
    port = p;
  } else {
    host = t; // plain host or bare IPv6
  }
  if (host.isEmpty || host.contains(RegExp(r'\s')) || port < 1 || port > 65535) return null;
  return (host: host, port: port);
}

class NetworkPrinter extends PrinterTransport {
  final String host;
  final int port;
  const NetworkPrinter(this.host, {this.port = 9100});

  @override
  String get label => host.contains(':') ? '[$host]:$port' : '$host:$port';

  @override
  Future<void> send(List<int> bytes) async {
    Socket? socket;
    StreamSubscription<Uint8List>? sub;
    try {
      socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));
      // Drain whatever the printer reports back (status bytes) so the close
      // below is a clean FIN, not a reset that could drop unsent data.
      sub = socket.listen((_) {}, onError: (Object _) {}, cancelOnError: true);
      socket.add(bytes);
      await socket.flush().timeout(const Duration(seconds: 30));
      await socket.close().timeout(const Duration(seconds: 3), onTimeout: () => null);
    } on SocketException catch (e) {
      throw PrinterException(_socketMessage(e));
    } on TimeoutException {
      throw PrinterException('เครื่องพิมพ์ $label ไม่ตอบสนอง (หมดเวลาส่งข้อมูล) — ตรวจกระดาษและสายแลน');
    } finally {
      await sub?.cancel();
      socket?.destroy();
    }
  }

  String _socketMessage(SocketException e) {
    final code = e.osError?.errorCode;
    final text = '${e.message} ${e.osError?.message ?? ''}'.toLowerCase();
    if (code == 10061 || code == 111 || code == 61 || text.contains('refused')) {
      return 'เครื่องพิมพ์ที่ $label ปฏิเสธการเชื่อมต่อ — ตรวจหมายเลขพอร์ต (ปกติ 9100)';
    }
    if (text.contains('timed out') || code == 10060 || code == 110 || code == 60) {
      return 'เชื่อมต่อ $label ไม่ได้ภายใน 5 วินาที — ตรวจ IP และว่าเครื่องพิมพ์เปิดอยู่ในเครือข่ายเดียวกัน';
    }
    if (text.contains('lookup') || (text.contains('host') && text.contains('not known')) || code == 11001 || code == 7 || code == 8) {
      return 'ไม่พบเครื่อง "$host" ในเครือข่าย — ตรวจ IP / ชื่อเครื่องอีกครั้ง';
    }
    if (code == 10065 || code == 113 || code == 65 || code == 10051 || code == 101 || code == 51) {
      return 'ไม่มีเส้นทางไปยัง $label — ตรวจว่าเครื่อง POS ต่อ Wi-Fi/LAN วงเดียวกับเครื่องพิมพ์';
    }
    return 'เชื่อมต่อเครื่องพิมพ์ $label ไม่ได้ (${e.osError?.message ?? e.message})';
  }
}

// ─────────────────────────── Windows spooler (RAW) ───────────────────────────

class WindowsRawPrinter extends PrinterTransport {
  final String queueName;
  final String docName;
  const WindowsRawPrinter(this.queueName, {this.docName = 'Thai Prompt POS'});

  @override
  String get label => queueName;

  @override
  Future<void> send(List<int> bytes) async {
    if (!_isWindows) throw const PrinterException('การพิมพ์ผ่านคิวเครื่องพิมพ์ USB ใช้ได้เฉพาะบน Windows');
    if (queueName.trim().isEmpty) throw const PrinterException('ยังไม่ได้เลือกเครื่องพิมพ์ USB ในหน้าตั้งค่า');
    final data = Uint8List.fromList(bytes);
    final queue = queueName;
    final doc = docName;
    try {
      // The spooler calls are synchronous FFI — keep them off the UI thread.
      await Isolate.run(() => _winRawPrint(queue, doc, data)).timeout(const Duration(seconds: 60));
    } on PrinterException {
      rethrow;
    } on TimeoutException {
      throw PrinterException('ระบบพิมพ์ของ Windows ไม่ตอบสนอง (เครื่องพิมพ์ "$queue")');
    } catch (e) {
      throw PrinterException('ส่งงานไปที่เครื่องพิมพ์ "$queue" ไม่สำเร็จ: $e');
    }
  }
}

/// Process-heap allocator (keeps this file free of a direct package:ffi import).
final class _ProcessHeap implements Allocator {
  const _ProcessHeap();

  @override
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment}) {
    final p = w32.HeapAlloc(w32.GetProcessHeap(), w32.HEAP_ZERO_MEMORY, byteCount);
    if (p.address == 0) throw const PrinterException('หน่วยความจำไม่พอสำหรับงานพิมพ์');
    return p.cast<T>();
  }

  @override
  void free(Pointer pointer) {
    if (pointer.address != 0) w32.HeapFree(w32.GetProcessHeap(), 0, pointer);
  }
}

/// NUL-terminated UTF-16 copy of [s] (cast to LPWSTR at the call site).
Pointer<Uint16> _wide(String s, Allocator heap) {
  final units = s.codeUnits;
  final p = heap<Uint16>(units.length + 1);
  final view = p.asTypedList(units.length + 1);
  view.setAll(0, units);
  view[units.length] = 0;
  return p;
}

String _winError(String what, int code) {
  final why = switch (code) {
    1801 => 'ไม่พบเครื่องพิมพ์ชื่อนี้ใน Windows (ถูกลบหรือเปลี่ยนชื่อ?)',
    5 => 'ไม่มีสิทธิ์ใช้เครื่องพิมพ์นี้',
    1722 || 1726 || 1753 => 'บริการ Print Spooler ของ Windows ไม่ทำงาน',
    1804 => 'ไดรเวอร์ไม่รับข้อมูลแบบ RAW — ลองติดตั้งไดรเวอร์ของเครื่องพิมพ์หรือ "Generic / Text Only"',
    1797 => 'ไม่พบไดรเวอร์ของเครื่องพิมพ์',
    _ => 'รหัสข้อผิดพลาด Windows $code',
  };
  return '$what — $why';
}

/// Runs in a background isolate. Frees every native allocation and closes the
/// printer handle on every path.
void _winRawPrint(String queue, String docName, Uint8List data) {
  const heap = _ProcessHeap();
  const chunk = 64 * 1024;
  final allocs = <Pointer>[];
  Pointer<T> keep<T extends NativeType>(Pointer<T> p) {
    allocs.add(p);
    return p;
  }

  var hPrinter = 0;
  var docStarted = false;
  var pageStarted = false;
  try {
    final pName = keep(_wide(queue, heap));
    final pDoc = keep(_wide(docName, heap));
    final pRaw = keep(_wide('RAW', heap));
    final pXps = keep(_wide('XPS_PASS', heap));
    final phPrinter = keep(heap<IntPtr>());
    final info = keep(heap<w32.DOC_INFO_1>());
    final written = keep(heap<Uint32>());
    final buf = keep(heap<Uint8>(chunk));

    if (w32.OpenPrinter(pName.cast(), phPrinter, nullptr) == 0) {
      throw PrinterException(_winError('เปิดเครื่องพิมพ์ "$queue" ไม่ได้', w32.GetLastError()));
    }
    hPrinter = phPrinter.value;

    info.ref
      ..pDocName = pDoc.cast()
      ..pOutputFile = nullptr
      ..pDatatype = pRaw.cast();
    var job = w32.StartDocPrinter(hPrinter, 1, info);
    if (job == 0) {
      // v4 (XPS) drivers refuse "RAW" but pass "XPS_PASS" through untouched.
      info.ref.pDatatype = pXps.cast();
      job = w32.StartDocPrinter(hPrinter, 1, info);
    }
    if (job == 0) throw PrinterException(_winError('เริ่มงานพิมพ์ที่ "$queue" ไม่ได้', w32.GetLastError()));
    docStarted = true;

    if (w32.StartPagePrinter(hPrinter) == 0) {
      throw PrinterException(_winError('เริ่มหน้าพิมพ์ที่ "$queue" ไม่ได้', w32.GetLastError()));
    }
    pageStarted = true;

    final view = buf.asTypedList(chunk);
    var offset = 0;
    while (offset < data.length) {
      final n = (data.length - offset) < chunk ? data.length - offset : chunk;
      view.setRange(0, n, data, offset);
      var sent = 0;
      while (sent < n) {
        written.value = 0;
        if (w32.WritePrinter(hPrinter, buf + sent, n - sent, written) == 0 || written.value == 0) {
          throw PrinterException(_winError('ส่งข้อมูลไปที่ "$queue" ไม่สำเร็จ', w32.GetLastError()));
        }
        sent += written.value;
      }
      offset += n;
    }
  } finally {
    if (pageStarted) w32.EndPagePrinter(hPrinter);
    if (docStarted) w32.EndDocPrinter(hPrinter);
    if (hPrinter != 0) w32.ClosePrinter(hPrinter);
    for (final p in allocs) {
      heap.free(p);
    }
  }
}

// ─────────────────────────── Bluetooth ───────────────────────────

final _macRe = RegExp(r'^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$');
final _uuidRe = RegExp(r'^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$');

class BluetoothPrinter extends PrinterTransport {
  /// Android: MAC (AA:BB:CC:DD:EE:FF) · iOS: peripheral UUID from the scan.
  final String mac;
  final String name;
  const BluetoothPrinter(this.mac, {this.name = ''});

  /// Sunmi handhelds/terminals expose their built-in printer as this paired device.
  static const sunmiInnerPrinterName = 'InnerPrinter';
  static const sunmiInnerPrinterMac = '00:11:22:33:44:55';

  /// The device the plugin's single shared connection currently points at.
  static String? _connectedMac;

  /// Largest write per plugin call on Android. The plugin prepends "\n" to
  /// every write and rebuilds the byte array element by element, so writes
  /// are kept small and always end on a command boundary.
  static const _androidChunk = 2048;
  static const _iosChunk = 512;

  @override
  String get label => name.isNotEmpty ? name : mac;

  /// Small bands keep every Android write under [_androidChunk] bytes.
  @override
  int get bandRows => 24;

  /// Throws a Thai [PrinterException] unless Bluetooth is usable right now.
  /// On Android 12+ asks for the "Nearby devices" permission when missing
  /// (the plugin never answers its other calls without it).
  static Future<void> ensureReady() async {
    if (!(_isAndroid || _isIOS)) throw const PrinterException('เครื่องพิมพ์บลูทูธใช้ได้บน Android และ iOS');
    var granted = await PrintBluetoothThermal.isPermissionBluetoothGranted.timeout(const Duration(seconds: 5), onTimeout: () => false);
    if (!granted && _isAndroid) {
      final st = await Permission.bluetoothConnect.request();
      granted = st.isGranted || await PrintBluetoothThermal.isPermissionBluetoothGranted.timeout(const Duration(seconds: 5), onTimeout: () => false);
      if (!granted) {
        throw PrinterException(st.isPermanentlyDenied
            ? 'แอปยังไม่ได้รับสิทธิ์ "อุปกรณ์ใกล้เคียง" — เปิดที่ ตั้งค่าเครื่อง › แอป › Thai Prompt POS › สิทธิ์ › อุปกรณ์ใกล้เคียง'
            : 'ต้องอนุญาตสิทธิ์ "อุปกรณ์ใกล้เคียง" (Bluetooth) ให้แอปก่อน จึงจะใช้เครื่องพิมพ์บลูทูธได้');
      }
    } else if (!granted) {
      throw const PrinterException('บลูทูธปิดอยู่หรือยังไม่อนุญาตให้แอปใช้บลูทูธ — ตรวจที่ ตั้งค่า › Bluetooth และ ความเป็นส่วนตัว › Bluetooth');
    }
    final on = await PrintBluetoothThermal.bluetoothEnabled.timeout(const Duration(seconds: 5), onTimeout: () => false);
    if (!on) throw const PrinterException('บลูทูธของเครื่องปิดอยู่ — เปิดบลูทูธแล้วลองใหม่');
  }

  /// Paired (Android) / nearby (iOS, ~5 s scan) devices.
  static Future<List<({String name, String mac})>> paired() async {
    await ensureReady();
    final list = await PrintBluetoothThermal.pairedBluetooths.timeout(const Duration(seconds: 12),
        onTimeout: () => throw const PrinterException('ค้นหาอุปกรณ์บลูทูธไม่ทันเวลา ลองใหม่อีกครั้ง'));
    final seen = <String>{};
    return [
      for (final d in list)
        if (d.macAdress.trim().isNotEmpty && seen.add(d.macAdress.trim().toUpperCase()))
          (name: d.name.trim().isEmpty ? d.macAdress.trim() : d.name.trim(), mac: d.macAdress.trim()),
    ];
  }

  @override
  Future<void> send(List<int> bytes) => sendParts([Uint8List.fromList(bytes)]);

  @override
  Future<void> sendParts(List<Uint8List> parts) async {
    final addr = mac.trim();
    if (addr.isEmpty) throw const PrinterException('ยังไม่ได้เลือกเครื่องพิมพ์บลูทูธในหน้าตั้งค่า');
    // Malformed addresses crash (iOS force-unwrap) or hang the plugin.
    if ((_isAndroid && !_macRe.hasMatch(addr)) || (_isIOS && !_uuidRe.hasMatch(addr))) {
      throw const PrinterException('ที่อยู่เครื่องพิมพ์บลูทูธไม่ถูกต้อง — เลือกเครื่องจากรายการในหน้าตั้งค่าใหม่');
    }
    await ensureReady();
    final chunks = _isIOS ? _splitEvery(parts, _iosChunk) : groupParts(parts, _androidChunk);
    if (chunks.isEmpty) return;
    await _connect(addr);
    if (await _write(chunks)) return;
    // Nothing was delivered (stale link failed on the first write) —
    // reconnect once and resend. Never resend after a partial delivery.
    _connectedMac = null;
    await _connect(addr);
    if (!await _write(chunks)) throw _dropped();
  }

  /// iOS doesn't touch the payload, so it can be cut anywhere.
  static List<Uint8List> _splitEvery(List<Uint8List> parts, int size) {
    final all = BytesBuilder(copy: false);
    for (final p in parts) {
      all.add(p);
    }
    final b = all.takeBytes();
    return [for (var i = 0; i < b.length; i += size) Uint8List.sublistView(b, i, (i + size) < b.length ? i + size : b.length)];
  }

  PrinterException _dropped() =>
      PrinterException('ส่งข้อมูลไปเครื่องพิมพ์บลูทูธ "$label" ไม่สำเร็จ — การเชื่อมต่อหลุด ตรวจเครื่องพิมพ์แล้วลองใหม่');

  Future<void> _connect(String addr) async {
    final connected = await PrintBluetoothThermal.connectionStatus.timeout(const Duration(seconds: 5), onTimeout: () => false);
    if (connected && _connectedMac == addr) return;
    if (connected) {
      // The plugin holds one connection and refuses connect() while it is open.
      await PrintBluetoothThermal.disconnect.timeout(const Duration(seconds: 5), onTimeout: () => false);
    }
    _connectedMac = null;
    final ok = await PrintBluetoothThermal.connect(macPrinterAddress: addr).timeout(const Duration(seconds: 20), onTimeout: () => false);
    if (!ok) {
      throw PrinterException('เชื่อมต่อเครื่องพิมพ์บลูทูธ "$label" ไม่ได้ — ตรวจว่าเครื่องพิมพ์เปิดอยู่ จับคู่ (pair) แล้ว และไม่ได้ต่อกับเครื่องอื่น');
    }
    _connectedMac = addr;
  }

  /// False when the very first chunk failed (nothing printed); throws when
  /// the link drops part-way through.
  Future<bool> _write(List<Uint8List> chunks) async {
    for (var i = 0; i < chunks.length; i++) {
      // Plain List<int>: the plugin casts its argument to List<Int> / [Int];
      // a Uint8List would arrive as a typed byte array and be rejected.
      final data = List<int>.of(chunks[i]);
      bool ok;
      if (_isIOS) {
        // iOS only answers for write-with-response characteristics; pace the
        // BLE writes so the printer buffer keeps up.
        ok = await PrintBluetoothThermal.writeBytes(data).timeout(const Duration(seconds: 2), onTimeout: () => true);
        await Future<void>.delayed(const Duration(milliseconds: 25));
      } else {
        ok = await PrintBluetoothThermal.writeBytes(data).timeout(const Duration(seconds: 20), onTimeout: () => false);
      }
      if (!ok) {
        _connectedMac = null;
        if (i == 0) return false;
        throw _dropped();
      }
    }
    return true;
  }
}
