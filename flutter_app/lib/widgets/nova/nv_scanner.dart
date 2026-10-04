// Thaiprompt POS — Nova camera scanner (สแกนบาร์โค้ด / QR ด้วยกล้อง).
//
//   final code = await showNvScanner(context, title: 'สแกนสินค้า');
//   NvScanButton(onScanned: (code) => ...)
//
// A full-screen night route over the live camera (mobile_scanner 7): dimmed
// edges, a gold rounded scan window framed by kanok corners with a sweeping
// scan line, torch + switch-camera controls, and Thai error states (camera
// permission denied / no camera / camera busy) with retry + close. It returns
// the FIRST non-empty rawValue exactly once (light haptic), or null when the
// user closes it.
//
// Camera scanning exists on Android/iOS only. On Windows/web
// [nvCameraScanSupported] is false and [NvScanButton] renders nothing, so the
// USB/Bluetooth keyboard-wedge scanners typing into the search boxes stay the
// only (and unchanged) path there.
//
// by xman studio

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart' show openAppSettings;

import '../../theme/nv_icons.dart';
import '../../theme/nv_tokens.dart';
import 'nv_art.dart';
import 'nv_buttons.dart';

/// True where the camera scanner can run (Android / iOS).
bool get nvCameraScanSupported =>
    !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

/// One scanner at a time — a double tap on a scan button must not stack two
/// camera routes (the platform has a single camera session).
bool _nvScannerOpen = false;

/// Opens the full-screen camera scanner and resolves to the scanned code
/// (trimmed rawValue), or null when closed / unsupported / already open.
Future<String?> showNvScanner(
  BuildContext context, {
  String title = 'สแกนบาร์โค้ด',
  String? hint,
}) async {
  if (_nvScannerOpen) return null;
  _nvScannerOpen = true;
  try {
    return await Navigator.of(context, rootNavigator: true).push<String>(
      MaterialPageRoute<String>(
        fullscreenDialog: true,
        builder: (_) => _NvScannerPage(title: title, hint: hint),
      ),
    );
  } finally {
    _nvScannerOpen = false;
  }
}

/// Round "scan with camera" button for search boxes / code fields.
/// Renders nothing where the camera scanner isn't available (Windows, web).
class NvScanButton extends StatelessWidget {
  final ValueChanged<String> onScanned;
  final String title;
  final String? hint;
  final IconData icon;
  final String tooltip;
  final bool onNight;
  final double size;

  const NvScanButton({
    super.key,
    required this.onScanned,
    this.title = 'สแกนบาร์โค้ด',
    this.hint,
    this.icon = NvIcons.barcode,
    this.tooltip = 'สแกนด้วยกล้อง',
    this.onNight = false,
    this.size = 44,
  });

  Future<void> _scan(BuildContext context) async {
    final code = await showNvScanner(context, title: title, hint: hint);
    if (code == null || !context.mounted) return;
    onScanned(code);
  }

  @override
  Widget build(BuildContext context) {
    if (!nvCameraScanSupported) return const SizedBox.shrink();
    return NvIconButton(icon, tooltip: tooltip, onNight: onNight, size: size, onPressed: () => _scan(context));
  }
}

// ═════════════════════════════ scanner route ═════════════════════════════

class _NvScannerPage extends StatefulWidget {
  final String title;
  final String? hint;
  const _NvScannerPage({required this.title, this.hint});

  @override
  State<_NvScannerPage> createState() => _NvScannerPageState();
}

class _NvScannerPageState extends State<_NvScannerPage> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  /// Null where the camera scanner isn't supported (the page then only shows
  /// the "no camera" state and never touches the plugin).
  MobileScannerController? _controller;
  late final AnimationController _sweep;
  bool _handled = false; // a code was returned — ignore further detections
  bool _busy = false; // torch / camera switch in flight

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))..repeat(reverse: true);
    if (nvCameraScanSupported) {
      // autoStart off: this page starts / stops the camera itself (README
      // lifecycle pattern) so every start is awaited and its errors handled.
      _controller = MobileScannerController(autoStart: false);
      WidgetsBinding.instance.addObserver(this);
      unawaited(_start());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sweep.dispose();
    final c = _controller;
    _controller = null;
    super.dispose();
    // Releases the camera session (platform dispose stops the camera).
    if (c != null) unawaited(c.dispose().catchError((Object e) => debugPrint('NvScanner dispose: $e')));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    // Permission prompts flip the lifecycle before the camera is ready — skip.
    if (c == null || _handled || !c.value.hasCameraPermission) return;
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_start());
      case AppLifecycleState.inactive:
        unawaited(_stop());
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        break;
    }
  }

  Future<void> _start() async {
    final c = _controller;
    if (c == null) return;
    try {
      await c.start();
    } on MobileScannerException catch (_) {
      // Start-time failures (permission, no camera…) land in c.value.error and
      // render through errorBuilder; "already starting" / "disposed" are moot.
    } catch (e) {
      debugPrint('NvScanner start failed: $e'); // e.g. plugin not registered
    }
  }

  Future<void> _stop() async {
    final c = _controller;
    if (c == null) return;
    try {
      await c.stop();
    } catch (_) {
      // already stopped / disposed
    }
  }

  Future<void> _guarded(Future<void> Function(MobileScannerController c) action) async {
    final c = _controller;
    if (c == null || _busy || _handled) return;
    _busy = true;
    try {
      await action(c);
    } catch (_) {
      // camera not running yet / platform refused — the button does nothing
    } finally {
      _busy = false;
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled || !mounted) return;
    String? code;
    for (final b in capture.barcodes) {
      final v = b.rawValue?.trim();
      if (v != null && v.isNotEmpty) {
        code = v;
        break;
      }
    }
    if (code == null) return;
    _handled = true; // debounce: one scan → one result
    unawaited(HapticFeedback.lightImpact());
    Navigator.of(context).pop(code);
  }

  void _close() {
    if (_handled || !mounted) return;
    Navigator.of(context).pop();
  }

  /// Scan window between the title bar and the bottom controls.
  Rect _windowFor(Size s, EdgeInsets pad) {
    final top = pad.top + 76.0; // under the title bar
    final bottom = s.height - pad.bottom - 112.0 - 52.0; // above controls + hint
    final availH = math.max(bottom - top, 110.0);
    final w = math.min(s.width * 0.82, 400.0);
    final h = math.max(math.min(w * 0.68, availH), 100.0);
    return Rect.fromCenter(center: Offset(s.width / 2, top + availH / 2), width: w, height: h);
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Nv.navy950,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (c == null)
              _ScanProblem(code: null, onClose: _close)
            else
              LayoutBuilder(builder: (context, box) {
                final window = _windowFor(box.biggest, MediaQuery.paddingOf(context));
                return MobileScanner(
                  controller: c,
                  fit: BoxFit.cover,
                  tapToFocus: true,
                  onDetect: _onDetect,
                  placeholderBuilder: (_) => const _ScanStarting(),
                  errorBuilder: (context, error) => _ScanProblem(code: error.errorCode, onClose: _close, onRetry: _start),
                  overlayBuilder: (context, _) => _ScanOverlay(
                    window: window,
                    sweep: _sweep,
                    controller: c,
                    hint: widget.hint ?? 'วางบาร์โค้ดหรือ QR ให้อยู่ในกรอบ · ระบบอ่านให้อัตโนมัติ',
                  ),
                );
              }),
            Positioned(left: 0, right: 0, top: 0, child: _TopBar(title: widget.title, onClose: _close)),
            if (c != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _Controls(
                  controller: c,
                  onTorch: () => _guarded((c) => c.toggleTorch()),
                  onSwitch: () => _guarded((c) => c.switchCamera()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════ pieces ═════════════════════════════

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  const _TopBar({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Nv.navy950.withValues(alpha: 0.92), Nv.navy950.withValues(alpha: 0)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 14, 18),
          child: Row(
            children: [
              NvIconButton(NvIcons.xmark, tooltip: 'ปิด', onNight: true, onPressed: onClose),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('สแกนด้วยกล้อง', style: Nv.eyebrow(color: Nv.gold300)),
                    Text(title,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.display(19, color: Nv.onNight)),
                  ],
                ),
              ),
              NvArt.icon('barcode', size: 40, fallbackIcon: NvIcons.barcode),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dimmed edges + gold window + kanok corners + sweeping line + hint.
class _ScanOverlay extends StatelessWidget {
  final Rect window;
  final Animation<double> sweep;
  final MobileScannerController controller;
  final String hint;
  const _ScanOverlay({required this.window, required this.sweep, required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    final corner = (window.shortestSide * 0.3).clamp(40.0, 64.0);
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _WindowPainter(window)),
          // kanok-gold corners hugging the window
          Positioned.fromRect(
            rect: window.inflate(10),
            child: Stack(children: [NvKanokCorners(size: corner, inset: EdgeInsets.zero, opacity: 0.95)]),
          ),
          // sweeping scan line (or a spinner while the camera restarts)
          Positioned.fromRect(
            rect: window.deflate(14),
            child: ValueListenableBuilder<MobileScannerState>(
              valueListenable: controller,
              builder: (context, s, _) {
                if (!s.isRunning) {
                  return const Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Nv.gold300),
                    ),
                  );
                }
                return RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: sweep,
                    builder: (context, child) => Align(
                      alignment: Alignment(0, Curves.easeInOut.transform(sweep.value) * 2 - 1),
                      child: child,
                    ),
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: LinearGradient(colors: [
                          Nv.gold300.withValues(alpha: 0),
                          Nv.gold300,
                          Nv.gold100,
                          Nv.gold300,
                          Nv.gold300.withValues(alpha: 0),
                        ]),
                        boxShadow: [BoxShadow(color: Nv.gold400.withValues(alpha: 0.7), blurRadius: 12, spreadRadius: 1)],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: window.bottom + 18,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Nv.navy900.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(Nv.rPill),
                    border: Border.all(color: Nv.lineNightStrong),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(NvIcons.qrcode, size: 14, color: Nv.gold300),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          hint,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Nv.ui(13, color: Nv.onNight2, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WindowPainter extends CustomPainter {
  final Rect window;
  _WindowPainter(this.window);

  static const _radius = Radius.circular(Nv.rLg);

  @override
  void paint(Canvas canvas, Size size) {
    final hole = RRect.fromRectAndRadius(window, _radius);
    // dim everything outside the window
    final dim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(hole);
    canvas.drawPath(dim, Paint()..color = Nv.navy950.withValues(alpha: 0.64));
    // soft gold glow + hairline rim
    canvas.drawRRect(
      hole,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = Nv.gold400.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(
      hole,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Nv.gold300.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(_WindowPainter old) => old.window != window;
}

/// Torch + switch camera, shown only while the camera runs.
class _Controls extends StatelessWidget {
  final MobileScannerController controller;
  final VoidCallback onTorch;
  final VoidCallback onSwitch;
  const _Controls({required this.controller, required this.onTorch, required this.onSwitch});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Nv.navy950.withValues(alpha: 0.9), Nv.navy950.withValues(alpha: 0)],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 14),
          child: ValueListenableBuilder<MobileScannerState>(
            valueListenable: controller,
            builder: (context, s, _) {
              final running = s.isInitialized && s.isRunning && s.error == null;
              final torch = running && s.torchState != TorchState.unavailable;
              final cams = s.availableCameras;
              final canSwitch = running && (cams == null || cams >= 2);
              return SizedBox(
                height: 76,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (torch)
                      _ControlButton(
                        icon: NvIcons.bolt,
                        label: s.torchState == TorchState.on ? 'ปิดไฟฉาย' : 'ไฟฉาย',
                        active: s.torchState == TorchState.on,
                        onTap: onTorch,
                      ),
                    if (torch && canSwitch) const SizedBox(width: 36),
                    if (canSwitch) _ControlButton(icon: NvIcons.rotate, label: 'สลับกล้อง', onTap: onSwitch),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ControlButton({required this.icon, required this.label, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NvIconButton(icon, tooltip: label, onNight: true, active: active, size: 52, onPressed: onTap),
        const SizedBox(height: 6),
        Text(label, style: Nv.ui(12, color: active ? Nv.gold200 : Nv.onNight2, weight: FontWeight.w600)),
      ],
    );
  }
}

class _ScanStarting extends StatelessWidget {
  const _ScanStarting();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: Nv.night),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(strokeWidth: 2.6, color: Nv.gold300),
            ),
            const SizedBox(height: 14),
            Text('กำลังเปิดกล้อง…', style: Nv.ui(14, color: Nv.onNight2)),
          ],
        ),
      ),
    );
  }
}

/// Permission denied / no camera / camera failure — NvEmptyState look on night.
class _ScanProblem extends StatelessWidget {
  /// null = this platform can't scan with a camera at all.
  final MobileScannerErrorCode? code;
  final VoidCallback onClose;
  final Future<void> Function()? onRetry;
  const _ScanProblem({required this.code, required this.onClose, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final denied = code == MobileScannerErrorCode.permissionDenied;
    final noCamera = code == null || code == MobileScannerErrorCode.unsupported;
    final (String mascot, String title, String message) = denied
        ? (
            'wai',
            'ยังไม่ได้รับอนุญาตให้ใช้กล้อง',
            'เปิดสิทธิ์ "กล้อง" ให้แอปในการตั้งค่าของเครื่อง แล้วกด "ลองอีกครั้ง" · หรือพิมพ์รหัส / ใช้เครื่องสแกนบาร์โค้ดแทน',
          )
        : noCamera
            ? (
                'search',
                'ไม่พบกล้องสำหรับสแกน',
                code == null
                    ? 'อุปกรณ์นี้สแกนด้วยกล้องไม่ได้ · ใช้เครื่องสแกนบาร์โค้ด (USB / Bluetooth) หรือพิมพ์รหัสแทน'
                    : 'ไม่พบกล้องบนอุปกรณ์นี้ · ใช้เครื่องสแกนบาร์โค้ด (USB / Bluetooth) หรือพิมพ์รหัสแทน',
              )
            : (
                'sleepy',
                'เปิดกล้องไม่สำเร็จ',
                'กล้องอาจถูกแอปอื่นใช้งานอยู่ ปิดแอปนั้นแล้วกด "ลองอีกครั้ง"',
              );
    final retry = onRetry;
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: Nv.night),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NvArt.mascot(mascot, height: 150),
                  const SizedBox(height: 12),
                  Text(title, textAlign: TextAlign.center, style: Nv.display(20, color: Nv.onNight)),
                  const SizedBox(height: 8),
                  Text(message, textAlign: TextAlign.center, style: Nv.ui(14, color: Nv.onNight3, height: 1.5)),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (retry != null && !noCamera)
                        NvButton.gold('ลองอีกครั้ง', icon: NvIcons.rotate, onPressed: () => unawaited(retry())),
                      if (denied)
                        NvButton.ghost('เปิดการตั้งค่า',
                            icon: NvIcons.settings, onNight: true, onPressed: () => unawaited(openAppSettings())),
                      if (noCamera)
                        NvButton.gold('ปิด', icon: NvIcons.xmark, onPressed: onClose)
                      else
                        NvButton.ghost('ปิด', icon: NvIcons.xmark, onNight: true, onPressed: onClose),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
