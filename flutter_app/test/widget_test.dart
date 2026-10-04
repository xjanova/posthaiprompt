// Widget test — proves the AppScope (InheritedNotifier) reactivity: a widget
// that reads the store rebuilds when the store mutates. The full screen layouts
// are font-metric sensitive (the Prompt font isn't loaded in the headless test
// harness), so end-to-end visuals are verified via `flutter build` + manual run;
// here we assert the data↔UI binding deterministically.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_thaiprompt/state/app_scope.dart';
import 'package:pos_thaiprompt/state/pos_store.dart';

void main() {
  testWidgets('AppScope subscribers rebuild when the store changes', (tester) async {
    final store = PosStore();
    addTearDown(store.dispose); // cancels any pending debounced-save timer

    await tester.pumpWidget(MaterialApp(
      home: Directionality(
        textDirection: TextDirection.ltr,
        child: AppScope(
          store: store,
          child: Builder(builder: (c) {
            final s = AppScope.of(c);
            return Text('items=${s.cartItemCount} total=${s.cartTotal}');
          }),
        ),
      ),
    ));

    expect(find.text('items=0 total=0'), findsOneWidget);

    // Inject one product in the real API shape (no demo seed anymore).
    store.upsertProductsFromApi([
      {'sku': 'T1', 'name': 'ทดสอบ', 'price': 50, 'stock': 10, 'category_id': 1},
    ]);
    store.addProduct(store.products.first);
    await tester.pump(const Duration(milliseconds: 500)); // flush debounce timer

    final p = store.products.first;
    final expectedTotal = store.cartTotal; // subtotal + VAT
    expect(find.text('items=1 total=$expectedTotal'), findsOneWidget);
    expect(p.price, lessThanOrEqualTo(expectedTotal));
  });
}
