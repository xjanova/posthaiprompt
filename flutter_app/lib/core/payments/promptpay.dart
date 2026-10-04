// Thaiprompt POS — PromptPay QR payload (EMVCo merchant-presented, Thai QR).
//
// Builds the exact string a Thai banking app scans: tag 29 merchant account
// with AID A000000677010111, the PromptPay proxy (mobile → 0066XXXXXXXXX,
// 13-digit national/tax id, or 15-digit e-wallet id), currency 764, country
// TH, optional amount (dynamic QR, tag 01 = 12) and a CRC16/CCITT-FALSE
// checksum in tag 63.
//
// by xman studio

class PromptPay {
  PromptPay._();

  static const _aid = 'A000000677010111';

  /// Normalise a proxy id and say what kind it is, or null when invalid.
  static ({String tag, String value})? proxy(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10 && digits.startsWith('0')) {
      return (tag: '01', value: '0066${digits.substring(1)}');
    }
    if (digits.length == 11 && digits.startsWith('66')) {
      return (tag: '01', value: '00$digits');
    }
    if (digits.length == 13) return (tag: '02', value: digits);
    if (digits.length == 15) return (tag: '03', value: digits);
    return null;
  }

  static bool isValidId(String raw) => proxy(raw) != null;

  /// Full payload string. [amountBaht] null/0 → static QR (payer types amount).
  static String payload(String id, {double? amountBaht}) {
    final p = proxy(id);
    if (p == null) throw ArgumentError('รหัสพร้อมเพย์ไม่ถูกต้อง');
    final hasAmount = amountBaht != null && amountBaht > 0;
    final merchant = _f('00', _aid) + _f(p.tag, p.value);
    final b = StringBuffer()
      ..write(_f('00', '01'))
      ..write(_f('01', hasAmount ? '12' : '11'))
      ..write(_f('29', merchant))
      ..write(_f('53', '764'))
      ..write(hasAmount ? _f('54', amountBaht.toStringAsFixed(2)) : '')
      ..write(_f('58', 'TH'))
      ..write('6304');
    final body = b.toString();
    return body + crc16(body);
  }

  static String _f(String tag, String value) => '$tag${value.length.toString().padLeft(2, '0')}$value';

  /// CRC-16/CCITT-FALSE (poly 0x1021, init 0xFFFF), upper-case hex.
  static String crc16(String data) {
    var crc = 0xFFFF;
    for (final c in data.codeUnits) {
      crc ^= c << 8;
      for (var i = 0; i < 8; i++) {
        crc = (crc & 0x8000) != 0 ? ((crc << 1) ^ 0x1021) : (crc << 1);
        crc &= 0xFFFF;
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }

  /// Masked id for display: 08x-xxx-4567.
  static String mask(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.length < 4) return d;
    return '${'•' * (d.length - 4)}${d.substring(d.length - 4)}';
  }
}
