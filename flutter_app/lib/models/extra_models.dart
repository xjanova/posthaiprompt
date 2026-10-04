// Thaiprompt POS — Back-office domain models.
//
// Customers (CRM/loyalty), Staff (roles + hashed PIN), dining Tables (with
// floor-plan layout), the cash Shift (drawer movements + count), Suppliers and
// Purchase Orders, Stock movements, Coupons, Promotions, Membership tiers,
// Delivery jobs, Shipping providers, Branches and the Audit log. Every model
// round-trips through JSON so the whole back office persists offline.
//
// by xman studio

import 'catalog_models.dart' show fnv1a;

DateTime? _dt(Object? v) => v == null ? null : DateTime.tryParse(v as String);
int _i(Object? v, [int d = 0]) => (v as num?)?.toInt() ?? d;

// ───────────────────────────── CRM ─────────────────────────────

class Customer {
  final String id;
  String name;
  String phone;
  String email;
  String note;
  DateTime? birthday;
  int points;
  int visits;
  int spent; // lifetime baht
  final DateTime createdAt;
  String referralCode; // affiliate: who referred / own code

  Customer({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.note = '',
    this.birthday,
    this.points = 0,
    this.visits = 0,
    this.spent = 0,
    DateTime? createdAt,
    this.referralCode = '',
  }) : createdAt = createdAt ?? DateTime.now();

  /// Legacy fallback tier name (the store resolves tiers from [MembershipTier]
  /// definitions via `PosStore.tierFor`; this keeps old callers working).
  String get tier {
    if (spent >= 20000) return 'Premium';
    if (spent >= 8000) return 'Gold';
    if (spent >= 2000) return 'Silver';
    return 'ทั่วไป';
  }

  String get initials => name.isEmpty ? '?' : name.characters1;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'note': note,
        'birthday': birthday?.toIso8601String(),
        'points': points,
        'visits': visits,
        'spent': spent,
        'createdAt': createdAt.toIso8601String(),
        'referralCode': referralCode,
      };

  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
        id: j['id'] as String,
        name: j['name'] as String,
        phone: (j['phone'] as String?) ?? '',
        email: (j['email'] as String?) ?? '',
        note: (j['note'] as String?) ?? '',
        birthday: _dt(j['birthday']),
        points: _i(j['points']),
        visits: _i(j['visits']),
        spent: _i(j['spent']),
        createdAt: _dt(j['createdAt']),
        referralCode: (j['referralCode'] as String?) ?? '',
      );
}

extension _FirstChar on String {
  /// First user-perceived character for avatars (keeps Thai combining marks
  /// attached to their base — never slice a UTF-16 unit in half).
  String get characters1 {
    if (isEmpty) return '';
    final runes = this.runes.toList();
    // skip Thai leading vowels (เ แ โ ใ ไ) so "เชฟ" → "ช", not "เ"
    var start = 0;
    while (start < runes.length - 1 && runes[start] >= 0x0E40 && runes[start] <= 0x0E44) {
      start++;
    }
    final buf = StringBuffer(String.fromCharCode(runes[start]));
    for (var i = start + 1; i < runes.length; i++) {
      final r = runes[i];
      final isThaiMark = (r >= 0x0E31 && r <= 0x0E3A && r != 0x0E32 && r != 0x0E33) || (r >= 0x0E47 && r <= 0x0E4E);
      if (!isThaiMark) break;
      buf.write(String.fromCharCode(r));
    }
    return buf.toString();
  }
}

/// A loyalty tier definition (editable on the tiers screen).
class MembershipTier {
  final String id;
  String name;
  int minSpent; // lifetime baht to reach this tier
  int discountPercent; // auto discount at checkout for linked members
  int pointsPer100; // points earned per ฿100
  int hue; // card color

  MembershipTier({
    required this.id,
    required this.name,
    required this.minSpent,
    this.discountPercent = 0,
    this.pointsPer100 = 10,
    this.hue = 40,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'minSpent': minSpent,
        'discountPercent': discountPercent,
        'pointsPer100': pointsPer100,
        'hue': hue,
      };

  factory MembershipTier.fromJson(Map<String, dynamic> j) => MembershipTier(
        id: j['id'] as String,
        name: j['name'] as String,
        minSpent: _i(j['minSpent']),
        discountPercent: _i(j['discountPercent']),
        pointsPer100: _i(j['pointsPer100'], 10),
        hue: _i(j['hue'], 40),
      );

  static List<MembershipTier> defaults() => [
        MembershipTier(id: 'tier-basic', name: 'ทั่วไป', minSpent: 0, discountPercent: 0, pointsPer100: 10, hue: 215),
        MembershipTier(id: 'tier-silver', name: 'Silver', minSpent: 2000, discountPercent: 3, pointsPer100: 10, hue: 220),
        MembershipTier(id: 'tier-gold', name: 'Gold', minSpent: 8000, discountPercent: 5, pointsPer100: 12, hue: 42),
        MembershipTier(id: 'tier-premium', name: 'Premium', minSpent: 20000, discountPercent: 10, pointsPer100: 15, hue: 268),
      ];
}

// ───────────────────────────── Staff ─────────────────────────────

enum StaffRole { owner, manager, cashier, waiter, kitchen }

extension StaffRoleX on StaffRole {
  String get label => switch (this) {
        StaffRole.owner => 'เจ้าของร้าน',
        StaffRole.manager => 'ผู้จัดการ',
        StaffRole.cashier => 'แคชเชียร์',
        StaffRole.waiter => 'พนักงานเสิร์ฟ',
        StaffRole.kitchen => 'ครัว',
      };

  /// May approve refunds/voids, open the drawer, edit menu/settings/staff.
  bool get isManager => this == StaffRole.owner || this == StaffRole.manager;
  bool get canSell => this != StaffRole.kitchen;

  /// Landing route after login.
  String get home => switch (this) {
        StaffRole.kitchen => '/display/kitchen',
        StaffRole.waiter => '/tablet/floor',
        _ => '/cashier',
      };
}

class Staff {
  final String id;
  String name;
  StaffRole role;
  String phone;
  String pinHash; // sha256(salt + pin) hex
  String pinSalt;
  bool active;
  int hue;
  // runtime-ish but persisted so a restart keeps clock state + lockouts
  bool online; // clocked in
  DateTime? clockedInAt;
  int failedAttempts;
  DateTime? lockedUntil;
  int salesToday; // legacy field; the store computes live totals from orders

  Staff({
    required this.id,
    required this.name,
    this.role = StaffRole.cashier,
    this.phone = '',
    this.pinHash = '',
    this.pinSalt = '',
    this.active = true,
    int? hue,
    this.online = false,
    this.clockedInAt,
    this.failedAttempts = 0,
    this.lockedUntil,
    this.salesToday = 0,
  }) : hue = hue ?? (fnv1a(id) % 360);

  bool get hasPin => pinHash.isNotEmpty;
  bool get isLocked => lockedUntil != null && DateTime.now().isBefore(lockedUntil!);
  String get initials => name.isEmpty ? '?' : name.characters1;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role.name,
        'phone': phone,
        'pinHash': pinHash,
        'pinSalt': pinSalt,
        'active': active,
        'hue': hue,
        'online': online,
        'clockedInAt': clockedInAt?.toIso8601String(),
        'failedAttempts': failedAttempts,
        'lockedUntil': lockedUntil?.toIso8601String(),
      };

  factory Staff.fromJson(Map<String, dynamic> j) => Staff(
        id: j['id'] as String,
        name: j['name'] as String,
        role: StaffRole.values.firstWhere((r) => r.name == j['role'], orElse: () => StaffRole.cashier),
        phone: (j['phone'] as String?) ?? '',
        pinHash: (j['pinHash'] as String?) ?? '',
        pinSalt: (j['pinSalt'] as String?) ?? '',
        active: (j['active'] as bool?) ?? true,
        hue: (j['hue'] as num?)?.toInt(),
        online: (j['online'] as bool?) ?? false,
        clockedInAt: _dt(j['clockedInAt']),
        failedAttempts: _i(j['failedAttempts']),
        lockedUntil: _dt(j['lockedUntil']),
      );
}

/// Result of a PIN login attempt.
sealed class LoginResult {
  const LoginResult();
}

class LoginOk extends LoginResult {
  final Staff staff;
  const LoginOk(this.staff);
}

class LoginWrongPin extends LoginResult {
  final int attemptsLeft;
  const LoginWrongPin(this.attemptsLeft);
}

class LoginLocked extends LoginResult {
  final DateTime until;
  const LoginLocked(this.until);
}

// ───────────────────────────── Tables ─────────────────────────────

enum TableStatus { free, seated, reserved, billing }

extension TableStatusX on TableStatus {
  String get label => switch (this) {
        TableStatus.free => 'ว่าง',
        TableStatus.seated => 'นั่งอยู่',
        TableStatus.reserved => 'จอง',
        TableStatus.billing => 'รอเช็คบิล',
      };
}

enum TableShape { round, square, rect }

class TableInfo {
  int number;
  int seats;
  TableStatus status;
  int guests;
  double x; // 0..1 of the floor canvas width
  double y; // 0..1 of the floor canvas height
  TableShape shape;
  String zone; // 'ในร้าน' | 'ระเบียง' | 'ห้อง VIP'
  DateTime? seatedAt;
  String? reservedFor;
  bool callWaiter; // customer pressed "เรียกพนักงาน" on the table kiosk

  TableInfo({
    required this.number,
    required this.seats,
    this.status = TableStatus.free,
    this.guests = 0,
    this.x = 0.1,
    this.y = 0.1,
    this.shape = TableShape.square,
    this.zone = 'ในร้าน',
    this.seatedAt,
    this.reservedFor,
    this.callWaiter = false,
  });

  Map<String, dynamic> toJson() => {
        'number': number,
        'seats': seats,
        'status': status.name,
        'guests': guests,
        'x': x,
        'y': y,
        'shape': shape.name,
        'zone': zone,
        'seatedAt': seatedAt?.toIso8601String(),
        'reservedFor': reservedFor,
        'callWaiter': callWaiter,
      };

  factory TableInfo.fromJson(Map<String, dynamic> j) => TableInfo(
        number: _i(j['number']),
        seats: _i(j['seats'], 2),
        status: TableStatus.values.firstWhere((s) => s.name == j['status'], orElse: () => TableStatus.free),
        guests: _i(j['guests']),
        x: (j['x'] as num?)?.toDouble() ?? 0.1,
        y: (j['y'] as num?)?.toDouble() ?? 0.1,
        shape: TableShape.values.firstWhere((s) => s.name == j['shape'], orElse: () => TableShape.square),
        zone: (j['zone'] as String?) ?? 'ในร้าน',
        seatedAt: _dt(j['seatedAt']),
        reservedFor: j['reservedFor'] as String?,
        callWaiter: (j['callWaiter'] as bool?) ?? false,
      );
}

// ───────────────────────────── Shift / cash drawer ─────────────────────────────

enum CashMoveType { payIn, payOut, drop }

extension CashMoveTypeX on CashMoveType {
  String get label => switch (this) {
        CashMoveType.payIn => 'นำเงินเข้า',
        CashMoveType.payOut => 'นำเงินออก',
        CashMoveType.drop => 'ส่งเงินเข้าตู้เซฟ',
      };
  int get sign => this == CashMoveType.payIn ? 1 : -1;
}

class CashMovement {
  final DateTime at;
  final CashMoveType type;
  final int amount;
  final String reason;
  final String by;
  const CashMovement({required this.at, required this.type, required this.amount, this.reason = '', this.by = ''});

  Map<String, dynamic> toJson() =>
      {'at': at.toIso8601String(), 'type': type.name, 'amount': amount, 'reason': reason, 'by': by};
  factory CashMovement.fromJson(Map<String, dynamic> j) => CashMovement(
        at: DateTime.parse(j['at'] as String),
        type: CashMoveType.values.firstWhere((t) => t.name == j['type'], orElse: () => CashMoveType.payIn),
        amount: _i(j['amount']),
        reason: (j['reason'] as String?) ?? '',
        by: (j['by'] as String?) ?? '',
      );
}

class Shift {
  final String id;
  final DateTime openedAt;
  DateTime? closedAt;
  final int openingCash;
  final String cashier;
  final String? staffId;
  final List<CashMovement> movements;
  // ── close-out snapshot (Z-report) ──
  int? countedCash;
  int? expectedCash;
  int salesTotal;
  int orderCount;
  int refundTotal;
  Map<String, int> byMethod; // PaymentMethod.name → baht
  String closedBy;
  String note;
  int zNumber;

  Shift({
    required this.id,
    required this.openedAt,
    this.closedAt,
    this.openingCash = 0,
    required this.cashier,
    this.staffId,
    List<CashMovement>? movements,
    this.countedCash,
    this.expectedCash,
    this.salesTotal = 0,
    this.orderCount = 0,
    this.refundTotal = 0,
    Map<String, int>? byMethod,
    this.closedBy = '',
    this.note = '',
    this.zNumber = 0,
  })  : movements = movements ?? <CashMovement>[],
        byMethod = byMethod ?? <String, int>{};

  bool get isOpen => closedAt == null;
  int get cashVariance => (countedCash ?? 0) - (expectedCash ?? 0);
  int get movementNet => movements.fold(0, (s, m) => s + m.type.sign * m.amount);

  Map<String, dynamic> toJson() => {
        'id': id,
        'openedAt': openedAt.toIso8601String(),
        'closedAt': closedAt?.toIso8601String(),
        'openingCash': openingCash,
        'cashier': cashier,
        'staffId': staffId,
        'movements': movements.map((m) => m.toJson()).toList(),
        'countedCash': countedCash,
        'expectedCash': expectedCash,
        'salesTotal': salesTotal,
        'orderCount': orderCount,
        'refundTotal': refundTotal,
        'byMethod': byMethod,
        'closedBy': closedBy,
        'note': note,
        'zNumber': zNumber,
      };

  factory Shift.fromJson(Map<String, dynamic> j) => Shift(
        id: j['id'] as String,
        openedAt: DateTime.parse(j['openedAt'] as String),
        closedAt: _dt(j['closedAt']),
        openingCash: _i(j['openingCash']),
        cashier: (j['cashier'] as String?) ?? '—',
        staffId: j['staffId'] as String?,
        movements: ((j['movements'] as List?) ?? const [])
            .map((e) => CashMovement.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        countedCash: (j['countedCash'] as num?)?.toInt(),
        expectedCash: (j['expectedCash'] as num?)?.toInt(),
        salesTotal: _i(j['salesTotal']),
        orderCount: _i(j['orderCount']),
        refundTotal: _i(j['refundTotal']),
        byMethod: ((j['byMethod'] as Map?) ?? const {}).map((k, v) => MapEntry(k as String, _i(v))),
        closedBy: (j['closedBy'] as String?) ?? '',
        note: (j['note'] as String?) ?? '',
        zNumber: _i(j['zNumber']),
      );
}

// ───────────────────────────── Purchasing ─────────────────────────────

class Supplier {
  final String id;
  String name;
  String category;
  String phone;
  String contact;
  String note;
  String lastOrder; // display text of the last PO date

  Supplier({
    required this.id,
    required this.name,
    this.category = '',
    this.phone = '',
    this.contact = '',
    this.note = '',
    this.lastOrder = '—',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'phone': phone,
        'contact': contact,
        'note': note,
        'lastOrder': lastOrder,
      };

  factory Supplier.fromJson(Map<String, dynamic> j) => Supplier(
        id: j['id'] as String,
        name: j['name'] as String,
        category: (j['category'] as String?) ?? '',
        phone: (j['phone'] as String?) ?? '',
        contact: (j['contact'] as String?) ?? '',
        note: (j['note'] as String?) ?? '',
        lastOrder: (j['lastOrder'] as String?) ?? '—',
      );
}

enum PoStatus { draft, ordered, received, cancelled }

extension PoStatusX on PoStatus {
  String get label => switch (this) {
        PoStatus.draft => 'ร่าง',
        PoStatus.ordered => 'สั่งแล้ว',
        PoStatus.received => 'รับของแล้ว',
        PoStatus.cancelled => 'ยกเลิก',
      };
}

class PoLine {
  final String code;
  final String name;
  int qty;
  int unitCost;
  PoLine({required this.code, required this.name, required this.qty, required this.unitCost});
  int get total => qty * unitCost;

  Map<String, dynamic> toJson() => {'code': code, 'name': name, 'qty': qty, 'unitCost': unitCost};
  factory PoLine.fromJson(Map<String, dynamic> j) =>
      PoLine(code: j['code'] as String, name: j['name'] as String, qty: _i(j['qty']), unitCost: _i(j['unitCost']));
}

class PurchaseOrder {
  final String id; // PO-0001
  final String supplierId;
  final String supplierName;
  final DateTime createdAt;
  final List<PoLine> lines;
  PoStatus status;
  DateTime? receivedAt;
  String note;
  final String createdBy;

  PurchaseOrder({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.createdAt,
    required this.lines,
    this.status = PoStatus.draft,
    this.receivedAt,
    this.note = '',
    this.createdBy = '',
  });

  int get total => lines.fold(0, (s, l) => s + l.total);
  int get itemCount => lines.fold(0, (s, l) => s + l.qty);

  Map<String, dynamic> toJson() => {
        'id': id,
        'supplierId': supplierId,
        'supplierName': supplierName,
        'createdAt': createdAt.toIso8601String(),
        'lines': lines.map((l) => l.toJson()).toList(),
        'status': status.name,
        'receivedAt': receivedAt?.toIso8601String(),
        'note': note,
        'createdBy': createdBy,
      };

  factory PurchaseOrder.fromJson(Map<String, dynamic> j) => PurchaseOrder(
        id: j['id'] as String,
        supplierId: j['supplierId'] as String,
        supplierName: (j['supplierName'] as String?) ?? '',
        createdAt: DateTime.parse(j['createdAt'] as String),
        lines: ((j['lines'] as List?) ?? const []).map((e) => PoLine.fromJson((e as Map).cast<String, dynamic>())).toList(),
        status: PoStatus.values.firstWhere((s) => s.name == j['status'], orElse: () => PoStatus.draft),
        receivedAt: _dt(j['receivedAt']),
        note: (j['note'] as String?) ?? '',
        createdBy: (j['createdBy'] as String?) ?? '',
      );
}

// ───────────────────────────── Stock ─────────────────────────────

enum StockMoveType { sale, refund, receive, adjust, waste, count }

extension StockMoveTypeX on StockMoveType {
  String get label => switch (this) {
        StockMoveType.sale => 'ขาย',
        StockMoveType.refund => 'คืนสินค้า',
        StockMoveType.receive => 'รับเข้า',
        StockMoveType.adjust => 'ปรับยอด',
        StockMoveType.waste => 'ของเสีย',
        StockMoveType.count => 'ตรวจนับ',
      };
}

class StockMovement {
  final DateTime at;
  final String code;
  final String name;
  final int delta;
  final int balance; // stock after this movement
  final StockMoveType type;
  final String reason;
  final String by;
  final String ref; // order / PO id

  const StockMovement({
    required this.at,
    required this.code,
    required this.name,
    required this.delta,
    required this.balance,
    required this.type,
    this.reason = '',
    this.by = '',
    this.ref = '',
  });

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'code': code,
        'name': name,
        'delta': delta,
        'balance': balance,
        'type': type.name,
        'reason': reason,
        'by': by,
        'ref': ref,
      };

  factory StockMovement.fromJson(Map<String, dynamic> j) => StockMovement(
        at: DateTime.parse(j['at'] as String),
        code: j['code'] as String,
        name: (j['name'] as String?) ?? '',
        delta: _i(j['delta']),
        balance: _i(j['balance']),
        type: StockMoveType.values.firstWhere((t) => t.name == j['type'], orElse: () => StockMoveType.adjust),
        reason: (j['reason'] as String?) ?? '',
        by: (j['by'] as String?) ?? '',
        ref: (j['ref'] as String?) ?? '',
      );
}

// ───────────────────────────── Discounts ─────────────────────────────

enum DiscountKind { amount, percent }

/// A coupon code definition.
class CouponDef {
  final String code; // upper-case
  String name;
  DiscountKind kind;
  int value; // baht or percent
  int minSpend;
  int maxDiscount; // cap for percent coupons (0 = none)
  bool active;
  DateTime? startsAt;
  DateTime? endsAt;
  int usageLimit; // 0 = unlimited
  int usedCount;

  CouponDef({
    required this.code,
    required this.name,
    this.kind = DiscountKind.amount,
    required this.value,
    this.minSpend = 0,
    this.maxDiscount = 0,
    this.active = true,
    this.startsAt,
    this.endsAt,
    this.usageLimit = 0,
    this.usedCount = 0,
  });

  /// Why this coupon can't apply right now ('' = OK).
  String blockReason(int subtotal, DateTime now) {
    if (!active) return 'คูปองถูกปิดใช้งาน';
    if (startsAt != null && now.isBefore(startsAt!)) return 'คูปองยังไม่เริ่มใช้';
    if (endsAt != null && now.isAfter(endsAt!)) return 'คูปองหมดอายุแล้ว';
    if (usageLimit > 0 && usedCount >= usageLimit) return 'คูปองถูกใช้ครบจำนวนแล้ว';
    if (subtotal < minSpend) return 'ยอดขั้นต่ำ ฿$minSpend';
    return '';
  }

  int discountFor(int subtotal) {
    final raw = kind == DiscountKind.amount ? value : (subtotal * value / 100).floor();
    final capped = (kind == DiscountKind.percent && maxDiscount > 0) ? (raw > maxDiscount ? maxDiscount : raw) : raw;
    return capped.clamp(0, subtotal);
  }

  String get summary => kind == DiscountKind.amount ? 'ลด ฿$value' : 'ลด $value%';

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'kind': kind.name,
        'value': value,
        'minSpend': minSpend,
        'maxDiscount': maxDiscount,
        'active': active,
        'startsAt': startsAt?.toIso8601String(),
        'endsAt': endsAt?.toIso8601String(),
        'usageLimit': usageLimit,
        'usedCount': usedCount,
      };

  factory CouponDef.fromJson(Map<String, dynamic> j) => CouponDef(
        code: j['code'] as String,
        name: (j['name'] as String?) ?? '',
        kind: DiscountKind.values.firstWhere((k) => k.name == j['kind'], orElse: () => DiscountKind.amount),
        value: _i(j['value']),
        minSpend: _i(j['minSpend']),
        maxDiscount: _i(j['maxDiscount']),
        active: (j['active'] as bool?) ?? true,
        startsAt: _dt(j['startsAt']),
        endsAt: _dt(j['endsAt']),
        usageLimit: _i(j['usageLimit']),
        usedCount: _i(j['usedCount']),
      );
}

enum PromoScope { all, category }

/// An automatic promotion rule (no code needed) — the best active one applies.
class Promotion {
  final String id;
  String name;
  DiscountKind kind;
  int value;
  int minSpend;
  PromoScope scope;
  String categoryId; // when scope == category
  int startHour; // happy hour window (0-24); start == end means all day
  int endHour;
  bool active;

  Promotion({
    required this.id,
    required this.name,
    this.kind = DiscountKind.percent,
    required this.value,
    this.minSpend = 0,
    this.scope = PromoScope.all,
    this.categoryId = '',
    this.startHour = 0,
    this.endHour = 0,
    this.active = true,
  });

  bool activeAt(DateTime now) {
    if (!active) return false;
    if (startHour == endHour) return true;
    final h = now.hour;
    return startHour < endHour ? (h >= startHour && h < endHour) : (h >= startHour || h < endHour);
  }

  String get summary {
    final v = kind == DiscountKind.amount ? '฿$value' : '$value%';
    final when = startHour == endHour ? '' : ' · ${startHour.toString().padLeft(2, '0')}:00–${endHour.toString().padLeft(2, '0')}:00';
    final min = minSpend > 0 ? ' · ขั้นต่ำ ฿$minSpend' : '';
    return 'ลด $v$min$when';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        'value': value,
        'minSpend': minSpend,
        'scope': scope.name,
        'categoryId': categoryId,
        'startHour': startHour,
        'endHour': endHour,
        'active': active,
      };

  factory Promotion.fromJson(Map<String, dynamic> j) => Promotion(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? '',
        kind: DiscountKind.values.firstWhere((k) => k.name == j['kind'], orElse: () => DiscountKind.percent),
        value: _i(j['value']),
        minSpend: _i(j['minSpend']),
        scope: PromoScope.values.firstWhere((s) => s.name == j['scope'], orElse: () => PromoScope.all),
        categoryId: (j['categoryId'] as String?) ?? '',
        startHour: _i(j['startHour']),
        endHour: _i(j['endHour']),
        active: (j['active'] as bool?) ?? true,
      );
}

// ───────────────────────────── Delivery / shipping ─────────────────────────────

enum DeliveryStatus { pending, picking, delivering, delivered, cancelled }

extension DeliveryStatusX on DeliveryStatus {
  String get label => switch (this) {
        DeliveryStatus.pending => 'รอไรเดอร์',
        DeliveryStatus.picking => 'ไรเดอร์รับของ',
        DeliveryStatus.delivering => 'กำลังจัดส่ง',
        DeliveryStatus.delivered => 'ส่งสำเร็จ',
        DeliveryStatus.cancelled => 'ยกเลิก',
      };
  DeliveryStatus get next => switch (this) {
        DeliveryStatus.pending => DeliveryStatus.picking,
        DeliveryStatus.picking => DeliveryStatus.delivering,
        DeliveryStatus.delivering => DeliveryStatus.delivered,
        _ => this,
      };
}

class DeliveryJob {
  final String id; // DL-0001
  final String orderId;
  final DateTime createdAt;
  String customerName;
  String phone;
  String address;
  String providerId;
  String trackingNo;
  String riderName;
  int fee;
  bool cod;
  int weightGrams;
  DeliveryStatus status;
  DateTime? deliveredAt;
  String note;

  DeliveryJob({
    required this.id,
    required this.orderId,
    required this.createdAt,
    this.customerName = '',
    this.phone = '',
    this.address = '',
    this.providerId = 'self',
    this.trackingNo = '',
    this.riderName = '',
    this.fee = 0,
    this.cod = false,
    this.weightGrams = 500,
    this.status = DeliveryStatus.pending,
    this.deliveredAt,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'createdAt': createdAt.toIso8601String(),
        'customerName': customerName,
        'phone': phone,
        'address': address,
        'providerId': providerId,
        'trackingNo': trackingNo,
        'riderName': riderName,
        'fee': fee,
        'cod': cod,
        'weightGrams': weightGrams,
        'status': status.name,
        'deliveredAt': deliveredAt?.toIso8601String(),
        'note': note,
      };

  factory DeliveryJob.fromJson(Map<String, dynamic> j) => DeliveryJob(
        id: j['id'] as String,
        orderId: j['orderId'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        customerName: (j['customerName'] as String?) ?? '',
        phone: (j['phone'] as String?) ?? '',
        address: (j['address'] as String?) ?? '',
        providerId: (j['providerId'] as String?) ?? 'self',
        trackingNo: (j['trackingNo'] as String?) ?? '',
        riderName: (j['riderName'] as String?) ?? '',
        fee: _i(j['fee']),
        cod: (j['cod'] as bool?) ?? false,
        weightGrams: _i(j['weightGrams'], 500),
        status: DeliveryStatus.values.firstWhere((s) => s.name == j['status'], orElse: () => DeliveryStatus.pending),
        deliveredAt: _dt(j['deliveredAt']),
        note: (j['note'] as String?) ?? '',
      );
}

/// A delivery / parcel provider the shop works with. There is no partner API
/// integration — jobs are tracked manually (tracking no. + status), so [mode]
/// is honest about that.
class ShippingProvider {
  final String id;
  String name;
  bool enabled;
  int baseFee;
  String accountId; // merchant / shop id at the provider
  String trackingUrl; // '{no}' placeholder → opens tracking page
  String kind; // 'food' | 'parcel' | 'self'

  ShippingProvider({
    required this.id,
    required this.name,
    this.enabled = false,
    this.baseFee = 0,
    this.accountId = '',
    this.trackingUrl = '',
    this.kind = 'parcel',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'enabled': enabled,
        'baseFee': baseFee,
        'accountId': accountId,
        'trackingUrl': trackingUrl,
        'kind': kind,
      };

  factory ShippingProvider.fromJson(Map<String, dynamic> j) => ShippingProvider(
        id: j['id'] as String,
        name: j['name'] as String,
        enabled: (j['enabled'] as bool?) ?? false,
        baseFee: _i(j['baseFee']),
        accountId: (j['accountId'] as String?) ?? '',
        trackingUrl: (j['trackingUrl'] as String?) ?? '',
        kind: (j['kind'] as String?) ?? 'parcel',
      );

  static List<ShippingProvider> defaults() => [
        ShippingProvider(id: 'self', name: 'ส่งเองโดยร้าน', enabled: true, baseFee: 0, kind: 'self'),
        ShippingProvider(id: 'grab', name: 'GrabFood', kind: 'food'),
        ShippingProvider(id: 'lineman', name: 'LINE MAN', kind: 'food'),
        ShippingProvider(id: 'lalamove', name: 'Lalamove', kind: 'food'),
        ShippingProvider(id: 'flash', name: 'Flash Express', trackingUrl: 'https://www.flashexpress.co.th/fle/tracking?se={no}'),
        ShippingProvider(id: 'thaipost', name: 'ไปรษณีย์ไทย', trackingUrl: 'https://track.thailandpost.co.th/?trackNumber={no}'),
        ShippingProvider(id: 'jt', name: 'J&T Express'),
        ShippingProvider(id: 'kerry', name: 'KEX Express'),
      ];
}

// ───────────────────────────── Branch / audit ─────────────────────────────

class Branch {
  final String id;
  String name;
  String area;
  String phone;
  bool isCurrent; // this device's branch
  // Legacy display fields (live numbers for the current branch come from orders)
  int todaySales;
  int orders;

  Branch({
    String? id,
    required this.name,
    this.area = '',
    this.phone = '',
    this.isCurrent = false,
    this.todaySales = 0,
    this.orders = 0,
  }) : id = id ?? 'BR-${fnv1a(name) % 100000}';

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'area': area, 'phone': phone, 'isCurrent': isCurrent};
  factory Branch.fromJson(Map<String, dynamic> j) => Branch(
        id: j['id'] as String,
        name: j['name'] as String,
        area: (j['area'] as String?) ?? '',
        phone: (j['phone'] as String?) ?? '',
        isCurrent: (j['isCurrent'] as bool?) ?? false,
      );
}

/// One line in the tamper-evident activity log (admin screen).
class AuditEntry {
  final DateTime at;
  final String actor;
  final String action; // short verb: 'login', 'refund', 'void', 'price', …
  final String detail;
  const AuditEntry({required this.at, required this.actor, required this.action, this.detail = ''});

  Map<String, dynamic> toJson() => {'at': at.toIso8601String(), 'actor': actor, 'action': action, 'detail': detail};
  factory AuditEntry.fromJson(Map<String, dynamic> j) => AuditEntry(
        at: DateTime.parse(j['at'] as String),
        actor: (j['actor'] as String?) ?? '',
        action: (j['action'] as String?) ?? '',
        detail: (j['detail'] as String?) ?? '',
      );
}
