// Demo dataset for screenshot / smoke tests ONLY (never shipped in the app —
// the POS starts empty and fills from the shop's real catalog).

import 'dart:io';
import 'dart:math';

import 'package:pos_thaiprompt/data/local_store.dart';
import 'package:pos_thaiprompt/models/catalog_models.dart';
import 'package:pos_thaiprompt/models/extra_models.dart';
import 'package:pos_thaiprompt/models/order_models.dart';
import 'package:pos_thaiprompt/state/pos_store.dart';

const demoPin = '482916';

PosStore buildDemoStore() {
  final s = PosStore(disk: LocalStore(baseDir: Directory.systemTemp.createTempSync('pos_demo')));
  final owner = s.setupOwner(name: 'คุณแพรวา', pin: demoPin, shop: 'ไทยพร้อม คาเฟ่', branchName: 'สาขาเจริญกรุง');
  s.updateSettings(phone: '0812345678', address: '123 ถ.เจริญกรุง บางรัก กรุงเทพฯ 10500', taxNumber: '0105561234567', promptPay: '0812345678');
  s.addStaff(name: 'ธนา', role: StaffRole.cashier, pin: '731905');
  s.addStaff(name: 'มะลิ', role: StaffRole.waiter, pin: '640218');
  s.addStaff(name: 'เชฟต้น', role: StaffRole.kitchen, pin: '905173');
  s.login(owner.id, demoPin);

  final cats = [
    s.addCategory('ชาและนม', iconKey: 'drink'),
    s.addCategory('กาแฟ', iconKey: 'coffee'),
    s.addCategory('อาหารจานเดียว', iconKey: 'rice'),
    s.addCategory('เส้น', iconKey: 'noodle'),
    s.addCategory('ของหวาน', iconKey: 'dessert'),
    s.addCategory('เบเกอรี่', iconKey: 'bakery'),
  ];
  final size = [const OptionGroup(name: 'ขนาด', required: true, choices: [OptionChoice('ปกติ'), OptionChoice('ใหญ่', 15)])];
  final sweet = [
    ...size,
    const OptionGroup(name: 'ความหวาน', required: true, choices: [OptionChoice('หวานปกติ'), OptionChoice('หวานน้อย'), OptionChoice('ไม่หวาน')]),
    const OptionGroup(name: 'ท็อปปิ้ง', multi: true, choices: [OptionChoice('ไข่มุก', 10), OptionChoice('วิปครีม', 15)]),
  ];
  final items = <(String, int, int, int, String, String?, List<OptionGroup>, int)>[
    ('ชาไทยเย็น', 65, 18, 0, 'thai_tea', 'ขายดี', sweet, 120),
    ('ชาเขียวนม', 70, 20, 0, 'thai_tea', null, sweet, 80),
    ('น้ำส้มคั้นสด', 75, 25, 0, 'juice', 'ใหม่', size, 40),
    ('ลาเต้ร้อน', 75, 22, 1, 'coffee', 'ขายดี', size, 200),
    ('อเมริกาโน่เย็น', 70, 18, 1, 'coffee', null, size, 200),
    ('มอคค่า', 85, 26, 1, 'coffee', 'พรีเมียม', size, 4),
    ('ข้าวกะเพราไข่ดาว', 89, 35, 2, 'rice', 'ขายดี', const [], 60),
    ('ข้าวผัดกุ้ง', 99, 42, 2, 'rice', null, const [], 50),
    ('ผัดไทยกุ้งสด', 109, 45, 3, 'noodle', 'ขายดี', const [], 45),
    ('ก๋วยเตี๋ยวเรือ', 79, 30, 3, 'noodle', null, const [], 0),
    ('ข้าวเหนียวมะม่วง', 119, 40, 4, 'dessert', 'พรีเมียม', const [], 25),
    ('ปอเปี๊ยะทอด', 69, 22, 4, 'snack', null, const [], 30),
    ('ครัวซองต์เนยสด', 65, 24, 5, 'bakery', null, const [], 18),
    ('เค้กส้ม', 95, 32, 5, 'bakery', 'ใหม่', const [], 3),
  ];
  for (var i = 0; i < items.length; i++) {
    final it = items[i];
    final code = s.nextProductCode();
    s.upsertProduct(Product(
      id: code,
      code: code,
      name: it.$1,
      price: it.$2,
      cost: it.$3,
      categoryId: cats[it.$4].id,
      hue: stableHue(it.$1),
      art: it.$5,
      tag: it.$6,
      options: it.$7,
      stock: it.$8,
      barcode: '88500000${(1000 + i).toString()}',
    ));
  }

  final members = [
    s.addCustomer('สมชาย ใจดี', phone: '0891112222'),
    s.addCustomer('วิภา ศรีสุข', phone: '0823334444', email: 'wipa@example.com'),
    s.addCustomer('Kenji Tanaka', phone: '0865556666'),
    s.addCustomer('นภา รุ่งเรือง', phone: '0817778888'),
  ];
  members[0].spent = 24500;
  members[0].points = 2310;
  members[1].spent = 9200;
  members[1].points = 870;
  members[2].spent = 2600;
  members[2].points = 240;

  for (var i = 0; i < 8; i++) {
    s.addTable(seats: i % 3 == 0 ? 2 : (i % 3 == 1 ? 4 : 6), shape: i % 3 == 0 ? TableShape.round : (i % 3 == 1 ? TableShape.square : TableShape.rect), zone: i < 6 ? 'ในร้าน' : 'ระเบียง');
  }

  s.upsertCoupon(CouponDef(code: 'WELCOME50', name: 'ต้อนรับสมาชิกใหม่', value: 50, minSpend: 300));
  s.upsertCoupon(CouponDef(code: 'TEA10', name: 'ชาลด 10%', kind: DiscountKind.percent, value: 10, maxDiscount: 40));
  s.upsertPromotion(Promotion(id: s.newPromotionId(), name: 'Happy Hour กาแฟ', value: 15, scope: PromoScope.category, categoryId: cats[1].id, startHour: 14, endHour: 17));
  s.upsertPromotion(Promotion(id: s.newPromotionId(), name: 'ครบ 500 ลด 40', kind: DiscountKind.amount, value: 40, minSpend: 500));

  final sup = s.addSupplier(name: 'บริษัท นมสดไทย จำกัด', category: 'วัตถุดิบ', phone: '021234567', contact: 'คุณเอ');
  s.addSupplier(name: 'ร้านผักป้าศรี', category: 'ผักสด', phone: '0899990000');
  final po = s.createPurchaseOrder(sup, [PoLine(code: 'P0001', name: 'ชาไทยเย็น', qty: 48, unitCost: 17)], note: 'ส่งก่อน 9 โมง');
  s.markPoOrdered(po);

  // history: orders over the last 7 days (deterministic)
  s.openShift(openingCash: 1000);
  final rnd = Random(42);
  final now = DateTime.now();
  for (var d = 6; d >= 0; d--) {
    final n = 6 + rnd.nextInt(8);
    for (var k = 0; k < n; k++) {
      final lines = 1 + rnd.nextInt(3);
      for (var j = 0; j < lines; j++) {
        final p = s.products[rnd.nextInt(s.products.length)];
        if (p.canSell) s.addProduct(p, qty: 1 + rnd.nextInt(2));
      }
      if (s.cart.isEmpty) continue;
      if (k % 4 == 0) s.linkCustomer(members[rnd.nextInt(members.length)]);
      final m = PaymentMethod.values[rnd.nextInt(PaymentMethod.values.length)];
      final o = s.checkout(method: m, cashReceived: m == PaymentMethod.cash ? ((s.cartTotal ~/ 100) + 1) * 100 : 0, paymentRef: m == PaymentMethod.card ? 'EDC 0${100000 + rnd.nextInt(899999)}' : null);
      if (o == null) continue;
      // backdate (createdAt is final → rebuild from json)
      final j = o.toJson()..['createdAt'] = now.subtract(Duration(days: d, hours: 9 - (k % 9), minutes: rnd.nextInt(50))).toIso8601String();
      if (d > 0) j['shiftId'] = null;
      final i = s.orders.indexOf(o);
      s.orders[i] = Order.fromJson(j)..prep = PrepStatus.served;
    }
  }
  // one refund today
  final todays = s.ordersOn(now);
  if (todays.isNotEmpty) s.refundOrder(todays.first, reason: 'ลูกค้าเปลี่ยนใจ', approvedBy: s.currentStaff);

  // live kitchen + tables
  s.seatTable(s.tables[1], 3);
  s.addProduct(s.products[0], options: ['ใหญ่', 'หวานน้อย'], optionDelta: 15, note: 'แยกน้ำแข็ง');
  s.addProduct(s.products[6], qty: 2);
  s.sendCartToKitchen();
  s.seatTable(s.tables[4], 5);
  s.addProduct(s.products[8]);
  s.addProduct(s.products[10]);
  s.sendCartToKitchen();
  s.advanceEntry(s.kitchenQueue.last);
  s.setSelfTable(s.tables[6].number);
  s.addToSelfCart(s.products[3], options: ['ใหญ่'], optionDelta: 15);
  s.submitSelfOrder(note: 'ขอช้อนเพิ่ม');
  s.setCallWaiter(s.tables[6].number, true);
  s.setTableStatus(s.tables[2], TableStatus.reserved, reservedFor: 'คุณวิภา 19:00');

  final paid = s.paidOrders.first;
  final job = s.createDelivery(paid, customerName: 'คุณนภา', phone: '0817778888', address: '88/9 ซ.สุขุมวิท 31 วัฒนา กทม. 10110', providerId: 'lineman', cod: false);
  s.updateDelivery(job, trackingNo: 'LM2610040012', riderName: 'พี่โอ๊ต');
  s.advanceDelivery(job);
  // Thai Prompt rider: one waiting for the customer to pay in the app, one on the road
  TpRiderLine line(int i, int qty) => TpRiderLine(code: s.products[i].code, name: s.products[i].name, qty: qty, price: s.products[i].price);
  final road = s.createTpRiderJob(
    requestId: 40,
    qrPayload: 'TPPOS1.demo40',
    expiresAt: DateTime.now().add(const Duration(minutes: 3)),
    lines: [line(2, 1), line(7, 2)],
    subtotal: s.products[2].price + s.products[7].price * 2,
  );
  s.applyTpRiderStatus(road, {
    'status': 'paid',
    'delivery_fee': 42,
    'order': {'id': 901, 'order_number': 'ORD-2610-0901'},
    'customer': {'display_name': 'คุณมาลี ส.', 'address_short': 'คอนโดลุมพินี ทาวเวอร์ ชั้น 12 ห้อง 1205'},
    'rider_job': {
      'status': 'delivering',
      'job_number': 'JOB-26100455',
      'rider': {'display_name': 'สมชาย ก.', 'plate_masked': '1กข-**34', 'phone_masked': '08x-xxx-4521'},
    },
  });
  s.createTpRiderJob(
    requestId: 41,
    qrPayload: 'TPPOS1.k3J9xQ2mVb7LpR4tYw8Zc1Nd6Hf0Gs5Ae9Ku3Jo',
    expiresAt: DateTime.now().add(const Duration(minutes: 12, seconds: 30)),
    lines: [line(1, 2), line(5, 1)],
    subtotal: s.products[1].price * 2 + s.products[5].price,
    phone: '0891234567',
  );
  s.updateProvider(s.providerById('lineman')!, enabled: true, baseFee: 35);
  s.updateProvider(s.providerById('flash')!, enabled: true, baseFee: 45);

  // a live counter cart for cashier / payment / customer display shots
  s.setTable(s.tables[0].number);
  s.addProduct(s.products[3], options: ['ใหญ่'], optionDelta: 15);
  s.addProduct(s.products[6]);
  s.addProduct(s.products[12], qty: 2);
  s.linkCustomer(members[1]);
  s.tryApplyCoupon('TEA10');
  s.holdCart(label: 'โต๊ะ 8 · รอเพื่อน');
  s.setTable(s.tables[0].number);
  s.addProduct(s.products[3], options: ['ใหญ่'], optionDelta: 15);
  s.addProduct(s.products[6]);
  s.addProduct(s.products[12], qty: 2);
  s.linkCustomer(members[1]);
  return s;
}
