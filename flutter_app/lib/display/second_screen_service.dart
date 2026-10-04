// Thai Prompt POS — customer-facing second screen.
//
// Streams a [DisplaySnapshot] of the live counter (cart, totals, member,
// PromptPay QR, thank-you, promotions) to a physical second display:
//   • Windows — a second Flutter window (desktop_multi_window) placed
//               full-screen on the chosen monitor by the runner's native
//               "tp/window" channel.
//   • Android — a Presentation on the terminal's customer display (Sunmi T2/D2,
//               iMin …) hosting its own engine (MainActivity.kt).
// The secondary side has no store: it renders snapshots only
// (CustomerDisplayApp). Snapshots are debounced (≈150 ms) and resent every
// 15 s so clocks / thank-you expiry stay right even if a message is lost.
//
// by xman studio

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../state/pos_store.dart';
import 'customer_display_app.dart';
import 'display_snapshot.dart';

class ScreenInfo {
  final String id;
  final String name;
  final int width;
  final int height;
  final bool primary;
  final int x;
  final int y;
  const ScreenInfo({required this.id, required this.name, required this.width, required this.height, this.primary = false, this.x = 0, this.y = 0});

  /// Windows device names look like `\\.\DISPLAY2` — show just `DISPLAY2`.
  String get label => '${name.split(r'\').last} · $width×$height${primary ? ' (จอหลัก)' : ''}';
}

class SecondScreenService extends ChangeNotifier {
  SecondScreenService._();
  static final SecondScreenService instance = SecondScreenService._();

  static const _winPlacement = MethodChannel('tp/window');
  static const _android = MethodChannel('tp/second_screen');
  static const _toDisplay = WindowMethodChannel('tp/customer_display', mode: ChannelMode.unidirectional);
  static const _fromDisplay = WindowMethodChannel('tp/customer_display_main', mode: ChannelMode.unidirectional);

  PosStore? _store;
  Timer? _debounce;
  Timer? _heartbeat;
  bool active = false;
  bool busy = false;
  String? error;
  String _lastJson = '';
  WindowController? _window;
  bool _mainHandlerReady = false;

  bool get supported => !kIsWeb && (Platform.isWindows || Platform.isAndroid);

  /// Wire to the store once at startup; auto-starts when enabled in settings.
  void attach(PosStore store) {
    if (_store != null) return;
    _store = store;
    store.addListener(_onStore);
    if (supported && store.secondScreenEnabled) {
      // let the first frame settle before spawning windows / presentations
      Future<void>.delayed(const Duration(seconds: 2), () => start());
    }
  }

  void _onStore() {
    final s = _store;
    if (s == null) return;
    if (!active && s.secondScreenEnabled && !busy && error == null) {
      start();
      return;
    }
    if (active && !s.secondScreenEnabled) {
      stop();
      return;
    }
    if (!active) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), push);
  }

  Future<List<ScreenInfo>> displays() async {
    try {
      if (!kIsWeb && Platform.isWindows) {
        final raw = await _winPlacement.invokeListMethod<dynamic>('displays') ?? const [];
        return [
          for (final d in raw.whereType<Map>())
            ScreenInfo(
              id: '${d['id']}',
              name: '${d['name']}',
              width: (d['w'] as num?)?.toInt() ?? 0,
              height: (d['h'] as num?)?.toInt() ?? 0,
              x: (d['x'] as num?)?.toInt() ?? 0,
              y: (d['y'] as num?)?.toInt() ?? 0,
              primary: d['primary'] == true,
            ),
        ];
      }
      if (!kIsWeb && Platform.isAndroid) {
        final raw = await _android.invokeListMethod<dynamic>('displays') ?? const [];
        return [
          for (final d in raw.whereType<Map>())
            ScreenInfo(
              id: '${d['id']}',
              name: '${d['name']}',
              width: (d['w'] as num?)?.toInt() ?? 0,
              height: (d['h'] as num?)?.toInt() ?? 0,
            ),
        ];
      }
    } catch (e) {
      debugPrint('[SecondScreen] displays failed: $e');
    }
    return const [];
  }

  /// Pick the configured display, else the first non-primary one.
  ScreenInfo? _pick(List<ScreenInfo> all, String wanted) {
    for (final d in all) {
      if (wanted.isNotEmpty && d.id == wanted) return d;
    }
    for (final d in all) {
      if (!d.primary) return d;
    }
    return null;
  }

  Future<bool> start() async {
    final s = _store;
    if (!supported || s == null || busy) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final all = await displays();
      final target = _pick(all, s.secondScreenId);
      if (target == null) {
        error = Platform.isAndroid ? 'เครื่องนี้ไม่มีจอแสดงผลที่สอง' : 'ไม่พบจอที่สอง — ต่อจอเพิ่มแล้วตั้งค่าเป็น "ขยายจอ (Extend)"';
        active = false;
        return false;
      }
      _lastJson = DisplaySnapshot.fromStore(s).encode();
      if (Platform.isAndroid) {
        await _android.invokeMethod('state', _lastJson);
        final ok = await _android.invokeMethod<bool>('show', {'displayId': int.tryParse(target.id)}) ?? false;
        if (!ok) {
          error = 'เปิดจอที่สองไม่สำเร็จ';
          return false;
        }
      } else {
        await _ensureMainHandler();
        await _openWindow(target);
      }
      active = true;
      _heartbeat?.cancel();
      _heartbeat = Timer.periodic(const Duration(seconds: 15), (_) => push(force: true));
      return true;
    } catch (e) {
      error = 'เปิดจอที่สองไม่สำเร็จ: $e';
      active = false;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _ensureMainHandler() async {
    if (_mainHandlerReady) return;
    await _fromDisplay.setMethodCallHandler((call) async {
      if (call.method == 'getState') return _lastJson;
      if (call.method == 'closed') {
        _window = null;
        active = false;
        notifyListeners();
      }
      return null;
    });
    _mainHandlerReady = true;
  }

  Future<void> _openWindow(ScreenInfo target) async {
    // reuse a window left over from a previous session / hot restart
    if (_window == null) {
      for (final w in await WindowController.getAll()) {
        if (w.arguments.contains('"customer_display"')) _window = w;
      }
    }
    final args = jsonEncode({
      'type': 'customer_display',
      'x': target.x,
      'y': target.y,
      'w': target.width,
      'h': target.height,
    });
    if (_window != null) {
      // move the existing window (it re-reads placement on 'place')
      await _toDisplay.invokeMethod('place', args);
      await _window!.show();
      await push(force: true);
      return;
    }
    _window = await WindowController.create(WindowConfiguration(arguments: args, hiddenAtLaunch: true));
    await _window!.show();
  }

  Future<void> push({bool force = false}) async {
    final s = _store;
    if (s == null || !active) return;
    final json = DisplaySnapshot.fromStore(s).encode();
    if (!force && json == _lastJson) return;
    _lastJson = json;
    try {
      if (Platform.isAndroid) {
        await _android.invokeMethod('state', json);
      } else if (Platform.isWindows) {
        await _toDisplay.invokeMethod('state', json);
      }
    } catch (e) {
      // the window may still be booting; it pulls getState when ready
      debugPrint('[SecondScreen] push failed: $e');
    }
  }

  Future<void> stop() async {
    _heartbeat?.cancel();
    _debounce?.cancel();
    try {
      if (!kIsWeb && Platform.isAndroid) {
        await _android.invokeMethod('hide');
      } else if (!kIsWeb && Platform.isWindows && _window != null) {
        await _toDisplay.invokeMethod('close');
      }
    } catch (_) {}
    _window = null;
    active = false;
    notifyListeners();
  }
}

// ─────────────────────────── secondary-side entrypoints ───────────────────────────

/// Windows: called from main() when this engine is the customer-display window.
Future<void> runCustomerDisplayWindow(Map<String, dynamic> args) async {
  const placement = MethodChannel('tp/window');
  const inbox = WindowMethodChannel('tp/customer_display', mode: ChannelMode.unidirectional);
  const mainSide = WindowMethodChannel('tp/customer_display_main', mode: ChannelMode.unidirectional);
  final ctrl = StreamController<DisplaySnapshot>.broadcast();

  Future<void> place(Map<String, dynamic> a) => placement.invokeMethod('place', {
        'x': a['x'] ?? 0,
        'y': a['y'] ?? 0,
        'w': a['w'] ?? 1280,
        'h': a['h'] ?? 800,
        'fullscreen': true,
        'topmost': false,
      });

  try {
    await placement.invokeMethod('setTitle', {'title': 'Thai Prompt — จอลูกค้า'});
    await place(args);
  } catch (e) {
    debugPrint('[CustomerDisplay] placement failed: $e');
  }

  await inbox.setMethodCallHandler((call) async {
    switch (call.method) {
      case 'state':
        ctrl.add(DisplaySnapshot.decode(call.arguments as String));
      case 'place':
        await place((jsonDecode(call.arguments as String) as Map).cast<String, dynamic>());
      case 'close':
        try {
          await mainSide.invokeMethod('closed');
        } catch (_) {}
        await placement.invokeMethod('close');
    }
    return null;
  });

  DisplaySnapshot? initial;
  try {
    final s = await mainSide.invokeMethod<String>('getState');
    if (s != null && s.isNotEmpty) initial = DisplaySnapshot.decode(s);
  } catch (_) {}
  runApp(CustomerDisplayApp(snapshots: ctrl.stream, initial: initial));
}

/// Android: body of the Presentation engine's entrypoint (`customerDisplayMain`
/// in main.dart, launched by MainActivity.kt).
Future<void> runCustomerDisplayAndroid() async {
  WidgetsFlutterBinding.ensureInitialized();
  const ch = MethodChannel('tp/customer_display');
  final ctrl = StreamController<DisplaySnapshot>.broadcast();
  ch.setMethodCallHandler((call) async {
    if (call.method == 'state' && call.arguments is String && (call.arguments as String).isNotEmpty) {
      ctrl.add(DisplaySnapshot.decode(call.arguments as String));
    }
    return null;
  });
  DisplaySnapshot? initial;
  try {
    final s = await ch.invokeMethod<String>('getState');
    if (s != null && s.isNotEmpty) initial = DisplaySnapshot.decode(s);
  } catch (_) {}
  runApp(CustomerDisplayApp(snapshots: ctrl.stream, initial: initial));
}
