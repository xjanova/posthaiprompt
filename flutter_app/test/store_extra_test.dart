// Pure helpers: PromptPay EMVCo payload + CRC, PIN hashing rules, Thai
// formatting, stable hashing, router guards.

import 'package:flutter_test/flutter_test.dart';

import 'package:pos_thaiprompt/core/format.dart';
import 'package:pos_thaiprompt/core/payments/promptpay.dart';
import 'package:pos_thaiprompt/core/security/pin.dart';
import 'package:pos_thaiprompt/models/catalog_models.dart';
import 'package:pos_thaiprompt/models/extra_models.dart';
import 'package:pos_thaiprompt/routes/app_router.dart';

void main() {
  group('PromptPay', () {
    test('CRC16/CCITT-FALSE known vector', () {
      expect(PromptPay.crc16('123456789'), '29B1');
    });

    test('mobile proxy payload with amount is well-formed and self-checking', () {
      final p = PromptPay.payload('081-234-5678', amountBaht: 125);
      expect(p, startsWith('000201010212'));
      expect(p, contains('0016A000000677010111'));
      expect(p, contains('01130066812345678'));
      expect(p, contains('5303764'));
      expect(p, contains('5406125.00'));
      expect(p, contains('5802TH'));
      final body = p.substring(0, p.length - 4);
      expect(p.substring(p.length - 4), PromptPay.crc16(body));
    });

    test('static QR without amount, tax-id proxy, invalid ids rejected', () {
      final p = PromptPay.payload('0105551234567');
      expect(p, startsWith('000201010211'));
      expect(p, contains('02130105551234567'));
      expect(RegExp(r'54\d{2}\d+\.\d{2}').hasMatch(p), isFalse, reason: 'no amount tag');
      expect(PromptPay.isValidId('12345'), isFalse);
      expect(() => PromptPay.payload('12345'), throwsArgumentError);
    });
  });

  group('PIN', () {
    test('salted hashes differ per salt and verify correctly', () {
      final a = PinHasher.newSalt();
      final b = PinHasher.newSalt();
      expect(PinHasher.hash('482916', a), isNot(PinHasher.hash('482916', b)));
      expect(PinHasher.verify('482916', a, PinHasher.hash('482916', a)), isTrue);
      expect(PinHasher.verify('482917', a, PinHasher.hash('482916', a)), isFalse);
      expect(PinHasher.verify('482916', a, ''), isFalse);
    });

    test('weak / invalid PINs', () {
      expect(PinHasher.isValidPin('123'), isFalse);
      expect(PinHasher.isValidPin('12a4'), isFalse);
      expect(PinHasher.isWeak('1111'), isTrue);
      expect(PinHasher.isWeak('1234'), isTrue);
      expect(PinHasher.isWeak('9876'), isTrue);
      expect(PinHasher.isWeak('482916'), isFalse);
    });
  });

  group('format', () {
    test('baht + digits', () {
      expect(baht(1335), '฿1,335');
      expect(baht(1335, decimals: true), '฿1,335.00');
      expect(baht(-50), '-฿50');
      expect(groupDigits(1234567), '1,234,567');
      expect(parseBaht('1,250'), 1250);
    });

    test('Buddhist-era dates and 24h time', () {
      final d = DateTime(2026, 5, 8, 14, 42);
      expect(thaiDate(d), '08 พ.ค. 2569');
      expect(hm(d), '14:42');
      expect(thaiDateTime(d), '08 พ.ค. 2569 · 14:42');
      expect(phoneFmt('0812345678'), '081-234-5678');
    });
  });

  test('stable hue/fnv is deterministic', () {
    expect(fnv1a('ชาไทย'), fnv1a('ชาไทย'));
    expect(stableHue('ชาไทย'), inInclusiveRange(0, 359));
  });

  test('Thai initials keep combining marks', () {
    final c = Customer(id: '1', name: 'นิ่ม');
    expect(c.initials, 'นิ่');
  });

  group('router guard', () {
    final owner = Staff(id: 'o', name: 'o', role: StaffRole.owner);
    final cashier = Staff(id: 'c', name: 'c', role: StaffRole.cashier);
    final cook = Staff(id: 'k', name: 'k', role: StaffRole.kitchen);

    test('setup, login, roles', () {
      expect(AppRouter.guardFor(needsSetup: true, me: null, loc: '/cashier'), '/setup');
      expect(AppRouter.guardFor(needsSetup: false, me: null, loc: '/cashier'), '/login');
      expect(AppRouter.guardFor(needsSetup: false, me: null, loc: '/login'), isNull);
      expect(AppRouter.guardFor(needsSetup: false, me: cashier, loc: '/login'), '/cashier');
      expect(AppRouter.guardFor(needsSetup: false, me: cashier, loc: '/settings'), '/home');
      expect(AppRouter.guardFor(needsSetup: false, me: owner, loc: '/settings'), isNull);
      expect(AppRouter.guardFor(needsSetup: false, me: cook, loc: '/cashier'), '/display/kitchen');
      expect(AppRouter.guardFor(needsSetup: false, me: cook, loc: '/display/kitchen'), isNull);
    });
  });
}
