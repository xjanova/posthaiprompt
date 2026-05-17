// Smoke test — verify the app boots and the OverviewScreen renders.

import 'package:flutter_test/flutter_test.dart';

import 'package:pos_thaiprompt/main.dart';

void main() {
  testWidgets('App boots', (WidgetTester tester) async {
    await tester.pumpWidget(const ThaipromptPosApp());
    await tester.pump();

    // Brand title visible somewhere
    expect(find.text('Thaiprompt POS'), findsWidgets);
  });
}
