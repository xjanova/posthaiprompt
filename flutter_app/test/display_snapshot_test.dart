// Unit tests for the customer-display snapshot: fromStore mirrors the live
// cart (lines, totals, discounts, VAT label, member, PromptPay, promotions),
// JSON round-trip, tolerant fromJson, and the 20 s thank-you window driven by
// an injected store clock.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:pos_thaiprompt/core/payments/promptpay.dart';
import 'package:pos_thaiprompt/data/local_store.dart';
import 'package:pos_thaiprompt/display/display_snapshot.dart';
import 'package:pos_thaiprompt/models/catalog_models.dart';
import 'package:pos_thaiprompt/models/extra_models.dart';
import 'package:pos_thaiprompt/models/order_models.dart';
import 'package:pos_thaiprompt/state/pos_store.dart';

const ownerPin = '482916';
const shopPromptPay = '0812345678';

/// Signed-in store with a catalog (API shape) and an open shift.
PosStore buildStore(DateTime Function() clock) {
  final s = PosStore(disk: LocalStore(baseDir: Directory.systemTemp.createTempSync('pos_disp')), clock: clock);
  final owner = s.setupOwner(name: 'เจ้าของ', pin: ownerPin, shop: 'ร้านทดสอบ');
  expect(s.login(owner.id, ownerPin), isA<LoginOk>());
  s.upsertCategoriesFromApi([
    {'id': 1, 'name': 'ของเย็น'},
    {'id': 2, 'name': 'กาแฟ'},
  ]);
  s.upsertProductsFromApi([
    {'sku': 'TT-01', 'name': 'ชาไทยเย็น', 'price': 65, 'cost': 20, 'stock': 100, 'category_id': 1},
    {'sku': 'CP-10', 'name': 'คาปูชิโน่', 'price': 75, 'cost': 25, 'stock': 80, 'category_id': 2},
    {'sku': 'CR-21', 'name': 'ครัวซองต์', 'price': 55, 'stock': 5, 'category_id': 2},
  ]);
  s.openShift(openingCash: 500);
  return s;
}

Product p(PosStore s, String code) => s.productByCode(code)!;

void main() {
  group('fromStore', () {
    final t0 = DateTime(2026, 10, 4, 15, 0); // afternoon
    late PosStore s;
    late Customer member;

    setUp(() {
      s = buildStore(() => t0);
      s.updateSettings(promptPay: shopPromptPay, branchName: 'สาขาสยาม', footer: 'แล้วพบกันใหม่');
      s.upsertCoupon(CouponDef(code: 'TP20', name: 'ลด 20', value: 20, minSpend: 100));
      s.upsertPromotion(Promotion(id: 'p1', name: 'ลดกาแฟ 10%', value: 10, scope: PromoScope.category, categoryId: '2'));
      member = s.addCustomer('สมาชิกทอง', phone: '0898765432');
      member.spent = 9000; // Gold → 5%, 12 pts / ฿100
      member.points = 1234;
      s.addProduct(p(s, 'CP-10'), qty: 2); // 150, category 2
      s.addProduct(p(s, 'TT-01'), options: ['ใหญ่'], optionDelta: 15, note: 'หวานน้อย'); // 80
      expect(s.tryApplyCoupon('tp20'), isNull);
      s.linkCustomer(member);
      s.setTable(7);
    });
    tearDown(() => s.dispose());

    test('mirrors cart lines, totals, discount note and VAT label', () {
      final snap = DisplaySnapshot.fromStore(s, now: t0);
      expect(snap.shopName, 'ร้านทดสอบ');
      expect(snap.branch, 'สาขาสยาม');
      expect(snap.receiptFooter, 'แล้วพบกันใหม่');
      expect(snap.orderId, s.openOrderId);
      expect(snap.where, 'โต๊ะ 7');
      expect(snap.hasCart, isTrue);
      expect(snap.sentAt, t0);

      expect(snap.lines, hasLength(2));
      final cap = snap.lines[0];
      expect(cap.name, 'คาปูชิโน่');
      expect(cap.qty, 2);
      expect(cap.total, 150);
      expect(cap.unitPrice, 75);
      expect(cap.detail, '');
      expect(cap.iconKey, s.categoryById('2')!.iconKey);
      final tea = snap.lines[1];
      expect(tea.detail, 'ใหญ่ · หวานน้อย');
      expect(tea.total, 80);
      expect(tea.unitPrice, 80);

      expect(snap.itemCount, 3);
      expect(snap.subtotal, 230);
      // coupon 20 + promo 15 (10% of 150) + Gold 5% of 195 = 9
      expect(snap.discount, 44);
      expect(snap.discount, s.cartDiscount);
      expect(snap.tax, 13); // 186 × 7% = 13.02
      expect(snap.tax, s.cartTax);
      expect(snap.total, 199);
      expect(snap.total, s.cartTotal);
      expect(snap.discountNote, s.discountNote);
      expect(snap.discountNote, contains('TP20'));
      expect(snap.taxLabel, 'VAT 7%');

      // thank-you never shows over a live cart
      expect(snap.thanksUntil, isNull);
      expect(snap.thankYouActive(t0), isFalse);
    });

    test('member card data: tier, points, earn and next-tier hint', () {
      final snap = DisplaySnapshot.fromStore(s, now: t0);
      expect(snap.memberName, 'สมาชิกทอง');
      expect(snap.memberTier, 'Gold');
      expect(snap.memberPoints, 1234);
      expect(snap.memberEarn, (199 * 12 / 100).floor()); // 23
      expect(snap.memberNextHint, 'อีก ฿11,000 เลื่อนเป็น Premium');
      expect(snap.memberInitials, member.initials);
      expect(snap.memberHue, s.tierFor(member).hue);

      s.linkCustomer(null);
      final none = DisplaySnapshot.fromStore(s, now: t0);
      expect(none.memberName, isNull);
      expect(none.memberTier, isNull);
      expect(none.memberEarn, 0);
    });

    test('PromptPay payload for the exact total, only with a valid id and total > 0', () {
      final snap = DisplaySnapshot.fromStore(s, now: t0);
      expect(snap.promptPayPayload, PromptPay.payload(shopPromptPay, amountBaht: 199));
      expect(snap.promptPayMasked, PromptPay.mask(shopPromptPay));
      expect(snap.promptPayMasked, endsWith('5678'));

      s.updateSettings(promptPay: '123'); // invalid
      final bad = DisplaySnapshot.fromStore(s, now: t0);
      expect(bad.promptPayPayload, isNull);
      expect(bad.promptPayMasked, '');

      s.updateSettings(promptPay: shopPromptPay);
      s.clearCart();
      final empty = DisplaySnapshot.fromStore(s, now: t0);
      expect(empty.total, 0);
      expect(empty.promptPayPayload, isNull);
    });

    test('VAT label variants and order type', () {
      s.updateSettings(vatIncluded: true);
      expect(DisplaySnapshot.fromStore(s, now: t0).taxLabel, 'VAT 7% (รวมในราคาแล้ว)');
      s.updateSettings(vatOn: false);
      final noVat = DisplaySnapshot.fromStore(s, now: t0);
      expect(noVat.taxLabel, '');
      expect(noVat.tax, 0);
      s.setOrderType(OrderType.takeaway);
      expect(DisplaySnapshot.fromStore(s, now: t0).where, 'กลับบ้าน');
    });

    test('promotions: only the ones active now, with category name and art', () {
      s.upsertPromotion(Promotion(id: 'p2', name: 'แฮปปี้อาวร์', kind: DiscountKind.amount, value: 30, startHour: 14, endHour: 17));
      s.upsertPromotion(Promotion(id: 'p3', name: 'ปิดอยู่', value: 5, active: false));

      final at3pm = DisplaySnapshot.fromStore(s, now: t0);
      expect(at3pm.promos.map((x) => x.name), unorderedEquals(['ลดกาแฟ 10%', 'แฮปปี้อาวร์']));
      final cat = at3pm.promos.firstWhere((x) => x.name == 'ลดกาแฟ 10%');
      expect(cat.categoryName, 'กาแฟ');
      expect(cat.art, 'discount');
      final happy = at3pm.promos.firstWhere((x) => x.name == 'แฮปปี้อาวร์');
      expect(happy.categoryName, isNull);
      expect(happy.art, 'coupon');
      expect(happy.summary, contains('14:00'));

      final at6pm = DisplaySnapshot.fromStore(s, now: DateTime(2026, 10, 4, 18));
      expect(at6pm.promos.map((x) => x.name), ['ลดกาแฟ 10%']);
    });

    test('JSON round-trip keeps every field', () {
      final snap = DisplaySnapshot.fromStore(s, now: t0);
      final back = DisplaySnapshot.decode(snap.encode());
      expect(back.shopName, snap.shopName);
      expect(back.branch, snap.branch);
      expect(back.receiptFooter, snap.receiptFooter);
      expect(back.orderId, snap.orderId);
      expect(back.where, snap.where);
      expect(back.lines, snap.lines);
      expect(back.itemCount, snap.itemCount);
      expect(back.subtotal, snap.subtotal);
      expect(back.discount, snap.discount);
      expect(back.tax, snap.tax);
      expect(back.total, snap.total);
      expect(back.discountNote, snap.discountNote);
      expect(back.taxLabel, snap.taxLabel);
      expect(back.memberName, snap.memberName);
      expect(back.memberTier, snap.memberTier);
      expect(back.memberPoints, snap.memberPoints);
      expect(back.memberEarn, snap.memberEarn);
      expect(back.memberNextHint, snap.memberNextHint);
      expect(back.memberInitials, snap.memberInitials);
      expect(back.memberHue, snap.memberHue);
      expect(back.promptPayPayload, snap.promptPayPayload);
      expect(back.promptPayMasked, snap.promptPayMasked);
      expect(back.promos, snap.promos);
      expect(back.sentAt, snap.sentAt);
      expect(back.hasCart, isTrue);
      // re-encoding is stable
      expect(back.encode(), snap.encode());
    });
  });

  group('fromJson tolerance', () {
    test('empty map, empty() and junk values never throw', () {
      expect(() => DisplaySnapshot.fromJson(<String, dynamic>{}), returnsNormally);
      final e = DisplaySnapshot.fromJson(<String, dynamic>{});
      expect(e.hasCart, isFalse);
      expect(e.lines, isEmpty);
      expect(e.promos, isEmpty);
      expect(e.shopName, '');
      expect(e.total, 0);
      expect(e.memberName, isNull);
      expect(e.promptPayPayload, isNull);
      expect(e.thanksUntil, isNull);
      expect(e.thankYouActive(DateTime.now()), isFalse);
      expect(e.sentAt, DateTime.fromMillisecondsSinceEpoch(0));

      final junk = DisplaySnapshot.fromJson(<String, dynamic>{
        'lines': 'not a list',
        'total': '42',
        'subtotal': 12.7,
        'promos': [1, null, {'name': 'โปร A'}],
        'thanksUntil': 'not a date',
        'memberHue': null,
        'promptPayPayload': '',
        'shopName': 7,
      });
      expect(junk.lines, isEmpty);
      expect(junk.total, 42);
      expect(junk.subtotal, 12);
      expect(junk.promos, hasLength(1));
      expect(junk.promos.single.name, 'โปร A');
      expect(junk.promos.single.summary, '');
      expect(junk.promos.single.art, 'coupon');
      expect(junk.thanksUntil, isNull);
      expect(junk.memberHue, 40);
      expect(junk.promptPayPayload, isNull);
      expect(junk.shopName, '7');

      expect(DisplaySnapshot.fromJson({'lines': [<String, dynamic>{}]}).lines.single.qty, 0);
      expect(DisplaySnapshot.decode(DisplaySnapshot.empty().encode()).hasCart, isFalse);
      expect(() => DisplaySnapshot.decode('[1,2]'), throwsFormatException);
    });
  });

  group('thank-you window', () {
    test('20 s after checkout while the cart is empty (injected clock)', () {
      var now = DateTime(2026, 10, 4, 18, 30);
      final s = buildStore(() => now);
      final m = s.addCustomer('คุณลูกค้า', phone: '0811111111');
      s.addProduct(p(s, 'CP-10')); // 75 + VAT 5 = 80
      s.linkCustomer(m);
      final order = s.checkout(method: PaymentMethod.cash, cashReceived: 100);
      expect(order, isNotNull);
      expect(order!.createdAt, now);
      final paidAt = now;

      // 5 s later: thank-you with total, cash and change
      now = paidAt.add(const Duration(seconds: 5));
      final snap = DisplaySnapshot.fromStore(s, now: now);
      expect(snap.hasCart, isFalse);
      expect(snap.thanksOrderId, order.id);
      expect(snap.thanksTotal, order.total);
      expect(snap.thanksCash, 100);
      expect(snap.thanksChange, 100 - order.total);
      expect(snap.thanksMethod, 'เงินสด');
      expect(snap.thanksName, 'คุณลูกค้า');
      expect(snap.thanksUntil, paidAt.add(DisplaySnapshot.thanksFor));
      expect(snap.thankYouActive(now), isTrue);
      expect(snap.thankYouActive(paidAt.add(const Duration(milliseconds: 19999))), isTrue);
      expect(snap.thankYouActive(paidAt.add(const Duration(seconds: 20))), isFalse);
      expect(snap.thankYouActive(paidAt.add(const Duration(seconds: 25))), isFalse);

      // the window survives the trip to the second screen
      final back = DisplaySnapshot.decode(snap.encode());
      expect(back.thanksUntil, snap.thanksUntil);
      expect(back.thanksOrderId, order.id);
      expect(back.thanksCash, 100);
      expect(back.thanksChange, snap.thanksChange);
      expect(back.thanksMethod, 'เงินสด');
      expect(back.thankYouActive(now), isTrue);

      // built after the window → idle
      now = paidAt.add(const Duration(seconds: 25));
      final after = DisplaySnapshot.fromStore(s, now: now);
      expect(after.thanksUntil, isNull);
      expect(after.thanksOrderId, isNull);
      expect(after.thankYouActive(now), isFalse);

      // clock went backwards (order "in the future") → no thank-you
      final early = DisplaySnapshot.fromStore(s, now: paidAt.subtract(const Duration(seconds: 1)));
      expect(early.thanksUntil, isNull);

      // the cashier starts the next bill inside the window → cart wins
      now = paidAt.add(const Duration(seconds: 3));
      s.addProduct(p(s, 'TT-01'));
      final next = DisplaySnapshot.fromStore(s, now: now);
      expect(next.hasCart, isTrue);
      expect(next.thanksUntil, isNull);
      expect(next.thankYouActive(now), isFalse);
      s.dispose();
    });

    test('non-cash sale: no cash / change figures', () {
      var now = DateTime(2026, 10, 4, 12);
      final s = buildStore(() => now);
      s.addProduct(p(s, 'TT-01'));
      final order = s.checkout(method: PaymentMethod.promptpay);
      expect(order, isNotNull);
      now = now.add(const Duration(seconds: 1));
      final snap = DisplaySnapshot.fromStore(s, now: now);
      expect(snap.thankYouActive(now), isTrue);
      expect(snap.thanksCash, 0);
      expect(snap.thanksChange, 0);
      expect(snap.thanksMethod, 'พร้อมเพย์');
      expect(snap.thanksName, isNull);
      expect(snap.thanksTotal, order!.total);
      s.dispose();
    });
  });
}
