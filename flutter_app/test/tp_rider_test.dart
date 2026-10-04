// Thai Prompt rider delivery: server product ids, request items, the server
// status → POS mapping, booking the bill exactly once, expiry / cancel, the
// persisted job shape and the customer-display QR.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:pos_thaiprompt/data/local_store.dart';
import 'package:pos_thaiprompt/display/display_snapshot.dart';
import 'package:pos_thaiprompt/models/extra_models.dart';
import 'package:pos_thaiprompt/models/order_models.dart';
import 'package:pos_thaiprompt/state/pos_store.dart';

const ownerPin = '482916';

PosStore signedIn() {
  final s = PosStore(disk: LocalStore(baseDir: Directory.systemTemp.createTempSync('pos_tp')));
  final owner = s.setupOwner(name: 'เจ้าของ', pin: ownerPin, shop: 'ร้านทดสอบ');
  expect(s.login(owner.id, ownerPin), isA<LoginOk>());
  s.upsertProductsFromApi([
    {'id': 881, 'sku': 'TT-01', 'name': 'ชาไทยเย็น', 'price': 65, 'stock': 100},
    {'id': '882', 'sku': 'CP-10', 'name': 'คาปูชิโน่', 'price': 75, 'stock': 80},
    {'sku': 'CR-21', 'name': 'ครัวซองต์', 'price': 55, 'stock': 5},
  ]);
  s.openShift(openingCash: 500);
  return s;
}

DeliveryJob newJob(PosStore s, {int requestId = 41}) => s.createTpRiderJob(
      requestId: requestId,
      qrPayload: 'TPPOS1.abc123',
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      lines: const [
        TpRiderLine(code: 'TT-01', name: 'ชาไทยเย็น', qty: 2, price: 60),
        TpRiderLine(code: 'CP-10', name: 'คาปูชิโน่', qty: 1, price: 75, options: 'ร้อน · หวานน้อย'),
      ],
      subtotal: 195,
      phone: '0812345678',
    );

void main() {
  test('sync maps the server product id (int or numeric string)', () {
    final s = signedIn();
    expect(s.productByCode('TT-01')!.serverId, 881);
    expect(s.productByCode('CP-10')!.serverId, 882);
    expect(s.productByCode('CR-21')!.serverId, isNull);
  });

  test('request items: one row per product with id + sku, options go to the note', () {
    final s = signedIn();
    s.addProduct(s.productByCode('TT-01')!, qty: 1);
    s.addProduct(s.productByCode('TT-01')!, options: ['หวานน้อย']);
    s.addProduct(s.productByCode('CR-21')!, note: 'อุ่นด้วย');
    final items = s.tpRiderRequestItems();
    expect(items, hasLength(2));
    expect(items.first, {'product_id': 881, 'sku': 'TT-01', 'name': 'ชาไทยเย็น', 'qty': 2});
    expect(items.last.containsKey('product_id'), isFalse);
    expect(s.tpRiderCartNote(), contains('หวานน้อย'));
    expect(s.tpRiderCartNote(), contains('อุ่นด้วย'));
  });

  test('creating a request keeps the cart and books nothing; same request id is reused', () {
    final s = signedIn();
    s.addProduct(s.productByCode('TT-01')!);
    final before = s.orders.length;
    final j = newJob(s);
    expect(j.awaitingPayment, isTrue);
    expect(j.orderId, isEmpty);
    expect(j.status, DeliveryStatus.pending);
    expect(s.orders.length, before);
    expect(s.cart, isNotEmpty);
    expect(identical(newJob(s), j), isTrue);
    expect(s.tpActiveJobs, [j]);
  });

  test('paid → POS bill booked exactly once at server prices, stock out, not COD', () {
    final s = signedIn();
    final j = newJob(s);
    final stock = s.productByCode('TT-01')!.stock;
    final paid = {
      'id': 41,
      'status': 'paid',
      'delivery_fee': 45.0,
      'order': {'id': 901, 'order_number': 'ORD-901'},
      'customer': {'display_name': 'สมชาย ก.', 'address_short': 'ซ.สุขุมวิท 101'},
      'rider_job': null,
      'handover': null,
    };
    expect(s.applyTpRiderStatus(j, paid), isTrue);
    final order = s.orderById(j.orderId)!;
    expect(order.method, PaymentMethod.thaiprompt);
    expect(order.total, 195);
    expect(order.discount, 0);
    expect(order.type, OrderType.delivery);
    expect(order.paymentRef, 'ORD-901');
    expect(order.lines.map((l) => l.price), [60, 75]);
    expect(order.lines.last.options, ['ร้อน', 'หวานน้อย']);
    expect(s.productByCode('TT-01')!.stock, stock - 2);
    expect(j.fee, 45);
    expect(j.customerName, 'สมชาย ก.');
    expect(j.status, DeliveryStatus.pending, reason: 'paid, rider not found yet');
    expect(j.tpStatusLabel, contains('หาไรเดอร์'));

    final count = s.orders.length;
    s.applyTpRiderStatus(j, paid);
    s.applyTpRiderStatus(j, {...paid, 'rider_job': {'status': 'accepted', 'job_number': 'JOB-1'}});
    expect(s.orders.length, count, reason: 'never booked twice');
    expect(s.checkoutBlockReason, isNotEmpty, reason: 'counter cart untouched (empty)');
  });

  test('rider statuses drive the board', () {
    final s = signedIn();
    final j = newJob(s);
    Map<String, dynamic> st(String rider) => {
          'status': 'paid',
          'rider_job': {
            'status': rider,
            'job_number': 'JOB-55',
            'rider': {'display_name': 'สมหญิง ข.', 'plate_masked': '1กข-**34', 'phone_masked': '08x-xxx-1234'},
          },
        };
    s.applyTpRiderStatus(j, st('accepted'));
    expect(j.status, DeliveryStatus.picking);
    expect(j.riderName, 'สมหญิง ข.');
    expect(j.trackingNo, 'JOB-55');
    s.applyTpRiderStatus(j, st('picked_up'));
    expect(j.status, DeliveryStatus.delivering);
    s.applyTpRiderStatus(j, st('awaiting_release'));
    expect(j.status, DeliveryStatus.delivering);
    s.applyTpRiderStatus(j, st('completed'));
    expect(j.status, DeliveryStatus.delivered);
    expect(j.deliveredAt, isNotNull);
    expect(j.tpActive, isFalse);
    expect(s.tpActiveJobs, isEmpty);
  });

  test('expired / cancelled close the job; a paid job is never closed locally', () {
    final s = signedIn();
    final a = newJob(s, requestId: 1);
    s.showRiderQr(a);
    expect(s.riderQrJob, a);
    s.applyTpRiderStatus(a, {'status': 'expired'});
    expect(a.status, DeliveryStatus.cancelled);
    expect(s.riderQrJob, isNull);
    expect(a.orderId, isEmpty);

    final b = newJob(s, requestId: 2);
    s.markTpRiderClosed(b);
    expect(b.payStatus, 'cancelled');
    expect(b.status, DeliveryStatus.cancelled);

    final c = newJob(s, requestId: 3);
    s.applyTpRiderStatus(c, {'status': 'paid'});
    s.markTpRiderClosed(c);
    expect(c.payStatus, 'paid');
    expect(c.status, isNot(DeliveryStatus.cancelled));
  });

  test('job JSON round-trips the Thai Prompt fields', () {
    final s = signedIn();
    final j = newJob(s);
    s.applyTpRiderStatus(j, {
      'status': 'paid',
      'order': {'order_number': 'ORD-9'},
      'rider_job': {'status': 'delivering', 'rider': {'display_name': 'ก', 'plate_masked': 'x'}},
      'handover': {'status': 'waiting'},
    });
    final back = DeliveryJob.fromJson(j.toJson());
    expect(back.isTpRider, isTrue);
    expect(back.requestId, 41);
    expect(back.payStatus, 'paid');
    expect(back.riderStatus, 'delivering');
    expect(back.handoverStatus, 'waiting');
    expect(back.remoteOrderNo, 'ORD-9');
    expect(back.lines.map((l) => l.total), [120, 75]);
    expect(back.orderId, j.orderId);
    // a manual job stays lean
    expect(DeliveryJob(id: 'DL-1', orderId: 'A1', createdAt: DateTime(2026)).toJson().containsKey('payStatus'), isFalse);
  });

  test('customer display carries the rider QR while it waits for payment', () {
    final s = signedIn();
    final j = newJob(s);
    s.showRiderQr(j);
    final snap = DisplaySnapshot.decode(DisplaySnapshot.fromStore(s).encode());
    expect(snap.riderQrPayload, 'TPPOS1.abc123');
    expect(snap.riderQrTotal, 195);
    expect(snap.riderQrLines, hasLength(2));
    expect(snap.riderQrActive(DateTime.now()), isTrue);
    expect(snap.riderQrActive(DateTime.now().add(const Duration(minutes: 20))), isFalse);

    s.applyTpRiderStatus(j, {'status': 'paid'});
    expect(DisplaySnapshot.fromStore(s).riderQrPayload, isNull, reason: 'QR leaves the screen once paid');
  });
}
