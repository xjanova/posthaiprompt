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
  final size = switch (sizeArg) {
    'phone' => const Size(390, 844),
    'tablet' => const Size(1180, 820),
    'small' => const Size(1024, 700),
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
