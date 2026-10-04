// Unit tests for the functional core: auth + lockout, cart math (coupons,
// promotions, member tiers, VAT add-on/inclusive), checkout guards, cash
// change, partial refunds, shift Z-report, tickets → kitchen → settle,
// split bills, purchase orders, persistence round-trip.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:pos_thaiprompt/data/local_store.dart';
import 'package:pos_thaiprompt/models/catalog_models.dart';
import 'package:pos_thaiprompt/models/extra_models.dart';
import 'package:pos_thaiprompt/models/order_models.dart';
import 'package:pos_thaiprompt/state/pos_store.dart';

const ownerPin = '482916';

/// Products in the exact shape /api/pos/sync/products returns.
void seedCatalog(PosStore store) {
  store.upsertCategoriesFromApi([
    {'id': 1, 'name': 'ของเย็น'},
    {'id': 2, 'name': 'กาแฟ'},
  ]);
  store.upsertProductsFromApi([
    {'sku': 'TT-01', 'name': 'ชาไทยเย็น', 'price': 65, 'cost': 20, 'stock': 100, 'category_id': 1},
    {'sku': 'CP-10', 'name': 'คาปูชิโน่', 'price': 75, 'cost': 25, 'stock': 80, 'category_id': 2},
    {'sku': 'CR-21', 'name': 'ครัวซองต์', 'price': 55, 'stock': 5, 'category_id': 2, 'barcode': '8850999320014'},
  ]);
}

PosStore signedIn({bool shift = true, Directory? dir}) {
  final s = PosStore(disk: LocalStore(baseDir: dir ?? Directory.systemTemp.createTempSync('pos_t')));
  final owner = s.setupOwner(name: 'เจ้าของ', pin: ownerPin, shop: 'ร้านทดสอบ');
  expect(s.login(owner.id, ownerPin), isA<LoginOk>());
  seedCatalog(s);
  if (shift) s.openShift(openingCash: 500);
  return s;
}

Product p(PosStore s, String code) => s.productByCode(code)!;

void main() {
  group('auth', () {
    test('first run needs setup, owner can log in, PIN is hashed', () {
      final s = PosStore(disk: LocalStore(baseDir: Directory.systemTemp.createTempSync('pos_a')));
      expect(s.needsSetup, isTrue);
      final o = s.setupOwner(name: 'แอน', pin: ownerPin);
      expect(s.needsSetup, isFalse);
      expect(o.pinHash, isNot(contains(ownerPin)));
      expect(o.pinHash.length, 64);
      expect(s.login(o.id, ownerPin), isA<LoginOk>());
      expect(s.currentStaff?.id, o.id);
      expect(s.isManager, isTrue);
      s.dispose();
    });

    test('5 wrong PINs lock the account for 2 minutes', () {
      var now = DateTime(2026, 10, 4, 9);
      final s = PosStore(disk: LocalStore(baseDir: Directory.systemTemp.createTempSync('pos_l')), clock: () => now);
      final o = s.setupOwner(name: 'แอน', pin: ownerPin);
      for (var i = 0; i < 4; i++) {
        expect(s.login(o.id, '000000'), isA<LoginWrongPin>());
      }
      expect(s.login(o.id, '000000'), isA<LoginLocked>());
      // even the right PIN is refused while locked
      expect(s.login(o.id, ownerPin), isA<LoginLocked>());
      now = now.add(const Duration(minutes: 3));
      expect(s.login(o.id, ownerPin), isA<LoginOk>());
      s.dispose();
    });

    test('manager override needs a manager PIN; cashiers cannot approve', () {
      final s = signedIn();
      final cashier = s.addStaff(name: 'บี', role: StaffRole.cashier, pin: '731905');
      expect(s.verifyManagerPin('731905'), isNull);
      expect(s.verifyManagerPin(ownerPin)?.role, StaffRole.owner);
      expect(s.pinInUse('731905'), isTrue);
      expect(s.pinInUse('731905', except: cashier), isFalse);
      expect(() => s.removeStaff(s.currentStaff!), throwsStateError);
      s.dispose();
    });
  });

  group('cart & discounts', () {
    late PosStore s;
    setUp(() => s = signedIn());
    tearDown(() => s.dispose());

    test('same product merges; options split lines and add their delta', () {
      s.addProduct(p(s, 'TT-01'));
      s.addProduct(p(s, 'TT-01'));
      s.addProduct(p(s, 'TT-01'), options: ['ใหญ่'], optionDelta: 15);
      expect(s.cart.length, 2);
      expect(s.cart.first.qty, 2);
      expect(s.cartSubtotal, 65 * 2 + 80);
    });

    test('cannot add beyond stock or unavailable products', () {
      final c = p(s, 'CR-21'); // stock 5
      expect(s.addProduct(c, qty: 5), isTrue);
      expect(s.addProduct(c), isFalse);
      s.setProductAvailable(p(s, 'TT-01'), false);
      expect(s.addProduct(p(s, 'TT-01')), isFalse);
    });

    test('scanner adds by barcode', () {
      expect(s.addByScan('8850999320014')?.code, 'CR-21');
      expect(s.addByScan('nope'), isNull);
    });

    test('VAT add-on vs inclusive', () {
      s.addProduct(p(s, 'CP-10'), qty: 2); // 150
      expect(s.cartTax, 11); // 150 × 7% = 10.5 → 11
      expect(s.cartTotal, 161);
      s.updateSettings(vatIncluded: true);
      expect(s.cartTax, 10); // 150 × 7/107 = 9.81 → 10
      expect(s.cartTotal, 150);
    });

    test('coupon + promotion + member tier stack, capped at subtotal', () {
      s.updateSettings(vatOn: false);
      s.upsertCoupon(CouponDef(code: 'TP20', name: 'ลด 20', value: 20, minSpend: 100));
      s.upsertPromotion(Promotion(id: 'p1', name: 'ลดกาแฟ 10%', value: 10, scope: PromoScope.category, categoryId: '2'));
      final m = s.addCustomer('สมาชิกทอง', phone: '0812345678');
      m.spent = 9000; // Gold → 5%
      s.addProduct(p(s, 'CP-10'), qty: 2); // 150, category 2
      s.addProduct(p(s, 'TT-01')); // 65 → subtotal 215
      expect(s.tryApplyCoupon('tp20'), isNull);
      s.linkCustomer(m);
      expect(s.couponDiscount, 20);
      expect(s.promoDiscount, 15); // 10% of 150
      expect(s.memberDiscount, 9); // 5% of (215-20-15)=180
      expect(s.cartDiscount, 44);
      expect(s.cartTotal, 171);
      expect(s.discountNote, contains('TP20'));
    });

    test('coupon errors are explained', () {
      s.upsertCoupon(CouponDef(code: 'BIG', name: 'x', value: 50, minSpend: 500));
      s.addProduct(p(s, 'TT-01'));
      expect(s.tryApplyCoupon('BIG'), contains('ขั้นต่ำ'));
      expect(s.tryApplyCoupon('NOPE'), 'ไม่พบคูปองนี้');
    });
  });

  group('checkout', () {
    test('blocked without a shift or login', () {
      final s = signedIn(shift: false);
      s.addProduct(p(s, 'TT-01'));
      expect(s.checkoutBlockReason, contains('เปิดกะ'));
      expect(s.checkout(method: PaymentMethod.cash), isNull);
      s.openShift();
      s.logout();
      expect(s.checkoutBlockReason, contains('เข้าสู่ระบบ'));
      s.dispose();
    });

    test('cash change, stock ledger, loyalty, order snapshot', () {
      final s = signedIn();
      s.updateSettings(vatOn: false);
      final m = s.addCustomer('บี', phone: '0899999999');
      s.linkCustomer(m);
      s.addProduct(p(s, 'TT-01'), qty: 2); // 130
      expect(s.checkout(method: PaymentMethod.cash, cashReceived: 100), isNull, reason: 'short cash');
      final o = s.checkout(method: PaymentMethod.cash, cashReceived: 200)!;
      expect(o.total, 130);
      expect(o.change, 70);
      expect(o.staffId, s.currentStaff!.id);
      expect(o.shiftId, s.currentShift!.id);
      expect(p(s, 'TT-01').stock, 98);
      expect(s.stockMoves.first.type, StockMoveType.sale);
      expect(m.points, 13); // basic tier 10 pts / ฿100
      expect(s.cart, isEmpty);
      expect(o.reference, startsWith('TP-${o.id}-'));
      expect(o.reference, o.reference, reason: 'stable');
      s.dispose();
    });

    test('partial then full refund restocks and adjusts totals', () {
      final s = signedIn();
      s.updateSettings(vatOn: false);
      s.addProduct(p(s, 'CP-10'), qty: 3); // 225
      final o = s.checkout(method: PaymentMethod.card, paymentRef: 'EDC 123456')!;
      final mgr = s.verifyManagerPin(ownerPin);
      expect(s.refundOrder(o, qtyByCode: {'CP-10': 1}, reason: 'เย็นไป', approvedBy: mgr), 75);
      expect(o.status, OrderStatus.paid);
      expect(o.netTotal, 150);
      expect(p(s, 'CP-10').stock, 78);
      expect(s.refundOrder(o), 150);
      expect(o.status, OrderStatus.refunded);
      expect(p(s, 'CP-10').stock, 80);
      expect(s.refundOrder(o), 0, reason: 'nothing left');
      s.dispose();
    });
  });

  group('shift', () {
    test('expected cash, movements, variance and Z number', () {
      final s = signedIn(); // float 500
      s.updateSettings(vatOn: false);
      s.addProduct(p(s, 'TT-01'), qty: 2);
      s.checkout(method: PaymentMethod.cash, cashReceived: 500); // +130 cash
      s.addProduct(p(s, 'CP-10'));
      s.checkout(method: PaymentMethod.promptpay); // not cash
      s.addCashMovement(CashMoveType.payOut, 30, reason: 'น้ำแข็ง');
      final sh = s.currentShift!;
      expect(s.shiftSales(sh), 205);
      expect(s.expectedCash(sh), 500 + 130 - 30);
      final z = s.closeShift(countedCash: 590)!;
      expect(z.cashVariance, -10);
      expect(z.byMethod['promptpay'], 75);
      expect(z.zNumber, 1);
      expect(s.hasOpenShift, isFalse);
      expect(s.shiftHistory.first, same(z));
      s.dispose();
    });
  });

  group('tables, tickets, kitchen', () {
    test('send to kitchen, bump, settle at the counter frees the table', () {
      final s = signedIn();
      final t = s.addTable(seats: 4);
      s.seatTable(t, 3);
      s.addProduct(p(s, 'TT-01'), qty: 2, note: 'หวานน้อย');
      final ticket = s.sendCartToKitchen()!;
      expect(ticket.tableNumber, t.number);
      expect(s.cart, isEmpty);
      expect(s.kitchenQueue.single.ticket, same(ticket));
      s.advanceEntry(s.kitchenQueue.single);
      expect(ticket.prep, PrepStatus.preparing);
      expect(s.tableBillTotal(t.number), 130);
      expect(s.loadTableToCart(t.number), isTrue);
      expect(t.status, TableStatus.billing);
      final o = s.checkout(method: PaymentMethod.cash)!;
      expect(o.ticketId, ticket.id);
      expect(ticket.status, TicketStatus.settled);
      expect(t.status, TableStatus.free);
      // a settled ticket keeps cooking until served; the paid order does not duplicate it
      expect(s.kitchenQueue.length, 1);
      s.advanceEntry(s.kitchenQueue.single);
      s.advanceEntry(s.kitchenQueue.single);
      expect(s.kitchenQueue, isEmpty);
      s.dispose();
    });

    test('self-order kiosk never touches the counter cart or payments', () {
      final s = signedIn();
      s.addTable(number: 7);
      s.setSelfTable(7);
      s.addProduct(p(s, 'CP-10'));
      s.addToSelfCart(p(s, 'TT-01'), qty: 2);
      final t = s.submitSelfOrder()!;
      expect(t.source, OrderSource.self);
      expect(s.cart.length, 1, reason: 'counter cart untouched');
      expect(s.orders, isEmpty, reason: 'no payment recorded');
      expect(s.lastSelfTicket, same(t));
      s.setCallWaiter(7, true);
      expect(s.tablesCallingWaiter, [7]);
      s.dispose();
    });

    test('split bill parks selected quantities', () {
      final s = signedIn();
      s.addProduct(p(s, 'TT-01'), qty: 3);
      final line = s.cart.single;
      final h = s.splitToHeld({line: 1}, label: 'คนที่ 2')!;
      expect(line.qty, 2);
      expect(h.total, 65);
      s.clearCart();
      s.resumeHeld(h);
      expect(s.cart.single.qty, 1);
      s.dispose();
    });
  });

  group('purchasing', () {
    test('receive PO adds stock and updates cost', () {
      final s = signedIn();
      final sup = s.addSupplier(name: 'ร้านนม');
      final po = s.createPurchaseOrder(sup, [PoLine(code: 'TT-01', name: 'ชาไทยเย็น', qty: 24, unitCost: 18)]);
      expect(po.id, 'PO-0001');
      s.markPoOrdered(po);
      s.receivePurchaseOrder(po);
      expect(po.status, PoStatus.received);
      expect(p(s, 'TT-01').stock, 124);
      expect(p(s, 'TT-01').cost, 18);
      s.receivePurchaseOrder(po);
      expect(p(s, 'TT-01').stock, 124, reason: 'idempotent');
      s.dispose();
    });
  });

  group('tax invoice', () {
    test('running number per Buddhist year, kept on re-issue', () {
      final s = signedIn();
      s.addProduct(p(s, 'TT-01'));
      final o = s.checkout(method: PaymentMethod.cash)!;
      final no = s.issueTaxInvoice(o, const TaxBuyer(name: 'บริษัท ก จำกัด', taxId: '0105551234567'));
      expect(no, 'INV-${o.createdAt.year + 543}-000001');
      expect(s.issueTaxInvoice(o, const TaxBuyer(name: 'x', taxId: '1')), no);
      s.dispose();
    });
  });

  group('persistence', () {
    test('everything round-trips through the atomic snapshot', () async {
      final dir = Directory.systemTemp.createTempSync('pos_p');
      final s = signedIn(dir: dir);
      s.addCategory('เบเกอรี่', iconKey: 'bakery');
      s.upsertProduct(Product(id: 'P9', code: 'P9', name: 'เค้ก', price: 89, categoryId: '', hue: 10, art: 'bakery'));
      s.addProduct(p(s, 'TT-01'));
      s.checkout(method: PaymentMethod.cash);
      s.upsertCoupon(CouponDef(code: 'A1', name: 'a', value: 5));
      await s.flush();
      final staffId = s.currentStaff!.id;
      s.dispose();

      final back = PosStore(disk: LocalStore(baseDir: dir));
      await back.init();
      expect(back.needsSetup, isFalse);
      expect(back.staffById(staffId), isNotNull);
      expect(back.productByCode('P9')?.art, 'bakery');
      expect(back.categories.any((c) => c.name == 'เบเกอรี่'), isTrue);
      expect(back.orders.length, 1);
      expect(back.couponByCode('A1'), isNotNull);
      expect(back.hasOpenShift, isTrue);
      expect(back.currentStaff, isNull, reason: 'session is never persisted');
      back.dispose();
    });

    test('corrupt main file falls back to the backup', () async {
      final dir = Directory.systemTemp.createTempSync('pos_c');
      final disk = LocalStore(baseDir: dir);
      await disk.save({'v': 2, 'settings': {'shopName': 'A'}});
      await disk.save({'v': 2, 'settings': {'shopName': 'B'}});
      File('${dir.path}/pos_state.json').writeAsStringSync('{broken');
      final s = PosStore(disk: LocalStore(baseDir: dir));
      await s.init();
      expect(s.restoredFromBackup, isTrue);
      expect(s.shopName, 'A');
      s.dispose();
    });
  });
}
