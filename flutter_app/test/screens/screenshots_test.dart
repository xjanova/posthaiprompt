// Screenshot + smoke test for every route (real fonts, real Nova art, demo
// data). Writes PNGs to build/screens/<size>/<name>.png and fails on
// exceptions/overflows, listing which routes broke.
//
//   flutter test test/screens/screenshots_test.dart --dart-define=SCREENS=1
//   … --dart-define=SCREENS=1 --dart-define=ROUTES=/cashier,/payment
//   … --dart-define=SCREENS=1 --dart-define=SIZE=phone|tablet|small
//
// Opt-in (skipped in the default `flutter test` / CI run unless SCREENS=1).

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_thaiprompt/data/local_store.dart';
import 'package:pos_thaiprompt/routes/app_router.dart';
import 'package:pos_thaiprompt/screens/tp_rider_dialog.dart';
import 'package:pos_thaiprompt/state/pos_store.dart';
import 'package:pos_thaiprompt/state/app_scope.dart';
import 'package:pos_thaiprompt/theme/tp_theme.dart';

import 'demo_data.dart';

const _allRoutes = [
  '/login', '/home', '/cashier', '/payment', '/receipt', '/orders', '/bill/create', '/refund', '/payment/nfc', '/tax-invoice',
  '/shift', '/tablet/floor', '/floor-designer', '/display/kitchen', '/mobile/order', '/m/cashier', '/display/customer',
  '/self-order', '/order-status', '/cust/menu', '/cust/item?code=P0001', '/cust/cart', '/cust/confirm', '/menu-editor',
  '/inventory', '/stock', '/po', '/barcode', '/crm', '/tiers', '/coupons', '/discount-center', '/affiliate', '/delivery',
  '/shipping/providers', '/shipping/labels', '/dashboard', '/mobile/manager', '/accounting', '/hq', '/staff', '/admin',
  '/settings', '/screens',
];

Future<void> _loadFonts() async {
  final manifest = json.decode(await rootBundle.loadString('FontManifest.json')) as List;
  for (final f in manifest) {
    final family = (f as Map)['family'] as String;
    final loader = FontLoader(family);
    for (final a in (f['fonts'] as List)) {
      loader.addFont(rootBundle.load((a as Map)['asset'] as String));
    }
    await loader.load();
  }
}

Future<void> _precacheAll(WidgetTester tester) async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final ctx = tester.element(find.byType(MaterialApp).first);
  await tester.runAsync(() async {
    for (final k in manifest.listAssets().where((k) => k.startsWith('assets/nova/'))) {
      await precacheImage(AssetImage(k), ctx);
    }
  });
}

void main() {
  const routesArg = String.fromEnvironment('ROUTES');
  const sizeArg = String.fromEnvironment('SIZE', defaultValue: 'desktop');
  final routes = routesArg.isEmpty ? _allRoutes : routesArg.split(',');
  // Named presets, or any WxH (e.g. --dart-define=SIZE=1366x768).
  final size = switch (sizeArg) {
    'phone' => const Size(390, 844), // iPhone / most Android phones
    'handheld' => const Size(360, 720), // Sunmi V2 / handheld POS
    'tablet' => const Size(1180, 820), // iPad Air / 11" Android, landscape
    'tablet-portrait' => const Size(820, 1180),
    'pos4x3' => const Size(1024, 768), // 15" 4:3 POS terminals
    'pos1366' => const Size(1366, 768), // most Windows touch POS
    'fhd' => const Size(1920, 1080), // Sunmi T2 / 15.6" FHD POS
    'small' => const Size(1024, 700),
    'desktop' => const Size(1440, 900),
    _ when RegExp(r'^\d+x\d+$').hasMatch(sizeArg) =>
      Size(double.parse(sizeArg.split('x')[0]), double.parse(sizeArg.split('x')[1])),
    _ => const Size(1440, 900),
  };

  testWidgets('render every route ($sizeArg)', (tester) async {
    await _loadFonts();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final out = Directory('build/screens/$sizeArg')..createSync(recursive: true);
    final failures = <String, String>{};
    final store = buildDemoStore();
    final router = AppRouter.create(store);
    final key = GlobalKey();

    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: AppScope(
        store: store,
        child: MaterialApp.router(debugShowCheckedModeBanner: false, theme: TpTheme.light(), routerConfig: router),
      ),
    ));
    await _precacheAll(tester);

    for (final r in routes) {
      final errors = <String>[];
      final prev = FlutterError.onError;
      FlutterError.onError = (d) => errors.add(d.exceptionAsString().split('\n').first);
      try {
        if (r == '/login') {
          store.logout();
        } else if (store.currentStaff == null) {
          store.login(store.activeStaff.first.id, demoPin);
        }
        router.go(r);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
        await tester.pump(const Duration(milliseconds: 50));
        final ex = tester.takeException();
        if (ex != null) errors.add(ex.toString().split('\n').first);
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final bytes = await tester.runAsync(() async {
          final img = await boundary.toImage(pixelRatio: 1);
          final png = await img.toByteData(format: ui.ImageByteFormat.png);
          img.dispose();
          return png!.buffer.asUint8List();
        });
        final name = r.replaceAll(RegExp(r'^/'), '').replaceAll(RegExp(r'[/?=&]'), '_');
        File('${out.path}/${name.isEmpty ? 'root' : name}.png').writeAsBytesSync(bytes!);
        final loc = router.routerDelegate.currentConfiguration.uri.toString();
        if (!r.startsWith(loc.split('?').first)) errors.add('redirected to $loc');
        if (r == '/login') store.login(store.activeStaff.first.id, demoPin);
      } catch (e) {
        errors.add('THROWN: ${e.toString().split('\n').first}');
      } finally {
        FlutterError.onError = prev;
      }
      if (errors.isNotEmpty) failures[r] = errors.toSet().take(4).join(' | ');
    }

    // dispose the tree so timers in screens are cancelled
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    router.dispose();
    store.dispose();

    File('${out.path}/_report.txt').writeAsStringSync(
        failures.isEmpty ? 'ALL OK (${routes.length} routes)\n' : failures.entries.map((e) => '${e.key}: ${e.value}').join('\n'));
    expect(failures, isEmpty, reason: failures.entries.map((e) => '${e.key}: ${e.value}').join('\n'));
  }, timeout: const Timeout(Duration(minutes: 10)), skip: const String.fromEnvironment('SCREENS') != '1');

  testWidgets('Thai Prompt rider: QR dialog, paid dialog, customer display', (tester) async {
    await _loadFonts();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final out = Directory('build/screens/$sizeArg')..createSync(recursive: true);
    final store = buildDemoStore();
    store.login(store.activeStaff.first.id, demoPin);
    final router = AppRouter.create(store);
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: AppScope(store: store, child: MaterialApp.router(theme: TpTheme.light(), routerConfig: router, debugShowCheckedModeBanner: false)),
    ));
    await _precacheAll(tester);
    final errors = <String>[];
    final prev = FlutterError.onError;
    FlutterError.onError = (d) => errors.add(d.exceptionAsString().split('\n').first);

    Future<void> shot(String name) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
      await tester.pump(const Duration(milliseconds: 50));
      final ex = tester.takeException();
      if (ex != null) errors.add('$name: ${ex.toString().split('\n').first}');
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final bytes = await tester.runAsync(() async {
        final img = await boundary.toImage(pixelRatio: 1);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        img.dispose();
        return png!.buffer.asUint8List();
      });
      File('${out.path}/$name.png').writeAsBytesSync(bytes!);
    }

    final waiting = store.deliveries.firstWhere((d) => d.awaitingPayment);
    router.go('/delivery');
    await shot('tp_delivery_board');
    final ctx = router.routerDelegate.navigatorKey.currentContext!;
    final done = showTpRiderDialog(ctx, resume: waiting);
    await shot('tp_qr_dialog');
    store.applyTpRiderStatus(waiting, {
      'status': 'paid',
      'delivery_fee': 38,
      'order': {'order_number': 'ORD-2610-0902'},
      'rider_job': {'status': 'pending'},
    });
    await shot('tp_paid_dialog');
    await tester.tap(find.text('ดูใบเสร็จ'));
    await tester.pump(const Duration(milliseconds: 400));
    expect((await done)?.outcome, TpRiderOutcome.paid);

    final parked = store.createTpRiderJob(
      requestId: 77,
      qrPayload: 'TPPOS1.k3J9xQ2mVb7LpR4tYw8Zc1Nd6Hf0Gs5Ae9Ku3Jo',
      expiresAt: DateTime.now().add(const Duration(minutes: 9, seconds: 41)),
      lines: waiting.lines,
      subtotal: waiting.subtotal,
    );
    store.showRiderQr(parked);
    router.go('/display/customer');
    await shot('tp_customer_display');
    store.showRiderQr(null);

    FlutterError.onError = prev;
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    router.dispose();
    store.dispose();
    expect(errors, isEmpty, reason: errors.join('\n'));
  }, skip: const String.fromEnvironment('SCREENS') != '1');

  testWidgets('first-run setup screen', (tester) async {
    await _loadFonts();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final out = Directory('build/screens/$sizeArg')..createSync(recursive: true);
    final store = PosStore(disk: LocalStore(baseDir: Directory.systemTemp.createTempSync('pos_setup')));
    final router = AppRouter.create(store);
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: AppScope(store: store, child: MaterialApp.router(theme: TpTheme.light(), routerConfig: router, debugShowCheckedModeBanner: false)),
    ));
    await _precacheAll(tester);
    await tester.pump(const Duration(milliseconds: 400));
    expect(router.routerDelegate.currentConfiguration.uri.path, '/setup');
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() async {
      final img = await boundary.toImage(pixelRatio: 1);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      return png!.buffer.asUint8List();
    });
    File('${out.path}/setup.png').writeAsBytesSync(bytes!);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    store.dispose();
  }, skip: const String.fromEnvironment('SCREENS') != '1');
}
