// Thaiprompt POS — Thai formatting helpers (money, dates in พ.ศ., time).
//
// Anti-drift rule #9/#10: ฿ before the amount with no space, comma thousands,
// Buddhist-era years in user-facing dates, 24-hour time. Store Gregorian,
// format for display only. Use these everywhere instead of ad-hoc string math.
//
// by xman studio

const _thMonthsShort = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
const _thMonthsLong = [
  'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
  'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
];
const _thDays = ['จันทร์', 'อังคาร', 'พุธ', 'พฤหัสบดี', 'ศุกร์', 'เสาร์', 'อาทิตย์'];

/// 12345 → "12,345"
String groupDigits(int n) {
  final neg = n < 0;
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return neg ? '-$b' : b.toString();
}

/// ฿1,335 · ฿1,335.00 with [decimals] · -฿50 for negatives.
String baht(int amount, {bool decimals = false, bool sign = false}) {
  final neg = amount < 0;
  final body = '฿${groupDigits(amount.abs())}${decimals ? '.00' : ''}';
  if (neg) return '-$body';
  return sign && amount > 0 ? '+$body' : body;
}

/// Plain number with thousands separators and optional 2 decimals (no ฿).
String num2(num v, {int fraction = 2}) {
  final fixed = v.toStringAsFixed(fraction);
  final parts = fixed.split('.');
  final whole = groupDigits(int.parse(parts[0]));
  return fraction > 0 ? '$whole.${parts[1]}' : whole;
}

int beYear(DateTime d) => d.year + 543;

String _p2(int v) => v.toString().padLeft(2, '0');

/// 14:42
String hm(DateTime d) => '${_p2(d.hour)}:${_p2(d.minute)}';

/// 14:42:09
String hms(DateTime d) => '${_p2(d.hour)}:${_p2(d.minute)}:${_p2(d.second)}';

/// 08 พ.ค. 2569
String thaiDate(DateTime d) => '${_p2(d.day)} ${_thMonthsShort[d.month - 1]} ${beYear(d)}';

/// 8 พฤษภาคม 2569
String thaiDateLong(DateTime d) => '${d.day} ${_thMonthsLong[d.month - 1]} ${beYear(d)}';

/// วันศุกร์ที่ 8 พฤษภาคม 2569
String thaiDateFull(DateTime d) => 'วัน${_thDays[d.weekday - 1]}ที่ ${thaiDateLong(d)}';

/// 08 พ.ค. 2569 · 14:42
String thaiDateTime(DateTime d) => '${thaiDate(d)} · ${hm(d)}';

/// 08 พ.ค.
String thaiDayMonth(DateTime d) => '${_p2(d.day)} ${_thMonthsShort[d.month - 1]}';

String thaiMonthShort(int month) => _thMonthsShort[month - 1];
String thaiWeekdayShort(DateTime d) => const ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'][d.weekday - 1];

/// "เมื่อสักครู่" · "5 นาทีที่แล้ว" · "2 ชม.ที่แล้ว" · date
String timeAgo(DateTime d, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final diff = n.difference(d);
  if (diff.inSeconds < 45) return 'เมื่อสักครู่';
  if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
  if (diff.inHours < 24) return '${diff.inHours} ชม.ที่แล้ว';
  if (diff.inDays < 7) return '${diff.inDays} วันที่แล้ว';
  return thaiDate(d);
}

/// mm:ss elapsed (KDS ticket timers).
String elapsed(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return m >= 60 ? '${m ~/ 60}:${_p2(m % 60)}:${_p2(s)}' : '${_p2(m)}:${_p2(s)}';
}

/// Thai phone display: 0812345678 → 081-234-5678
String phoneFmt(String raw) {
  final d = raw.replaceAll(RegExp(r'\D'), '');
  if (d.length == 10) return '${d.substring(0, 3)}-${d.substring(3, 6)}-${d.substring(6)}';
  if (d.length == 9) return '${d.substring(0, 2)}-${d.substring(2, 5)}-${d.substring(5)}';
  return raw;
}

/// Parse a user-typed baht amount ("1,250" / "1250.50") → whole baht, or null.
int? parseBaht(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[^\d.]'), '');
  if (cleaned.isEmpty) return null;
  final v = double.tryParse(cleaned);
  return v?.round();
}
