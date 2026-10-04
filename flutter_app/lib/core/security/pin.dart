// Thaiprompt POS — Staff PIN hashing.
//
// PINs are never stored in clear: sha256(salt + pin) with a random 16-byte
// salt per staff member, compared in constant time so response timing does
// not leak how many leading characters matched.
//
// by xman studio

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class PinHasher {
  PinHasher._();

  static final Random _rng = Random.secure();

  static String newSalt() {
    final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String hash(String pin, String salt) => sha256.convert(utf8.encode('$salt:$pin')).toString();

  static bool verify(String pin, String salt, String expectedHash) {
    if (expectedHash.isEmpty) return false;
    final actual = hash(pin, salt);
    if (actual.length != expectedHash.length) return false;
    var diff = 0;
    for (var i = 0; i < actual.length; i++) {
      diff |= actual.codeUnitAt(i) ^ expectedHash.codeUnitAt(i);
    }
    return diff == 0;
  }

  /// 4–6 digits only.
  static bool isValidPin(String pin) => RegExp(r'^\d{4,6}$').hasMatch(pin);

  /// Reject trivially guessable PINs (1111, 1234, 0000 …).
  static bool isWeak(String pin) {
    if (RegExp(r'^(\d)\1+$').hasMatch(pin)) return true;
    const seq = '01234567890';
    const rev = '09876543210';
    return seq.contains(pin) || rev.contains(pin);
  }
}
