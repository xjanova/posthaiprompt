// Thaiprompt POS — Application store (the single reactive brain).
//
// A zero-dependency ChangeNotifier wired into the tree via AppScope. Owns the
// catalog, the live cart, kitchen tickets, recorded orders, staff + PIN
// session, the cash shift, every back-office domain (CRM, tiers, coupons,
// promotions, tables, suppliers/POs, stock ledger, deliveries, branches) and
// the derived totals the screens render. Every mutation persists (debounced,
// atomic) through LocalStore, so the POS works fully offline; paid orders are
// also queued for the live terminal API by SyncService.
//
// by xman studio

import 'dart:convert' show jsonEncode;

import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../core/api/api_config.dart';
import '../core/auth/auth_repository.dart';
import '../core/security/pin.dart';
import '../core/sync/sync_service.dart';
import '../data/catalog_seed.dart';
import '../data/local_store.dart';
import '../models/catalog_models.dart';
import '../models/extra_models.dart';
import '../models/order_models.dart';

/// One card on the kitchen display — either a paid counter order or an unpaid
/// table / self-order ticket.
class KitchenEntry {
  final String id;
  final String label; // 'โต๊ะ 7' · 'กลับบ้าน' · 'A1042'
  final DateTime createdAt;
  final List<OrderLine> lines;
  final PrepStatus prep;
  final OrderSource source;
  final String note;
  final Order? order;
  final Ticket? ticket;

  const KitchenEntry({
    required this.id,
    required this.label,
    required this.createdAt,
    required this.lines,
    required this.prep,
    required this.source,
    this.note = '',
    this.order,
    this.ticket,
  });

  bool get isTicket => ticket != null;
  int get itemCount => lines.fold(0, (s, l) => s + l.qty);
}

/// A parked cart ("พักบิล") that can be resumed later.
class HeldCart {
  final String id;
  final String label;
  final DateTime createdAt;
  final List<Map<String, dynamic>> lines; // CartLine.toJson
  final int? tableNumber;
  final OrderType type;
  final String? customerId;
  final int total;

  HeldCart({
    required this.id,
    required this.label,
    required this.createdAt,
    required this.lines,
    this.tableNumber,
    this.type = OrderType.dineIn,
    this.customerId,
    this.total = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'createdAt': createdAt.toIso8601String(),
        'lines': lines,
        'tableNumber': tableNumber,
        'type': type.name,
        'customerId': customerId,
        'total': total,
      };

  factory HeldCart.fromJson(Map<String, dynamic> j) => HeldCart(
        id: j['id'] as String,
        label: (j['label'] as String?) ?? '',
        createdAt: DateTime.parse(j['createdAt'] as String),
        lines: ((j['lines'] as List?) ?? const []).map((e) => (e as Map).cast<String, dynamic>()).toList(),
        tableNumber: (j['tableNumber'] as num?)?.toInt(),
        type: OrderType.values.firstWhere((t) => t.name == j['type'], orElse: () => OrderType.dineIn),
        customerId: j['customerId'] as String?,
        total: (j['total'] as num?)?.toInt() ?? 0,
      );
}

class PosStore extends ChangeNotifier {
  final LocalStore _disk;
  final DateTime Function() _clock;
  PosStore({LocalStore? disk, DateTime Function()? clock})
      : _disk = disk ?? LocalStore(),
        _clock = clock ?? DateTime.now;

  static const maxPinAttempts = 5;
  static const pinLockDuration = Duration(minutes: 2);

  // ── Catalog ──
  final List<Category> categories = List.of(kSeedCategories);
  final List<Product> products = seedProducts();

  // ── Back-office domains ──
  final List<Customer> customers = seedCustomers();
  final List<Staff> staff = seedStaff();
  final List<TableInfo> tables = seedTables();
  final List<Supplier> suppliers = seedSuppliers();
  final List<Branch> branches = seedBranches();
  final List<MembershipTier> tiers = MembershipTier.defaults();
  final List<CouponDef> couponDefs = [];
  final List<Promotion> promotions = [];
  final List<PurchaseOrder> purchaseOrders = [];
  final List<StockMovement> stockMoves = [];
  final List<Ticket> tickets = [];
  final List<DeliveryJob> deliveries = [];
  final List<ShippingProvider> shippingProviders = ShippingProvider.defaults();
  final List<AuditEntry> auditLog = [];
  final List<HeldCart> heldCarts = [];
  Shift? currentShift;
  final List<Shift> shiftHistory = [];

  // ── Session ──
  Staff? currentStaff;

  // ── Cart (live order being built at the counter) ──
  final List<CartLine> cart = [];
  String? _couponCode;
  OrderType orderType = OrderType.dineIn;
  int? tableNumber;
  int guests = 1;
  String? customerName;
  String? customerId;
  final List<String> activeTicketIds = []; // tickets being settled by this cart

  // ── Self-order kiosk cart (customer tablet — never mixes with the counter) ──
  final List<CartLine> selfCart = [];
  int? selfTable;
  String? lastSelfTicketId;

  // ── Filters ──
  String? activeCategoryId; // null = all
  String searchQuery = '';

  // ── History ──
  final List<Order> orders = [];
  int _orderSeq = 1001;
  int _ticketSeq = 1;
  int _poSeq = 1;
  int _taxSeq = 1;
  int _zSeq = 1;
  int _deliverySeq = 1;

  // ── Settings ──
  String shopName = 'ร้านของฉัน';
  String branch = 'สาขาหลัก';
  String cashier = '—';
  String shopPhone = '';
  String shopAddress = '';
  String taxId = '';
  String promptPayId = '';
  String receiptFooter = 'ขอบคุณที่อุดหนุน · แล้วพบกันใหม่';
  double vatRate = 0.07;
  bool vatEnabled = true;
  bool vatInclusive = false; // prices already include VAT
  bool kitchenEnabled = true;
  bool requireShift = true;
  bool autoPrintReceipt = false;
  String printerName = ''; // '' = ask every time (system dialog)
  int paperWidthMm = 80; // 58 | 80
  bool soundEnabled = true;

  // ── Receipt printer hardware (ESC/POS) ──
  /// 'system' (OS print dialog / driver, PDF) · 'windows' (raw ESC/POS to a
  /// Windows printer queue — USB thermal printers) · 'network' (LAN, TCP 9100)
  /// · 'bluetooth' (SPP; includes Sunmi built-in "InnerPrinter").
  String printerMode = 'system';
  String printerAddress = ''; // network: host[:port] · bluetooth: MAC
  String printerDeviceName = ''; // human label (bluetooth device / windows queue)
  bool printerAutoCut = true;
  bool drawerOnCash = true; // kick the cash drawer after cash sales

  // ── Customer-facing second screen ──
  bool secondScreenEnabled = false;
  String secondScreenId = ''; // platform display id ('' = first non-primary)

  // ── App updates ──
  bool autoUpdate = true; // install new versions by itself when the POS is idle

  // ── Server / sync (main.thaiprompt.online · POS terminal API) ──
  String serverBaseUrl = ApiConfig.defaultBaseUrl;
  String branchId = 'BR-01';
  String terminalId = 'POS-01';
  String productKey = '';
  String deviceId = '';

  /// Wired in main() after construction. Null in tests / pure-offline boot.
  SyncService? sync;
  AuthRepository? auth;

  bool _ready = false;
  bool get isReady => _ready;

  /// True when the main snapshot was corrupt and we restored from backup.
  bool restoredFromBackup = false;

  DateTime _now() => _clock();

  // ─────────────────────────── lifecycle ───────────────────────────

  Future<void> init() async {
    final snap = await _disk.load();
    restoredFromBackup = _disk.lastLoadSource == LoadSource.backup;
    if (snap != null) _restore(snap);
    _ready = true;
    notifyListeners();
  }

  List<T> _list<T>(Object? raw, T Function(Map<String, dynamic>) f) =>
      ((raw as List?) ?? const []).map((e) => f((e as Map).cast<String, dynamic>())).toList();

  void _replace<T>(List<T> target, Object? raw, T Function(Map<String, dynamic>) f) {
    if (raw == null) return;
    target
      ..clear()
      ..addAll(_list(raw, f));
  }

  void _restore(Map<String, dynamic> snap) {
    _orderSeq = (snap['orderSeq'] as num?)?.toInt() ?? _orderSeq;
    _ticketSeq = (snap['ticketSeq'] as num?)?.toInt() ?? _ticketSeq;
    _poSeq = (snap['poSeq'] as num?)?.toInt() ?? _poSeq;
    _taxSeq = (snap['taxSeq'] as num?)?.toInt() ?? _taxSeq;
    _zSeq = (snap['zSeq'] as num?)?.toInt() ?? _zSeq;
    _deliverySeq = (snap['deliverySeq'] as num?)?.toInt() ?? _deliverySeq;

    _replace(categories, snap['categories'], Category.fromJson);
    _replace(products, snap['products'], Product.fromJson);
    // v1 snapshots kept only a stock map on top of the (now empty) seed.
    final stock = (snap['stock'] as Map?)?.cast<String, dynamic>();
    if (stock != null && snap['products'] == null) {
      for (final p in products) {
        final s = stock[p.code];
        if (s is int) p.stock = s;
      }
    }

    _replace(orders, snap['orders'], Order.fromJson);
    _replace(customers, snap['customers'], Customer.fromJson);
    _replace(staff, snap['staff'], Staff.fromJson);
    _replace(tables, snap['tables'], TableInfo.fromJson);
    _replace(suppliers, snap['suppliers'], Supplier.fromJson);
    _replace(branches, snap['branches'], Branch.fromJson);
    _replace(tiers, snap['tiers'], MembershipTier.fromJson);
    _replace(couponDefs, snap['coupons'], CouponDef.fromJson);
    _replace(promotions, snap['promotions'], Promotion.fromJson);
    _replace(purchaseOrders, snap['purchaseOrders'], PurchaseOrder.fromJson);
    _replace(stockMoves, snap['stockMoves'], StockMovement.fromJson);
    _replace(tickets, snap['tickets'], Ticket.fromJson);
    _replace(deliveries, snap['deliveries'], DeliveryJob.fromJson);
    _replace(shippingProviders, snap['shippingProviders'], ShippingProvider.fromJson);
    _replace(auditLog, snap['auditLog'], AuditEntry.fromJson);
    _replace(heldCarts, snap['heldCarts'], HeldCart.fromJson);
    _replace(shiftHistory, snap['shiftHistory'], Shift.fromJson);
    final shiftJson = snap['currentShift'] as Map?;
    currentShift = shiftJson != null ? Shift.fromJson(shiftJson.cast<String, dynamic>()) : null;

    final s = (snap['settings'] as Map?)?.cast<String, dynamic>();
    if (s != null) {
      shopName = (s['shopName'] as String?) ?? shopName;
      branch = (s['branch'] as String?) ?? branch;
      cashier = (s['cashier'] as String?) ?? cashier;
      shopPhone = (s['shopPhone'] as String?) ?? shopPhone;
      shopAddress = (s['shopAddress'] as String?) ?? shopAddress;
      taxId = (s['taxId'] as String?) ?? taxId;
      promptPayId = (s['promptPayId'] as String?) ?? promptPayId;
      receiptFooter = (s['receiptFooter'] as String?) ?? receiptFooter;
      vatRate = (s['vatRate'] as num?)?.toDouble() ?? vatRate;
      vatEnabled = (s['vatEnabled'] as bool?) ?? vatEnabled;
      vatInclusive = (s['vatInclusive'] as bool?) ?? vatInclusive;
      kitchenEnabled = (s['kitchenEnabled'] as bool?) ?? kitchenEnabled;
      requireShift = (s['requireShift'] as bool?) ?? requireShift;
      autoPrintReceipt = (s['autoPrintReceipt'] as bool?) ?? autoPrintReceipt;
      printerName = (s['printerName'] as String?) ?? printerName;
      paperWidthMm = (s['paperWidthMm'] as num?)?.toInt() ?? paperWidthMm;
      soundEnabled = (s['soundEnabled'] as bool?) ?? soundEnabled;
      printerMode = (s['printerMode'] as String?) ?? printerMode;
      printerAddress = (s['printerAddress'] as String?) ?? printerAddress;
      printerDeviceName = (s['printerDeviceName'] as String?) ?? printerDeviceName;
      printerAutoCut = (s['printerAutoCut'] as bool?) ?? printerAutoCut;
      drawerOnCash = (s['drawerOnCash'] as bool?) ?? drawerOnCash;
      secondScreenEnabled = (s['secondScreenEnabled'] as bool?) ?? secondScreenEnabled;
      secondScreenId = (s['secondScreenId'] as String?) ?? secondScreenId;
      autoUpdate = (s['autoUpdate'] as bool?) ?? autoUpdate;
      serverBaseUrl = (s['serverBaseUrl'] as String?) ?? serverBaseUrl;
      branchId = (s['branchId'] as String?) ?? branchId;
      terminalId = (s['terminalId'] as String?) ?? terminalId;
      productKey = (s['productKey'] as String?) ?? productKey;
      deviceId = (s['deviceId'] as String?) ?? deviceId;
    }
  }

  Map<String, dynamic> _snapshot() => {
        'v': LocalStore.schemaVersion,
        'orderSeq': _orderSeq,
        'ticketSeq': _ticketSeq,
        'poSeq': _poSeq,
        'taxSeq': _taxSeq,
        'zSeq': _zSeq,
        'deliverySeq': _deliverySeq,
        'categories': categories.map((c) => c.toJson()).toList(),
        'products': products.map((p) => p.toJson()).toList(),
        'orders': orders.map((o) => o.toJson()).toList(),
        'customers': customers.map((c) => c.toJson()).toList(),
        'staff': staff.map((s) => s.toJson()).toList(),
        'tables': tables.map((t) => t.toJson()).toList(),
        'suppliers': suppliers.map((s) => s.toJson()).toList(),
        'branches': branches.map((b) => b.toJson()).toList(),
        'tiers': tiers.map((t) => t.toJson()).toList(),
        'coupons': couponDefs.map((c) => c.toJson()).toList(),
        'promotions': promotions.map((p) => p.toJson()).toList(),
        'purchaseOrders': purchaseOrders.map((p) => p.toJson()).toList(),
        'stockMoves': stockMoves.map((m) => m.toJson()).toList(),
        'tickets': tickets.map((t) => t.toJson()).toList(),
        'deliveries': deliveries.map((d) => d.toJson()).toList(),
        'shippingProviders': shippingProviders.map((p) => p.toJson()).toList(),
        'auditLog': auditLog.map((a) => a.toJson()).toList(),
        'heldCarts': heldCarts.map((h) => h.toJson()).toList(),
        'currentShift': currentShift?.toJson(),
        'shiftHistory': shiftHistory.map((s) => s.toJson()).toList(),
        'settings': {
          'shopName': shopName,
          'branch': branch,
          'cashier': cashier,
          'shopPhone': shopPhone,
          'shopAddress': shopAddress,
          'taxId': taxId,
          'promptPayId': promptPayId,
          'receiptFooter': receiptFooter,
          'vatRate': vatRate,
          'vatEnabled': vatEnabled,
          'vatInclusive': vatInclusive,
          'kitchenEnabled': kitchenEnabled,
          'requireShift': requireShift,
          'autoPrintReceipt': autoPrintReceipt,
          'printerName': printerName,
          'paperWidthMm': paperWidthMm,
          'soundEnabled': soundEnabled,
          'printerMode': printerMode,
          'printerAddress': printerAddress,
          'printerDeviceName': printerDeviceName,
          'printerAutoCut': printerAutoCut,
          'drawerOnCash': drawerOnCash,
          'secondScreenEnabled': secondScreenEnabled,
          'secondScreenId': secondScreenId,
          'autoUpdate': autoUpdate,
          'serverBaseUrl': serverBaseUrl,
          'branchId': branchId,
          'terminalId': terminalId,
          'productKey': productKey,
          'deviceId': deviceId,
        },
      };

  void _persist() => _disk.saveDebounced(_snapshot);

  /// Flush any pending debounced write right now (e.g. before app exit).
  Future<void> flush() => _disk.save(_snapshot());

  void _changed() {
    notifyListeners();
    _persist();
  }

  String _id(String prefix) => '$prefix-${_now().microsecondsSinceEpoch.toRadixString(36)}';

  // ─────────────────────────── audit ───────────────────────────

  String get actorName => currentStaff?.name ?? cashier;

  void log(String action, [String detail = '']) {
    auditLog.insert(0, AuditEntry(at: _now(), actor: actorName, action: action, detail: detail));
    if (auditLog.length > 1500) auditLog.removeRange(1500, auditLog.length);
  }

  // ─────────────────────────── staff & session ───────────────────────────

  bool get hasStaff => staff.any((s) => s.active);
  bool get needsSetup => !hasStaff;
  bool get isSignedIn => currentStaff != null;
  bool get isManager => currentStaff?.role.isManager ?? false;
  List<Staff> get activeStaff => staff.where((s) => s.active).toList();

  Staff? staffById(String id) {
    for (final s in staff) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// First run: create the owner account (and optionally name the shop).
  Staff setupOwner({required String name, required String pin, String? shop, String? branchName}) {
    if (shop != null && shop.trim().isNotEmpty) shopName = shop.trim();
    if (branchName != null && branchName.trim().isNotEmpty) branch = branchName.trim();
    final owner = addStaff(name: name, role: StaffRole.owner, pin: pin, silent: true);
    if (branches.isEmpty) {
      branches.add(Branch(name: branch, isCurrent: true, phone: shopPhone));
    }
    log('setup', 'สร้างบัญชีเจ้าของร้าน ${owner.name}');
    _changed();
    return owner;
  }

  Staff addStaff({
    required String name,
    required StaffRole role,
    required String pin,
    String phone = '',
    bool silent = false,
  }) {
    final salt = PinHasher.newSalt();
    final s = Staff(
      id: _id('ST'),
      name: name.trim(),
      role: role,
      phone: phone.trim(),
      pinSalt: salt,
      pinHash: PinHasher.hash(pin, salt),
    );
    staff.add(s);
    if (!silent) {
      log('staff.add', '${s.name} (${role.label})');
      _changed();
    }
    return s;
  }

  void updateStaff(Staff s, {String? name, StaffRole? role, String? phone, bool? active}) {
    if (role != null && s.role == StaffRole.owner && role != StaffRole.owner && _ownerCount() <= 1) {
      throw StateError('ต้องมีเจ้าของร้านอย่างน้อย 1 คน');
    }
    if (active == false && s.role == StaffRole.owner && _ownerCount() <= 1) {
      throw StateError('ปิดบัญชีเจ้าของร้านคนสุดท้ายไม่ได้');
    }
    if (name != null) s.name = name.trim();
    if (role != null) s.role = role;
    if (phone != null) s.phone = phone.trim();
    if (active != null) s.active = active;
    log('staff.edit', s.name);
    _changed();
  }

  void setStaffPin(Staff s, String pin) {
    s.pinSalt = PinHasher.newSalt();
    s.pinHash = PinHasher.hash(pin, s.pinSalt);
    s.failedAttempts = 0;
    s.lockedUntil = null;
    log('staff.pin', 'เปลี่ยน PIN ของ ${s.name}');
    _changed();
  }

  void removeStaff(Staff s) {
    if (s.role == StaffRole.owner && _ownerCount() <= 1) {
      throw StateError('ลบเจ้าของร้านคนสุดท้ายไม่ได้');
    }
    if (currentStaff?.id == s.id) throw StateError('ลบบัญชีที่กำลังใช้งานอยู่ไม่ได้');
    staff.remove(s);
    log('staff.remove', s.name);
    _changed();
  }

  int _ownerCount() => staff.where((s) => s.active && s.role == StaffRole.owner).length;

  /// True when another staff member already uses this PIN (PINs identify the
  /// approver for manager overrides, so they must be unique).
  bool pinInUse(String pin, {Staff? except}) =>
      staff.any((s) => s.id != except?.id && s.hasPin && PinHasher.verify(pin, s.pinSalt, s.pinHash));

  LoginResult login(String staffId, String pin) {
    final s = staffById(staffId);
    if (s == null || !s.active) return const LoginWrongPin(0);
    final now = _now();
    if (s.lockedUntil != null && now.isBefore(s.lockedUntil!)) return LoginLocked(s.lockedUntil!);
    if (PinHasher.verify(pin, s.pinSalt, s.pinHash)) {
      s.failedAttempts = 0;
      s.lockedUntil = null;
      currentStaff = s;
      cashier = s.name;
      if (!s.online) {
        s.online = true;
        s.clockedInAt = now;
      }
      log('login', s.role.label);
      _changed();
      return LoginOk(s);
    }
    s.failedAttempts++;
    if (s.failedAttempts >= maxPinAttempts) {
      s.failedAttempts = 0;
      s.lockedUntil = now.add(pinLockDuration);
      log('login.locked', '${s.name} ใส่ PIN ผิด $maxPinAttempts ครั้ง');
      _changed();
      return LoginLocked(s.lockedUntil!);
    }
    _persist();
    notifyListeners();
    return LoginWrongPin(maxPinAttempts - s.failedAttempts);
  }

  int _mgrFails = 0;
  DateTime? _mgrLockedUntil;
  DateTime? get managerLockedUntil =>
      (_mgrLockedUntil != null && _now().isBefore(_mgrLockedUntil!)) ? _mgrLockedUntil : null;

  /// Manager override (refunds, drawer, voids). Returns the approving manager
  /// or null. Five wrong PINs lock overrides for [pinLockDuration].
  Staff? verifyManagerPin(String pin, {bool kiosk = false}) {
    if (kiosk ? kioskLockedUntil != null : managerLockedUntil != null) return null;
    for (final s in staff) {
      if (s.active && s.role.isManager && PinHasher.verify(pin, s.pinSalt, s.pinHash)) {
        if (kiosk) {
          _kioskFails = 0;
        } else {
          _mgrFails = 0;
        }
        return s;
      }
    }
    // Customer-facing exit keeps its own counter so a customer mashing the
    // kiosk keypad can't lock every manager override in the shop.
    if (kiosk) {
      _kioskFails++;
      if (_kioskFails >= maxPinAttempts) {
        _kioskFails = 0;
        _kioskLockedUntil = _now().add(pinLockDuration);
        log('kiosk.locked', 'ใส่ PIN ออกจากโหมดลูกค้าผิด $maxPinAttempts ครั้ง');
        _persist();
      }
      return null;
    }
    _mgrFails++;
    if (_mgrFails >= maxPinAttempts) {
      _mgrFails = 0;
      _mgrLockedUntil = _now().add(pinLockDuration);
      log('override.locked', 'ใส่ PIN ผู้จัดการผิด $maxPinAttempts ครั้ง');
      _persist();
    }
    return null;
  }

  int _kioskFails = 0;
  DateTime? _kioskLockedUntil;
  DateTime? get kioskLockedUntil =>
      (_kioskLockedUntil != null && _now().isBefore(_kioskLockedUntil!)) ? _kioskLockedUntil : null;

  void logout({bool clockOut = false}) {
    final s = currentStaff;
    if (s == null) return;
    if (clockOut) {
      s.online = false;
      s.clockedInAt = null;
    }
    log(clockOut ? 'logout.clockout' : 'logout');
    currentStaff = null;
    _changed();
  }

  void clockOut(Staff s) {
    s.online = false;
    s.clockedInAt = null;
    log('clockout', s.name);
    _changed();
  }

  int salesTodayFor(Staff s) =>
      ordersOn(_now()).where((o) => o.staffId == s.id).fold(0, (sum, o) => sum + o.netTotal);

  int ordersTodayFor(Staff s) => ordersOn(_now()).where((o) => o.staffId == s.id).length;

  // ─────────────────────────── catalog queries ───────────────────────────

  Category? categoryById(String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Product? productByCode(String code) {
    for (final p in products) {
      if (p.code == code) return p;
    }
    return null;
  }

  /// Exact barcode / SKU lookup (scanner input).
  Product? productByScan(String raw) {
    final q = raw.trim();
    if (q.isEmpty) return null;
    for (final p in products) {
      if (p.barcode == q || p.code == q) return p;
    }
    final lower = q.toLowerCase();
    for (final p in products) {
      if (p.code.toLowerCase() == lower) return p;
    }
    return null;
  }

  int productCountIn(String categoryId) => products.where((p) => p.categoryId == categoryId).length;

  List<Category> get sortedCategories => List.of(categories)..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  /// Products after the active category + search filters (sellable first).
  List<Product> get visibleProducts {
    final q = searchQuery.trim().toLowerCase();
    return products.where((p) {
      if (activeCategoryId != null && p.categoryId != activeCategoryId) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) || p.code.toLowerCase().contains(q) || p.barcode.contains(q);
    }).toList();
  }

  String get activeCategoryName =>
      activeCategoryId == null ? 'ทั้งหมด' : (categoryById(activeCategoryId!)?.name ?? 'ทั้งหมด');

  // ─────────────────────────── catalog edits ───────────────────────────

  String nextProductCode() {
    var n = products.length + 1;
    String code;
    do {
      code = 'P${n.toString().padLeft(4, '0')}';
      n++;
    } while (productByCode(code) != null);
    return code;
  }

  /// Create or replace a product (keyed by code). Price changes are audited.
  void upsertProduct(Product p) {
    final idx = products.indexWhere((x) => x.code == p.code);
    if (idx >= 0) {
      final old = products[idx];
      if (old.price != p.price) log('price', '${p.name} ${old.price} → ${p.price}');
      products[idx] = p;
      // Keep cart lines (counter + kiosk) pointing at the latest definition.
      for (final list in [cart, selfCart]) {
        for (var i = 0; i < list.length; i++) {
          final l = list[i];
          if (l.product.code == p.code) {
            list[i] = CartLine(product: p, qty: l.qty, note: l.note, options: l.options, optionDelta: l.optionDelta);
          }
        }
      }
    } else {
      products.add(p);
      log('product.add', p.name);
    }
    _changed();
  }

  void deleteProduct(Product p) {
    products.removeWhere((x) => x.code == p.code);
    cart.removeWhere((l) => l.product.code == p.code);
    selfCart.removeWhere((l) => l.product.code == p.code);
    log('product.remove', p.name);
    _changed();
  }

  void setProductAvailable(Product p, bool available) => upsertProduct(p.copyWith(available: available));

  Category addCategory(String name, {String iconKey = 'tag'}) {
    final c = Category(
      id: _id('CAT'),
      name: name.trim(),
      iconKey: iconKey,
      hue: stableHue(name),
      sortOrder: categories.length,
    );
    categories.add(c);
    log('category.add', c.name);
    _changed();
    return c;
  }

  void updateCategory(Category c, {String? name, String? iconKey}) {
    if (name != null) {
      c.name = name.trim();
      c.hue = stableHue(c.name);
    }
    if (iconKey != null) c.iconKey = iconKey;
    _changed();
  }

  /// Delete a category; its products become uncategorised ('').
  void deleteCategory(Category c) {
    categories.remove(c);
    for (var i = 0; i < products.length; i++) {
      if (products[i].categoryId == c.id) products[i] = products[i].copyWith(categoryId: '');
    }
    if (activeCategoryId == c.id) activeCategoryId = null;
    log('category.remove', c.name);
    _changed();
  }

  void moveCategory(Category c, int delta) {
    final list = sortedCategories;
    final i = list.indexOf(c);
    final j = (i + delta).clamp(0, list.length - 1);
    if (i < 0 || i == j) return;
    list.removeAt(i);
    list.insert(j, c);
    for (var k = 0; k < list.length; k++) {
      list[k].sortOrder = k;
    }
    _changed();
  }

  // ─────────────────────────── stock ledger ───────────────────────────

  void _move(Product p, int delta, StockMoveType type, {String reason = '', String ref = ''}) {
    if (!p.trackStock || delta == 0) return;
    p.stock = (p.stock + delta).clamp(0, 1 << 31);
    stockMoves.insert(
      0,
      StockMovement(
        at: _now(),
        code: p.code,
        name: p.name,
        delta: delta,
        balance: p.stock,
        type: type,
        reason: reason,
        by: actorName,
        ref: ref,
      ),
    );
    if (stockMoves.length > 3000) stockMoves.removeRange(3000, stockMoves.length);
  }

  /// Manual stock change (receive / waste / adjust) with a reason.
  void adjustStock(Product p, int delta, {StockMoveType type = StockMoveType.adjust, String reason = ''}) {
    _move(p, delta, type, reason: reason);
    log('stock', '${p.name} ${delta > 0 ? '+' : ''}$delta (${type.label}${reason.isEmpty ? '' : ' · $reason'})');
    _changed();
  }

  /// Back-compat helper used by older screens.
  void restock(Product p, int delta) =>
      adjustStock(p, delta, type: delta >= 0 ? StockMoveType.receive : StockMoveType.adjust);

  /// Physical count: set the on-hand quantity, logging the difference.
  void countStock(Product p, int counted, {String reason = 'ตรวจนับ'}) {
    final delta = counted - p.stock;
    if (delta == 0) return;
    adjustStock(p, delta, type: StockMoveType.count, reason: reason);
  }

  List<StockMovement> movesFor(String code) => stockMoves.where((m) => m.code == code).toList();
  List<Product> get lowStockProducts => products.where((p) => p.isLowStock).toList();

  // ─────────────────────────── discounts ───────────────────────────

  CouponDef? couponByCode(String code) {
    final c = code.trim().toUpperCase();
    for (final d in couponDefs) {
      if (d.code == c) return d;
    }
    return null;
  }

  /// Null on success, else a Thai reason why the code can't apply.
  String? tryApplyCoupon(String code) {
    final def = couponByCode(code);
    if (def == null) return 'ไม่พบคูปองนี้';
    final why = def.blockReason(cartSubtotal, _now());
    if (why.isNotEmpty) return why;
    _couponCode = def.code;
    notifyListeners();
    return null;
  }

  /// Back-compat: true if applied.
  bool applyCouponCode(String code) => tryApplyCoupon(code) == null;

  void removeCoupon() {
    _couponCode = null;
    notifyListeners();
  }

  String? get appliedCouponCode => _couponCode;

  int get couponDiscount {
    final code = _couponCode;
    if (code == null) return 0;
    final def = couponByCode(code);
    if (def == null || def.blockReason(cartSubtotal, _now()).isNotEmpty) return 0;
    return def.discountFor(cartSubtotal);
  }

  /// The applied coupon resolved against the current cart (null if none).
  Coupon? get coupon => _couponCode == null ? null : Coupon(_couponCode!, couponDiscount);

  /// The best automatic promotion for [lines] right now.
  ({Promotion promo, int amount})? _bestPromo(List<CartLine> lines) {
    final subtotal = lines.fold<int>(0, (s, l) => s + l.lineTotal);
    ({Promotion promo, int amount})? best;
    for (final p in promotions) {
      if (!p.activeAt(_now())) continue;
      final base = p.scope == PromoScope.category
          ? lines.where((l) => l.product.categoryId == p.categoryId).fold<int>(0, (s, l) => s + l.lineTotal)
          : subtotal;
      if (base <= 0 || subtotal < p.minSpend) continue;
      final amt = (p.kind == DiscountKind.amount ? p.value : (base * p.value / 100).floor()).clamp(0, base);
      if (best == null || amt > best.amount) best = (promo: p, amount: amt);
    }
    return best;
  }

  Promotion? get appliedPromotion => _bestPromo(cart)?.promo;
  int get promoDiscount => _bestPromo(cart)?.amount ?? 0;

  Customer? get linkedCustomer => customerId == null ? null : customerById(customerId!);

  int get memberDiscount {
    final c = linkedCustomer;
    if (c == null) return 0;
    final pct = tierFor(c).discountPercent;
    if (pct <= 0) return 0;
    final base = (cartSubtotal - couponDiscount - promoDiscount).clamp(0, cartSubtotal);
    return (base * pct / 100).floor();
  }

  String get discountNote {
    final parts = <String>[];
    if (couponDiscount > 0) parts.add('คูปอง ${_couponCode!}');
    final promo = appliedPromotion;
    if (promo != null && promoDiscount > 0) parts.add(promo.name);
    final c = linkedCustomer;
    if (c != null && memberDiscount > 0) parts.add('สมาชิก ${tierFor(c).name} -${tierFor(c).discountPercent}%');
    return parts.join(' · ');
  }

  // ─────────────────────────── cart totals ───────────────────────────

  int get cartItemCount => cart.fold(0, (s, l) => s + l.qty);
  int get cartSubtotal => cart.fold(0, (s, l) => s + l.lineTotal);

  int get cartDiscount => (couponDiscount + promoDiscount + memberDiscount).clamp(0, cartSubtotal);

  int get _taxable => cartSubtotal - cartDiscount;

  int get cartTax {
    if (!vatEnabled) return 0;
    return vatInclusive ? (_taxable * vatRate / (1 + vatRate)).round() : (_taxable * vatRate).round();
  }

  int get cartTotal => vatInclusive ? _taxable : _taxable + cartTax;
  bool get cartIsEmpty => cart.isEmpty;

  /// Display id for the next order (e.g. `A1042`).
  String get openOrderId => 'A$_orderSeq';

  /// Why checkout is blocked right now ('' = can sell).
  String get checkoutBlockReason {
    if (cart.isEmpty) return 'ยังไม่มีรายการในตะกร้า';
    if (currentStaff == null) return 'กรุณาเข้าสู่ระบบก่อนขาย';
    if (!currentStaff!.role.canSell) return 'บทบาทนี้ไม่มีสิทธิ์รับชำระเงิน';
    if (requireShift && !hasOpenShift) return 'กรุณาเปิดกะก่อนรับชำระเงิน';
    return '';
  }

  // ─────────────────────────── cart actions ───────────────────────────

  /// Add [p] (with chosen options) to the counter cart. Returns false when the
  /// product is unavailable or out of stock.
  bool addProduct(Product p, {List<String> options = const [], int optionDelta = 0, String note = '', int qty = 1}) =>
      _addTo(cart, p, options: options, optionDelta: optionDelta, note: note, qty: qty);

  bool _addTo(List<CartLine> target, Product p,
      {List<String> options = const [], int optionDelta = 0, String note = '', int qty = 1}) {
    if (!p.canSell || qty <= 0) return false;
    final inCart = target.where((l) => l.product.code == p.code).fold<int>(0, (s, l) => s + l.qty);
    if (p.trackStock && inCart + qty > p.stock) return false;
    final n = note.trim();
    final existing = target.where((l) => l.sameAs(p, options, n));
    if (existing.isNotEmpty) {
      existing.first.qty += qty;
    } else {
      target.add(CartLine(product: p, qty: qty, note: n, options: List.of(options), optionDelta: optionDelta));
    }
    _changed();
    return true;
  }

  /// Scanner entry: add the product matching [raw]; null if not found/unsellable.
  Product? addByScan(String raw) {
    final p = productByScan(raw);
    if (p == null) return null;
    return addProduct(p) ? p : null;
  }

  void incLine(CartLine line) {
    final p = line.product;
    final inCart = cart.where((l) => l.product.code == p.code).fold<int>(0, (s, l) => s + l.qty);
    if (p.trackStock && inCart + 1 > p.stock) return;
    line.qty++;
    _changed();
  }

  void decLine(CartLine line) {
    line.qty--;
    if (line.qty <= 0) cart.remove(line);
    _changed();
  }

  void setLineQty(CartLine line, int qty) {
    if (qty <= 0) {
      cart.remove(line);
    } else {
      line.qty = line.product.trackStock ? qty.clamp(1, line.product.stock) : qty;
    }
    _changed();
  }

  void removeLine(CartLine line) {
    cart.remove(line);
    _changed();
  }

  void setLineNote(CartLine line, String note) {
    line.note = note.trim();
    _changed();
  }

  void clearCart() {
    // Abandoning a recalled table bill: the table goes back to "seated".
    for (final id in activeTicketIds) {
      final t = ticketById(id);
      final tb = t?.tableNumber == null ? null : tableByNumber(t!.tableNumber!);
      if (tb != null && tb.status == TableStatus.billing) tb.status = TableStatus.seated;
    }
    cart.clear();
    _couponCode = null;
    customerName = null;
    customerId = null;
    activeTicketIds.clear();
    _changed();
  }

  void setCategory(String? id) {
    activeCategoryId = id;
    notifyListeners();
  }

  void setSearch(String q) {
    searchQuery = q;
    notifyListeners();
  }

  void setOrderType(OrderType t) {
    orderType = t;
    if (t != OrderType.dineIn) tableNumber = null;
    notifyListeners();
  }

  void setTable(int? table) {
    tableNumber = table;
    if (table != null) orderType = OrderType.dineIn;
    notifyListeners();
  }

  void setGuests(int n) {
    guests = n < 1 ? 1 : n;
    notifyListeners();
  }

  /// Link a member to the cart by name (exact match links the customer record).
  void setCustomerName(String? name) {
    final n = (name == null || name.trim().isEmpty) ? null : name.trim();
    customerName = n;
    customerId = null;
    if (n != null) {
      for (final c in customers) {
        if (c.name == n) {
          customerId = c.id;
          break;
        }
      }
    }
    notifyListeners();
  }

  void linkCustomer(Customer? c) {
    customerId = c?.id;
    customerName = c?.name;
    notifyListeners();
  }

  // ── Held (parked) carts ──
  HeldCart? holdCart({String label = ''}) {
    if (cart.isEmpty) return null;
    final h = HeldCart(
      id: _id('H'),
      label: label.trim().isNotEmpty ? label.trim() : (tableNumber != null ? 'โต๊ะ $tableNumber' : 'บิลพัก ${heldCarts.length + 1}'),
      createdAt: _now(),
      lines: cart.map((l) => l.toJson()).toList(),
      tableNumber: tableNumber,
      type: orderType,
      customerId: customerId,
      total: cartTotal,
    );
    heldCarts.insert(0, h);
    cart.clear();
    _couponCode = null;
    customerId = null;
    customerName = null;
    activeTicketIds.clear();
    log('hold', h.label);
    _changed();
    return h;
  }

  /// Resume a parked cart. The current cart must be empty (or it is held first).
  void resumeHeld(HeldCart h) {
    if (cart.isNotEmpty) holdCart();
    cart.clear();
    for (final j in h.lines) {
      final p = productByCode(j['code'] as String);
      if (p == null) continue;
      cart.add(CartLine(
        product: p,
        qty: (j['qty'] as num).toInt(),
        note: (j['note'] as String?) ?? '',
        options: ((j['options'] as List?) ?? const []).map((e) => e.toString()).toList(),
        optionDelta: (j['optionDelta'] as num?)?.toInt() ?? 0,
      ));
    }
    tableNumber = h.tableNumber;
    orderType = h.type;
    final c = h.customerId == null ? null : customerById(h.customerId!);
    customerId = c?.id;
    customerName = c?.name;
    heldCarts.remove(h);
    _changed();
  }

  /// "แยกบิล": move [qtyByLine] (line → qty) out of the cart into a new parked
  /// cart, leaving the rest to be paid now. Returns the parked cart.
  HeldCart? splitToHeld(Map<CartLine, int> qtyByLine, {String label = ''}) {
    final moved = <Map<String, dynamic>>[];
    var total = 0;
    qtyByLine.forEach((line, q) {
      if (!cart.contains(line)) return;
      final n = q.clamp(0, line.qty);
      if (n <= 0) return;
      moved.add({'code': line.product.code, 'qty': n, 'note': line.note, 'options': line.options, 'optionDelta': line.optionDelta});
      total += n * line.unitPrice;
    });
    if (moved.isEmpty) return null;
    for (final e in qtyByLine.entries) {
      if (!cart.contains(e.key)) continue;
      final left = e.key.qty - e.value.clamp(0, e.key.qty);
      if (left <= 0) {
        cart.remove(e.key);
      } else {
        e.key.qty = left;
      }
    }
    final h = HeldCart(
      id: _id('H'),
      label: label.trim().isNotEmpty ? label.trim() : 'บิลแยก ${heldCarts.length + 1}',
      createdAt: _now(),
      lines: moved,
      tableNumber: tableNumber,
      type: orderType,
      total: total,
    );
    heldCarts.insert(0, h);
    log('split', '${h.label} ${moved.length} รายการ');
    _changed();
    return h;
  }

  void deleteHeld(HeldCart h) {
    heldCarts.remove(h);
    log('hold.delete', h.label);
    _changed();
  }

  // ─────────────────────────── checkout ───────────────────────────

  Order? _lastOrder;
  Order? get lastOrder => _lastOrder ?? (orders.isNotEmpty ? orders.first : null);

  Order? orderById(String id) {
    for (final o in orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  /// Record the cart as a paid [Order]: deduct stock (ledger), award loyalty,
  /// settle linked kitchen tickets, queue for the server, clear the cart.
  /// Returns null when blocked (see [checkoutBlockReason]) or cash is short.
  Order? checkout({required PaymentMethod method, int cashReceived = 0, String? paymentRef}) {
    if (checkoutBlockReason.isNotEmpty) return null;
    final total = cartTotal;
    if (method == PaymentMethod.cash && cashReceived > 0 && cashReceived < total) return null;
    final tendered = method == PaymentMethod.cash ? (cashReceived > 0 ? cashReceived : total) : 0;
    final now = _now();

    final settling = tickets.where((t) => activeTicketIds.contains(t.id) && t.isOpen).toList();
    final fromTicket = settling.isNotEmpty;
    final prep = fromTicket
        ? settling.map((t) => t.prep).reduce((a, b) => a.index < b.index ? a : b)
        : (kitchenEnabled ? PrepStatus.queued : PrepStatus.served);
    final source = fromTicket ? settling.first.source : OrderSource.counter;

    final order = Order(
      id: openOrderId,
      createdAt: now,
      lines: cart.map((l) => l.toOrderLine()).toList(),
      subtotal: cartSubtotal,
      discount: cartDiscount,
      tax: cartTax,
      total: total,
      method: method,
      type: orderType,
      tableNumber: orderType == OrderType.dineIn ? tableNumber : null,
      guests: guests,
      cashier: actorName,
      couponCode: couponDiscount > 0 ? _couponCode : null,
      customerName: customerName,
      customerId: customerId,
      staffId: currentStaff?.id,
      shiftId: currentShift?.id,
      paymentRef: (paymentRef == null || paymentRef.trim().isEmpty) ? null : paymentRef.trim(),
      cashReceived: tendered,
      change: method == PaymentMethod.cash ? tendered - total : 0,
      source: source,
      ticketId: fromTicket ? settling.map((t) => t.id).join(',') : null,
      discountNote: discountNote,
      prep: prep,
    );

    for (final line in cart) {
      _move(line.product, -line.qty, StockMoveType.sale, ref: order.id);
    }

    if (couponDiscount > 0) couponByCode(_couponCode!)?.usedCount++;

    final c = linkedCustomer;
    if (c != null) {
      c.spent += order.total;
      c.visits += 1;
      c.points += (order.total * tierFor(c).pointsPer100 / 100).floor();
    }

    for (final t in settling) {
      t.status = TicketStatus.settled;
      t.settledOrderId = order.id;
      t.callWaiter = false;
    }
    if (fromTicket && order.tableNumber != null && openTicketsForTable(order.tableNumber!).isEmpty) {
      final t = tableByNumber(order.tableNumber!);
      if (t != null) {
        t.status = TableStatus.free;
        t.guests = 0;
        t.seatedAt = null;
        t.callWaiter = false;
      }
    }

    orders.insert(0, order);
    _lastOrder = order;
    _orderSeq++;
    sync?.enqueueOrder(order.toJson());
    log('checkout', '${order.id} ${method.receiptLabel} ฿${order.total}');

    cart.clear();
    _couponCode = null;
    customerName = null;
    customerId = null;
    activeTicketIds.clear();
    _changed();
    return order;
  }

  /// Refund [order] — all of it, or only [qtyByCode] (code → qty). Restocks,
  /// reverses loyalty, keeps the bill with its refund amount. Returns baht refunded.
  int refundOrder(Order order, {Map<String, int>? qtyByCode, String reason = '', Staff? approvedBy}) {
    if (order.status != OrderStatus.paid) return 0;
    // Paid from the customer's Thai Prompt wallet: only Thai Prompt can refund
    // it (dispute in the app → admin), a POS refund would hand out cash.
    if (order.method == PaymentMethod.thaiprompt) return 0;
    final ratio = order.subtotal == 0 ? 1.0 : order.total / order.subtotal;
    var gross = 0;
    for (final l in order.lines) {
      final want = qtyByCode == null ? l.refundableQty : (qtyByCode[l.code] ?? 0).clamp(0, l.refundableQty);
      if (want <= 0) continue;
      l.refundedQty += want;
      gross += want * l.price;
      final p = productByCode(l.code);
      if (p != null) _move(p, want, StockMoveType.refund, reason: reason, ref: order.id);
    }
    if (gross == 0) return 0;
    final allBack = order.lines.every((l) => l.refundableQty == 0);
    var amount = (gross * ratio).round();
    if (allBack) amount = order.total - order.refundAmount; // no rounding drift on full refunds
    amount = amount.clamp(0, order.total - order.refundAmount);
    order.refundAmount += amount;
    order.refundReason = reason.trim().isEmpty ? order.refundReason : reason.trim();
    order.refundedAt = _now();
    order.refundedBy = approvedBy?.name ?? actorName;
    if (allBack) order.status = OrderStatus.refunded;

    final c = order.customerId == null ? null : customerById(order.customerId!);
    if (c != null) {
      c.spent = (c.spent - amount).clamp(0, 1 << 31);
      c.points = (c.points - (amount * tierFor(c).pointsPer100 / 100).floor()).clamp(0, 1 << 31);
    }
    log('refund', '${order.id} ฿$amount${reason.isEmpty ? '' : ' · $reason'}${approvedBy != null ? ' · อนุมัติโดย ${approvedBy.name}' : ''}');
    _changed();
    return amount;
  }

  void markPrinted(Order o) {
    o.printCount++;
    if (o.printCount > 1) log('reprint', o.id);
    _changed();
  }

  // ─────────────────────────── tickets (unpaid kitchen orders) ───────────────────────────

  Ticket? ticketById(String id) {
    for (final t in tickets) {
      if (t.id == id) return t;
    }
    return null;
  }

  List<Ticket> get openTickets => tickets.where((t) => t.isOpen).toList();
  List<Ticket> openTicketsForTable(int table) => tickets.where((t) => t.isOpen && t.tableNumber == table).toList();
  int tableBillTotal(int table) => openTicketsForTable(table).fold(0, (s, t) => s + t.total);

  Ticket _newTicket(List<CartLine> lines, OrderSource source,
      {int? table, int guests = 1, String? customer, String? customerId, String note = ''}) {
    final t = Ticket(
      id: 'T-${(_ticketSeq++).toString().padLeft(4, '0')}',
      createdAt: _now(),
      source: source,
      tableNumber: table,
      guests: guests,
      customerName: customer,
      customerId: customerId,
      staffName: source == OrderSource.self ? 'ลูกค้า' : actorName,
      lines: lines.map((l) => l.toOrderLine()).toList(),
      note: note,
      prep: kitchenEnabled ? PrepStatus.queued : PrepStatus.served,
    );
    tickets.insert(0, t);
    if (tickets.length > 800) tickets.removeWhere((x) => !x.isOpen && tickets.indexOf(x) > 600);
    if (table != null) {
      final tb = tableByNumber(table);
      if (tb != null && tb.status != TableStatus.billing) {
        tb.status = TableStatus.seated;
        tb.seatedAt ??= _now();
        if (guests > tb.guests) tb.guests = guests;
      }
    }
    return t;
  }

  /// Send the counter cart to the kitchen as an unpaid ticket (table service).
  Ticket? sendCartToKitchen({OrderSource source = OrderSource.table, String note = ''}) {
    if (cart.isEmpty) return null;
    final t = _newTicket(cart, source,
        table: orderType == OrderType.dineIn ? tableNumber : null,
        guests: guests,
        customer: customerName,
        customerId: customerId,
        note: note);
    log('ticket', '${t.id}${t.tableNumber != null ? ' โต๊ะ ${t.tableNumber}' : ''} ${t.itemCount} รายการ');
    cart.clear();
    _couponCode = null;
    customerId = null;
    customerName = null;
    activeTicketIds.clear();
    _changed();
    return t;
  }

  void _relinkFromTickets(List<Ticket> list) {
    for (final t in list) {
      final c = t.customerId == null ? null : customerById(t.customerId!);
      if (c != null) {
        customerId = c.id;
        customerName = c.name;
        return;
      }
    }
  }

  /// Load every open ticket of [table] into the counter cart for payment.
  bool loadTableToCart(int table) {
    final list = openTicketsForTable(table);
    if (list.isEmpty) return false;
    cart.clear();
    activeTicketIds
      ..clear()
      ..addAll(list.map((t) => t.id));
    for (final t in list.reversed) {
      for (final l in t.lines) {
        final p = productByCode(l.code) ??
            Product(id: l.code, code: l.code, name: l.name, price: l.price, categoryId: '', hue: l.hue, trackStock: false);
        final base = productByCode(l.code)?.price ?? l.price;
        cart.add(CartLine(product: p, qty: l.qty, note: l.note, options: List.of(l.options), optionDelta: l.price - base));
      }
    }
    tableNumber = table;
    orderType = OrderType.dineIn;
    guests = list.map((t) => t.guests).fold(1, (a, b) => a > b ? a : b);
    customerId = null;
    customerName = null;
    _relinkFromTickets(list);
    final tb = tableByNumber(table);
    if (tb != null) tb.status = TableStatus.billing;
    _changed();
    return true;
  }

  void loadTicketToCart(Ticket t) {
    if (t.tableNumber != null) {
      loadTableToCart(t.tableNumber!);
      return;
    }
    cart.clear();
    activeTicketIds
      ..clear()
      ..add(t.id);
    for (final l in t.lines) {
      final p = productByCode(l.code) ??
          Product(id: l.code, code: l.code, name: l.name, price: l.price, categoryId: '', hue: l.hue, trackStock: false);
      final base = productByCode(l.code)?.price ?? l.price;
      cart.add(CartLine(product: p, qty: l.qty, note: l.note, options: List.of(l.options), optionDelta: l.price - base));
    }
    orderType = OrderType.takeaway;
    customerId = null;
    customerName = null;
    _relinkFromTickets([t]);
    _changed();
  }

  void cancelTicket(Ticket t, {String reason = '', Staff? approvedBy}) {
    if (!t.isOpen) return;
    t.status = TicketStatus.cancelled;
    activeTicketIds.remove(t.id);
    if (t.tableNumber != null && openTicketsForTable(t.tableNumber!).isEmpty) {
      final tb = tableByNumber(t.tableNumber!);
      if (tb != null && tb.status != TableStatus.reserved) {
        tb.status = TableStatus.free;
        tb.guests = 0;
        tb.seatedAt = null;
        tb.callWaiter = false;
      }
    }
    log('ticket.cancel', '${t.id}${reason.isEmpty ? '' : ' · $reason'}${approvedBy != null ? ' · ${approvedBy.name}' : ''}');
    _changed();
  }

  /// Customer pressed / staff cleared "เรียกพนักงาน" for a table (works even
  /// before the table has any ticket).
  void setCallWaiter(int table, bool on) {
    final tb = tableByNumber(table);
    if (tb != null) tb.callWaiter = on;
    for (final t in openTicketsForTable(table)) {
      t.callWaiter = on;
    }
    if (on) log('call.waiter', 'โต๊ะ $table');
    _changed();
  }

  List<int> get tablesCallingWaiter => {
        ...tables.where((t) => t.callWaiter).map((t) => t.number),
        ...openTickets.where((t) => t.callWaiter && t.tableNumber != null).map((t) => t.tableNumber!),
      }.toList()
        ..sort();

  // ── Self-order kiosk ──
  int get selfCartTotal => selfCart.fold(0, (s, l) => s + l.lineTotal);
  int get selfCartCount => selfCart.fold(0, (s, l) => s + l.qty);

  bool addToSelfCart(Product p, {List<String> options = const [], int optionDelta = 0, String note = '', int qty = 1}) =>
      _addTo(selfCart, p, options: options, optionDelta: optionDelta, note: note, qty: qty);

  void selfInc(CartLine l) {
    final p = l.product;
    final inCart = selfCart.where((x) => x.product.code == p.code).fold<int>(0, (s, x) => s + x.qty);
    if (!p.canSell || (p.trackStock && inCart + 1 > p.stock)) return;
    l.qty++;
    _changed();
  }

  /// Kiosk lines that can no longer be sold (sold out / 86'd since added).
  List<CartLine> get selfCartProblems {
    final out = <CartLine>[];
    for (final l in selfCart) {
      final live = productByCode(l.product.code) ?? l.product;
      final inCart = selfCart.where((x) => x.product.code == live.code).fold<int>(0, (s, x) => s + x.qty);
      if (!live.available || (live.trackStock && inCart > live.stock)) out.add(l);
    }
    return out;
  }

  void selfDec(CartLine l) {
    l.qty--;
    if (l.qty <= 0) selfCart.remove(l);
    _changed();
  }

  void selfRemove(CartLine l) {
    selfCart.remove(l);
    _changed();
  }

  void setSelfTable(int? table) {
    selfTable = table;
    notifyListeners();
  }

  /// Customer confirms the kiosk cart → kitchen ticket (unpaid, pay at counter).
  Ticket? submitSelfOrder({String note = '', int guests = 1}) {
    if (selfCart.isEmpty || selfCartProblems.isNotEmpty) return null;
    final t = _newTicket(selfCart, OrderSource.self, table: selfTable, guests: guests, note: note);
    lastSelfTicketId = t.id;
    selfCart.clear();
    log('self.order', '${t.id}${t.tableNumber != null ? ' โต๊ะ ${t.tableNumber}' : ''}');
    _changed();
    return t;
  }

  Ticket? get lastSelfTicket => lastSelfTicketId == null ? null : ticketById(lastSelfTicketId!);

  // ─────────────────────────── kitchen ───────────────────────────

  /// Active kitchen queue (FIFO): unpaid tickets + paid counter orders not yet served.
  List<KitchenEntry> get kitchenQueue {
    final out = <KitchenEntry>[];
    for (final t in tickets) {
      if (!t.isOpen && t.status != TicketStatus.settled) continue;
      if (t.prep == PrepStatus.served) continue;
      if (t.status == TicketStatus.cancelled) continue;
      out.add(KitchenEntry(
        id: t.id,
        label: t.tableNumber != null ? 'โต๊ะ ${t.tableNumber}' : (t.customerName ?? t.source.label),
        createdAt: t.createdAt,
        lines: t.lines,
        prep: t.prep,
        source: t.source,
        note: t.note,
        ticket: t,
      ));
    }
    for (final o in orders) {
      if (o.status != OrderStatus.paid || o.ticketId != null || o.prep == PrepStatus.served) continue;
      out.add(KitchenEntry(
        id: o.id,
        label: o.type == OrderType.dineIn && o.tableNumber != null ? 'โต๊ะ ${o.tableNumber}' : o.type.label,
        createdAt: o.createdAt,
        lines: o.lines,
        prep: o.prep,
        source: o.source,
        order: o,
      ));
    }
    out.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return out;
  }

  int get kitchenQueueCount => kitchenQueue.length;

  /// Back-compat: paid counter orders still in the kitchen.
  List<Order> get kitchenOrders => kitchenQueue.where((e) => e.order != null).map((e) => e.order!).toList();

  void setEntryPrep(KitchenEntry e, PrepStatus prep) {
    if (e.ticket != null) {
      e.ticket!.prep = prep;
      // keep the settled order (if any) in step for the order-status screen
      final o = e.ticket!.settledOrderId == null ? null : orderById(e.ticket!.settledOrderId!);
      if (o != null) o.prep = prep;
    }
    if (e.order != null) e.order!.prep = prep;
    _changed();
  }

  void advanceEntry(KitchenEntry e) => setEntryPrep(e, e.prep.next);
  void revertEntry(KitchenEntry e) => setEntryPrep(e, e.prep.previous);

  /// Back-compat for screens that bump [Order]s directly.
  void advanceOrderPrep(Order order) {
    if (order.prep == PrepStatus.served) return;
    order.prep = order.prep.next;
    _changed();
  }

  void setOrderPrep(Order order, PrepStatus prep) {
    order.prep = prep;
    _changed();
  }

  // ─────────────────────────── tax invoice ───────────────────────────

  /// Issue a full tax invoice for [order] with a gap-free running number per
  /// Buddhist year (INV-2569-000001). Re-issuing keeps the original number.
  String issueTaxInvoice(Order order, TaxBuyer buyer) {
    order.taxBuyer = buyer;
    order.taxInvoiceNo ??= 'INV-${order.createdAt.year + 543}-${(_taxSeq++).toString().padLeft(6, '0')}';
    log('taxinvoice', '${order.taxInvoiceNo} · ${order.id} · ${buyer.name}');
    _changed();
    return order.taxInvoiceNo!;
  }

  // ─────────────────────────── customers / tiers ───────────────────────────

  Customer? customerById(String id) {
    for (final c in customers) {
      if (c.id == id) return c;
    }
    return null;
  }

  Customer? customerByPhone(String phone) {
    final d = phone.replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return null;
    for (final c in customers) {
      if (c.phone.replaceAll(RegExp(r'\D'), '') == d) return c;
    }
    return null;
  }

  List<Customer> searchCustomers(String q) {
    final s = q.trim().toLowerCase();
    if (s.isEmpty) return List.of(customers);
    final digits = s.replaceAll(RegExp(r'\D'), '');
    return customers
        .where((c) =>
            c.name.toLowerCase().contains(s) ||
            (digits.isNotEmpty && c.phone.replaceAll(RegExp(r'\D'), '').contains(digits)) ||
            c.email.toLowerCase().contains(s))
        .toList();
  }

  /// [referred] = the member signed up through this shop's referral link.
  Customer addCustomer(String name, {String phone = '', String email = '', String note = '', DateTime? birthday, bool referred = false}) {
    final c = Customer(
      id: _id('C'),
      name: name.trim(),
      phone: phone.trim(),
      email: email.trim(),
      note: note.trim(),
      birthday: birthday,
      createdAt: _now(),
      referralCode: referred ? referralCode : '',
    );
    customers.insert(0, c);
    log('customer.add', c.name);
    _changed();
    return c;
  }

  void updateCustomer(Customer c,
      {String? name, String? phone, String? email, String? note, DateTime? birthday, bool clearBirthday = false, bool? referred}) {
    if (name != null) c.name = name.trim();
    if (phone != null) c.phone = phone.trim();
    if (email != null) c.email = email.trim();
    if (note != null) c.note = note.trim();
    if (birthday != null) c.birthday = birthday;
    if (clearBirthday) c.birthday = null;
    if (referred != null) c.referralCode = referred ? referralCode : '';
    if (customerId == c.id) customerName = c.name;
    _changed();
  }

  void deleteCustomer(Customer c) {
    customers.remove(c);
    if (customerId == c.id) {
      customerId = null;
      customerName = null;
    }
    log('customer.remove', c.name);
    _changed();
  }

  void adjustPoints(Customer c, int delta, {String reason = ''}) {
    c.points = (c.points + delta).clamp(0, 1 << 31);
    log('points', '${c.name} ${delta > 0 ? '+' : ''}$delta${reason.isEmpty ? '' : ' · $reason'}');
    _changed();
  }

  List<MembershipTier> get sortedTiers => List.of(tiers)..sort((a, b) => a.minSpent.compareTo(b.minSpent));

  MembershipTier tierFor(Customer c) {
    final list = sortedTiers;
    var t = list.isNotEmpty ? list.first : MembershipTier(id: 'tier-basic', name: 'ทั่วไป', minSpent: 0);
    for (final x in list) {
      if (c.spent >= x.minSpent) t = x;
    }
    return t;
  }

  /// The next tier above [c] and the baht still needed, or null at the top.
  ({MembershipTier tier, int remaining})? nextTierFor(Customer c) {
    for (final x in sortedTiers) {
      if (x.minSpent > c.spent) return (tier: x, remaining: x.minSpent - c.spent);
    }
    return null;
  }

  int membersInTier(MembershipTier t) => customers.where((c) => tierFor(c).id == t.id).length;

  void upsertTier(MembershipTier t) {
    final i = tiers.indexWhere((x) => x.id == t.id);
    if (i >= 0) {
      tiers[i] = t;
    } else {
      tiers.add(t);
    }
    log('tier', '${t.name} ≥ ฿${t.minSpent} · ลด ${t.discountPercent}%');
    _changed();
  }

  void deleteTier(MembershipTier t) {
    if (tiers.length <= 1) return;
    tiers.remove(t);
    _changed();
  }

  String newTierId() => _id('tier');

  // ─────────────────────────── coupons / promotions CRUD ───────────────────────────

  void upsertCoupon(CouponDef d) {
    final i = couponDefs.indexWhere((x) => x.code == d.code);
    if (i >= 0) {
      couponDefs[i] = d;
    } else {
      couponDefs.insert(0, d);
    }
    log('coupon', '${d.code} ${d.summary}');
    _changed();
  }

  void deleteCoupon(CouponDef d) {
    couponDefs.remove(d);
    if (_couponCode == d.code) _couponCode = null;
    log('coupon.remove', d.code);
    _changed();
  }

  void setCouponActive(CouponDef d, bool on) {
    d.active = on;
    _changed();
  }

  void upsertPromotion(Promotion p) {
    final i = promotions.indexWhere((x) => x.id == p.id);
    if (i >= 0) {
      promotions[i] = p;
    } else {
      promotions.insert(0, p);
    }
    log('promotion', '${p.name} ${p.summary}');
    _changed();
  }

  void deletePromotion(Promotion p) {
    promotions.remove(p);
    log('promotion.remove', p.name);
    _changed();
  }

  void setPromotionActive(Promotion p, bool on) {
    p.active = on;
    _changed();
  }

  String newPromotionId() => _id('PR');

  // ─────────────────────────── tables ───────────────────────────

  TableInfo? tableByNumber(int n) {
    for (final t in tables) {
      if (t.number == n) return t;
    }
    return null;
  }

  int get nextTableNumber => tables.isEmpty ? 1 : tables.map((t) => t.number).reduce((a, b) => a > b ? a : b) + 1;

  TableInfo addTable({int? number, int seats = 4, TableShape shape = TableShape.square, String zone = 'ในร้าน', double? x, double? y}) {
    final n = number ?? nextTableNumber;
    if (tableByNumber(n) != null) throw StateError('มีโต๊ะหมายเลข $n แล้ว');
    final i = tables.length;
    final t = TableInfo(
      number: n,
      seats: seats,
      shape: shape,
      zone: zone,
      x: x ?? (0.08 + (i % 5) * 0.18).clamp(0.0, 0.9),
      y: y ?? (0.1 + (i ~/ 5) * 0.24).clamp(0.0, 0.9),
    );
    tables.add(t);
    log('table.add', 'โต๊ะ $n');
    _changed();
    return t;
  }

  void updateTable(TableInfo t, {int? number, int? seats, TableShape? shape, String? zone, double? x, double? y}) {
    if (number != null && number != t.number) {
      if (tableByNumber(number) != null) throw StateError('มีโต๊ะหมายเลข $number แล้ว');
      t.number = number;
    }
    if (seats != null) t.seats = seats.clamp(1, 40);
    if (shape != null) t.shape = shape;
    if (zone != null) t.zone = zone;
    if (x != null) t.x = x.clamp(0.0, 1.0);
    if (y != null) t.y = y.clamp(0.0, 1.0);
    _changed();
  }

  void removeTable(TableInfo t) {
    if (openTicketsForTable(t.number).isNotEmpty) throw StateError('โต๊ะ ${t.number} ยังมีออเดอร์ค้างอยู่');
    tables.remove(t);
    log('table.remove', 'โต๊ะ ${t.number}');
    _changed();
  }

  void setTableStatus(TableInfo table, TableStatus status, {int? guests, String? reservedFor}) {
    table.status = status;
    if (guests != null) table.guests = guests;
    if (status == TableStatus.seated) table.seatedAt ??= _now();
    if (status == TableStatus.free) {
      table.guests = 0;
      table.seatedAt = null;
      table.reservedFor = null;
      table.callWaiter = false;
    }
    if (status == TableStatus.reserved) table.reservedFor = reservedFor;
    _changed();
  }

  /// Seat guests at a table and point the counter cart at it.
  void seatTable(TableInfo t, int guests) {
    setTableStatus(t, TableStatus.seated, guests: guests);
    tableNumber = t.number;
    this.guests = guests;
    orderType = OrderType.dineIn;
    notifyListeners();
  }

  // ─────────────────────────── shift / cash drawer ───────────────────────────

  bool get hasOpenShift => currentShift?.isOpen ?? false;

  void openShift({int openingCash = 0}) {
    if (hasOpenShift) return;
    currentShift = Shift(
      id: _id('SH'),
      openedAt: _now(),
      openingCash: openingCash,
      cashier: actorName,
      staffId: currentStaff?.id,
    );
    log('shift.open', 'เงินทอนตั้งต้น ฿$openingCash');
    _changed();
  }

  void addCashMovement(CashMoveType type, int amount, {String reason = ''}) {
    final s = currentShift;
    if (s == null || !s.isOpen || amount <= 0) return;
    s.movements.add(CashMovement(at: _now(), type: type, amount: amount, reason: reason.trim(), by: actorName));
    log('drawer', '${type.label} ฿$amount${reason.isEmpty ? '' : ' · $reason'}');
    _changed();
  }

  /// Paid orders recorded during a shift's open window.
  List<Order> ordersInShift(Shift shift) => orders
      .where((o) =>
          o.status != OrderStatus.open &&
          o.status != OrderStatus.voided &&
          (o.shiftId == shift.id ||
              (o.shiftId == null &&
                  !o.createdAt.isBefore(shift.openedAt) &&
                  (shift.closedAt == null || o.createdAt.isBefore(shift.closedAt!)))))
      .toList();

  int shiftSales(Shift s) => ordersInShift(s).fold(0, (sum, o) => sum + o.total);
  int shiftRefunds(Shift s) => ordersInShift(s).fold(0, (sum, o) => sum + o.refundAmount);

  Map<PaymentMethod, int> shiftByMethod(Shift s) {
    final m = <PaymentMethod, int>{for (final p in PaymentMethod.values) p: 0};
    for (final o in ordersInShift(s)) {
      m[o.method] = (m[o.method] ?? 0) + o.netTotal;
    }
    return m;
  }

  /// Cash that should be in the drawer now: float + cash sales − cash refunds ± movements.
  int expectedCash(Shift s) {
    final cashOrders = ordersInShift(s).where((o) => o.method == PaymentMethod.cash);
    final cashNet = cashOrders.fold<int>(0, (sum, o) => sum + o.total - o.refundAmount);
    return s.openingCash + cashNet + s.movementNet;
  }

  /// Close the shift with the physically counted cash → Z-report snapshot.
  Shift? closeShift({int? countedCash, String note = ''}) {
    final s = currentShift;
    if (s == null || !s.isOpen) return null;
    s.closedAt = _now();
    s.expectedCash = expectedCash(s);
    s.countedCash = countedCash ?? s.expectedCash;
    s.salesTotal = shiftSales(s);
    s.refundTotal = shiftRefunds(s);
    s.orderCount = ordersInShift(s).length;
    s.byMethod = {for (final e in shiftByMethod(s).entries) e.key.name: e.value};
    s.closedBy = actorName;
    s.note = note.trim();
    s.zNumber = _zSeq++;
    shiftHistory.insert(0, s);
    currentShift = null;
    log('shift.close', 'Z#${s.zNumber} ยอด ฿${s.salesTotal} ส่วนต่าง ฿${s.cashVariance}');
    _changed();
    return s;
  }

  // ─────────────────────────── suppliers / purchase orders ───────────────────────────

  Supplier addSupplier({required String name, String category = '', String phone = '', String contact = '', String note = ''}) {
    final s = Supplier(id: _id('SUP'), name: name.trim(), category: category.trim(), phone: phone.trim(), contact: contact.trim(), note: note.trim());
    suppliers.add(s);
    log('supplier.add', s.name);
    _changed();
    return s;
  }

  void updateSupplier(Supplier s, {String? name, String? category, String? phone, String? contact, String? note}) {
    if (name != null) s.name = name.trim();
    if (category != null) s.category = category.trim();
    if (phone != null) s.phone = phone.trim();
    if (contact != null) s.contact = contact.trim();
    if (note != null) s.note = note.trim();
    _changed();
  }

  void removeSupplier(Supplier s) {
    suppliers.remove(s);
    log('supplier.remove', s.name);
    _changed();
  }

  Supplier? supplierById(String id) {
    for (final s in suppliers) {
      if (s.id == id) return s;
    }
    return null;
  }

  PurchaseOrder createPurchaseOrder(Supplier s, List<PoLine> lines, {String note = ''}) {
    final po = PurchaseOrder(
      id: 'PO-${(_poSeq++).toString().padLeft(4, '0')}',
      supplierId: s.id,
      supplierName: s.name,
      createdAt: _now(),
      lines: lines,
      note: note.trim(),
      createdBy: actorName,
    );
    purchaseOrders.insert(0, po);
    log('po.create', '${po.id} ${s.name} ฿${po.total}');
    _changed();
    return po;
  }

  void markPoOrdered(PurchaseOrder po) {
    if (po.status != PoStatus.draft) return;
    po.status = PoStatus.ordered;
    final s = supplierById(po.supplierId);
    if (s != null) s.lastOrder = '${po.createdAt.day}/${po.createdAt.month}/${po.createdAt.year + 543}';
    log('po.order', po.id);
    _changed();
  }

  /// Receive goods: stock in (ledger), update unit cost to the PO price.
  void receivePurchaseOrder(PurchaseOrder po, {bool updateCost = true}) {
    if (po.status == PoStatus.received || po.status == PoStatus.cancelled) return;
    for (final l in po.lines) {
      final p = productByCode(l.code);
      if (p == null) continue;
      _move(p, l.qty, StockMoveType.receive, reason: po.supplierName, ref: po.id);
      if (updateCost && l.unitCost > 0 && l.unitCost != p.cost) {
        final i = products.indexOf(p);
        if (i >= 0) products[i] = p.copyWith(cost: l.unitCost);
      }
    }
    po.status = PoStatus.received;
    po.receivedAt = _now();
    log('po.receive', '${po.id} ${po.itemCount} ชิ้น');
    _changed();
  }

  void cancelPurchaseOrder(PurchaseOrder po) {
    if (po.status == PoStatus.received) return;
    po.status = PoStatus.cancelled;
    log('po.cancel', po.id);
    _changed();
  }

  // ─────────────────────────── delivery / shipping ───────────────────────────

  /// [fee] null → the provider's base fee; 0 → free delivery.
  DeliveryJob createDelivery(Order order,
      {String customerName = '',
      String phone = '',
      String address = '',
      String providerId = 'self',
      int? fee,
      bool cod = false,
      int weightGrams = 500,
      String note = '',
      String trackingNo = '',
      String riderName = ''}) {
    final p = providerById(providerId);
    final job = DeliveryJob(
      id: 'DL-${(_deliverySeq++).toString().padLeft(4, '0')}',
      orderId: order.id,
      createdAt: _now(),
      customerName: customerName.trim().isNotEmpty ? customerName.trim() : (order.customerName ?? ''),
      phone: phone.trim(),
      address: address.trim(),
      providerId: providerId,
      fee: fee ?? (p?.baseFee ?? 0),
      cod: cod,
      weightGrams: weightGrams,
      note: note.trim(),
      trackingNo: trackingNo.trim(),
      riderName: riderName.trim(),
    );
    deliveries.insert(0, job);
    log('delivery', '${job.id} ← ${order.id} (${p?.name ?? providerId})');
    _changed();
    return job;
  }

  DeliveryJob? deliveryForOrder(String orderId) {
    for (final d in deliveries) {
      if (d.orderId == orderId && d.status != DeliveryStatus.cancelled) return d;
    }
    return null;
  }

  void updateDelivery(DeliveryJob j,
      {String? customerName, String? phone, String? address, String? providerId, String? trackingNo, String? riderName, int? fee, bool? cod, int? weightGrams, String? note}) {
    if (customerName != null) j.customerName = customerName.trim();
    if (phone != null) j.phone = phone.trim();
    if (address != null) j.address = address.trim();
    if (providerId != null) j.providerId = providerId;
    if (trackingNo != null) j.trackingNo = trackingNo.trim();
    if (riderName != null) j.riderName = riderName.trim();
    if (fee != null) j.fee = fee;
    if (cod != null) j.cod = cod;
    if (weightGrams != null) j.weightGrams = weightGrams;
    if (note != null) j.note = note.trim();
    _changed();
  }

  void advanceDelivery(DeliveryJob j) {
    if (j.status == DeliveryStatus.delivered || j.status == DeliveryStatus.cancelled) return;
    j.status = j.status.next;
    if (j.status == DeliveryStatus.delivered) j.deliveredAt = _now();
    log('delivery.status', '${j.id} → ${j.status.label}');
    _changed();
  }

  void cancelDelivery(DeliveryJob j) {
    j.status = DeliveryStatus.cancelled;
    log('delivery.cancel', j.id);
    _changed();
  }

  // ─────────────────────────── Thai Prompt rider ───────────────────────────
  //
  // Cashier → "Thai Prompt · ส่งไรเดอร์" → the server prices the cart and
  // returns a QR → the customer pays goods + delivery from their Thai Prompt
  // wallet in the app → a rider picks up here. The POS bill is recorded only
  // when the server reports the request paid (RiderTracker polls), from the
  // server-priced lines kept on the job — so a payment that lands after the
  // cart was parked, or after a restart, is still booked exactly once.

  /// Job whose QR is on the customer display right now (null = none).
  String? riderQrJobId;

  DeliveryJob? get riderQrJob {
    final id = riderQrJobId;
    if (id == null) return null;
    for (final d in deliveries) {
      if (d.id == id) return d.awaitingPayment ? d : null;
    }
    return null;
  }

  void showRiderQr(DeliveryJob? j) {
    final id = j?.id;
    if (riderQrJobId == id) return;
    riderQrJobId = id;
    notifyListeners(); // display only — nothing to persist
  }

  List<DeliveryJob> get tpActiveJobs => deliveries.where((d) => d.tpActive).toList();

  /// The counter cart as request items — one row per product (options / notes
  /// travel in the request note: the online catalog has no POS modifiers).
  List<Map<String, dynamic>> tpRiderRequestItems() {
    final byCode = <String, Map<String, dynamic>>{};
    for (final l in cart) {
      final p = l.product;
      final row = byCode.putIfAbsent(p.code, () => {
            if (p.serverId != null) 'product_id': p.serverId,
            'sku': p.code,
            'name': p.name,
            'qty': 0,
          });
      row['qty'] = (row['qty'] as int) + l.qty;
    }
    return byCode.values.toList();
  }

  /// Options / notes of the cart lines as text for the rider request note.
  String tpRiderCartNote() => [
        for (final l in cart)
          if (l.options.isNotEmpty || l.note.isNotEmpty)
            '${l.product.name}: ${[...l.options, if (l.note.isNotEmpty) l.note].join(' · ')}',
      ].join(' / ');

  /// Record a request the server just created. Re-POSTing the same local id
  /// returns the same server request → the existing job is reused.
  DeliveryJob createTpRiderJob({
    required int requestId,
    required String qrPayload,
    required DateTime? expiresAt,
    required List<TpRiderLine> lines,
    required int subtotal,
    String customerName = '',
    String phone = '',
    String note = '',
  }) {
    for (final d in deliveries) {
      if (d.isTpRider && d.requestId == requestId) return d;
    }
    final job = DeliveryJob(
      id: 'DL-${(_deliverySeq++).toString().padLeft(4, '0')}',
      orderId: '',
      createdAt: _now(),
      customerName: customerName.trim(),
      phone: phone.trim(),
      providerId: kTpRiderProviderId,
      note: note.trim(),
      requestId: requestId,
      qrPayload: qrPayload,
      qrExpiresAt: expiresAt,
      payStatus: 'pending',
      subtotal: subtotal,
      lines: lines,
      weightGrams: 0,
    );
    deliveries.insert(0, job);
    log('delivery.tp', '${job.id} ← request #$requestId ฿$subtotal');
    _changed();
    return job;
  }

  /// Next local id for a rider request (idempotency key on the server).
  String get nextDeliveryId => 'DL-${_deliverySeq.toString().padLeft(4, '0')}';

  /// Merge a server snapshot (`GET /api/pos/delivery-requests/{id}`). Books the
  /// POS bill the first time the request is paid. Returns true when changed.
  bool applyTpRiderStatus(DeliveryJob j, Map<String, dynamic> d) {
    if (!j.isTpRider) return false;
    final before = jsonEncode(j.toJson());
    String str(Object? v) => v == null ? '' : '$v';
    Map<String, dynamic>? obj(Object? v) => v is Map ? v.cast<String, dynamic>() : null;

    final pay = str(d['status']);
    if (pay.isNotEmpty) j.payStatus = pay;
    final exp = DateTime.tryParse(str(d['expires_at']));
    if (exp != null) j.qrExpiresAt = exp.toLocal();
    final fee = d['delivery_fee'];
    if (fee is num) j.fee = fee.round();
    final order = obj(d['order']);
    if (order != null && str(order['order_number']).isNotEmpty) j.remoteOrderNo = str(order['order_number']);
    final cust = obj(d['customer']);
    if (cust != null) {
      if (str(cust['display_name']).isNotEmpty) j.customerName = str(cust['display_name']);
      if (str(cust['address_short']).isNotEmpty) j.address = str(cust['address_short']);
    }
    final rj = obj(d['rider_job']);
    if (rj != null) {
      j.riderStatus = str(rj['status']);
      if (str(rj['job_number']).isNotEmpty) j.trackingNo = str(rj['job_number']);
      final r = obj(rj['rider']);
      if (r != null) {
        j.riderName = str(r['display_name']);
        j.riderPlate = str(r['plate_masked']);
        j.riderPhone = str(r['phone_masked']);
      }
    }
    final ho = obj(d['handover']);
    if (ho != null) j.handoverStatus = str(ho['status']);
    j.syncedAt = _now();

    // payment → POS bill (exactly once)
    if (j.payStatus == 'paid' && j.orderId.isEmpty) {
      final o = _recordTpSale(j);
      j.orderId = o.id;
    }
    final next = switch (j.payStatus) {
      'expired' || 'cancelled' => DeliveryStatus.cancelled,
      'pending' => DeliveryStatus.pending,
      _ => switch (j.riderStatus) {
          'accepted' || 'assigned' || 'picking_up' => DeliveryStatus.picking,
          'picked_up' || 'delivering' || 'delivered' || 'awaiting_release' => DeliveryStatus.delivering,
          'completed' => DeliveryStatus.delivered,
          _ => DeliveryStatus.pending,
        },
    };
    if (next != j.status) {
      j.status = next;
      if (next == DeliveryStatus.delivered) j.deliveredAt ??= _now();
      log('delivery.status', '${j.id} → ${j.tpStatusLabel}');
    }
    if (j.status == DeliveryStatus.cancelled && riderQrJobId == j.id) riderQrJobId = null;
    final changed = jsonEncode(j.toJson()) != before;
    if (changed) _changed();
    return changed;
  }

  /// The paid request as a POS bill: server prices, VAT treated as included
  /// (the app charged the final price), stock out, kitchen queued. Not sent
  /// to the POS order sync — Thai Prompt already has this order.
  Order _recordTpSale(DeliveryJob j) {
    final now = _now();
    final lines = <OrderLine>[
      for (final l in j.lines)
        () {
          final p = productByCode(l.code);
          return OrderLine(
            name: l.name.isNotEmpty ? l.name : (p?.name ?? l.code),
            code: l.code,
            note: l.note,
            qty: l.qty,
            price: l.price,
            hue: p?.hue ?? stableHue(l.name),
            kind: p?.kind ?? 'rect',
            options: l.options.isEmpty ? const [] : l.options.split(' · '),
            cost: p?.cost ?? 0,
            art: p?.art,
          );
        }(),
    ];
    final subtotal = j.subtotal > 0 ? j.subtotal : lines.fold<int>(0, (s, l) => s + l.lineTotal);
    final tax = vatEnabled ? (subtotal * vatRate / (1 + vatRate)).round() : 0;
    final order = Order(
      id: openOrderId,
      createdAt: now,
      lines: lines,
      subtotal: subtotal,
      discount: 0,
      tax: tax,
      total: subtotal,
      method: PaymentMethod.thaiprompt,
      type: OrderType.delivery,
      cashier: actorName,
      customerName: j.customerName.isEmpty ? null : j.customerName,
      staffId: currentStaff?.id,
      shiftId: currentShift?.id,
      paymentRef: j.remoteOrderNo.isEmpty ? 'TP-REQ-${j.requestId}' : j.remoteOrderNo,
      source: OrderSource.delivery,
      prep: kitchenEnabled ? PrepStatus.queued : PrepStatus.served,
    );
    for (final l in j.lines) {
      final p = productByCode(l.code);
      if (p != null) _move(p, -l.qty, StockMoveType.sale, ref: order.id);
    }
    orders.insert(0, order);
    _lastOrder = order;
    _orderSeq++;
    log('checkout', '${order.id} Thai Prompt ฿${order.total} (${j.id})');
    return order;
  }

  /// After the server accepted the cancel (or the QR expired).
  void markTpRiderClosed(DeliveryJob j, {String payStatus = 'cancelled'}) {
    if (!j.isTpRider || j.payStatus == 'paid') return;
    j.payStatus = payStatus;
    j.status = DeliveryStatus.cancelled;
    if (riderQrJobId == j.id) riderQrJobId = null;
    log('delivery.cancel', '${j.id} ($payStatus)');
    _changed();
  }

  /// Display name of a delivery provider id (incl. the built-in Thai Prompt riders).
  String providerLabel(String id) => id == kTpRiderProviderId ? 'ไรเดอร์ Thai Prompt' : (providerById(id)?.name ?? id);

  ShippingProvider? providerById(String id) {
    for (final p in shippingProviders) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<ShippingProvider> get enabledProviders => shippingProviders.where((p) => p.enabled).toList();

  void updateProvider(ShippingProvider p, {bool? enabled, int? baseFee, String? accountId, String? name, String? trackingUrl}) {
    if (enabled != null) p.enabled = enabled;
    if (baseFee != null) p.baseFee = baseFee;
    if (accountId != null) p.accountId = accountId.trim();
    if (name != null) p.name = name.trim();
    if (trackingUrl != null) p.trackingUrl = trackingUrl.trim();
    _changed();
  }

  // ─────────────────────────── branches ───────────────────────────

  Branch? get currentBranch {
    for (final b in branches) {
      if (b.isCurrent) return b;
    }
    return null;
  }

  Branch addBranch({required String name, String area = '', String phone = ''}) {
    final b = Branch(id: _id('BR'), name: name.trim(), area: area.trim(), phone: phone.trim(), isCurrent: branches.isEmpty);
    branches.add(b);
    log('branch.add', b.name);
    _changed();
    return b;
  }

  void updateBranch(Branch b, {String? name, String? area, String? phone}) {
    if (name != null) b.name = name.trim();
    if (area != null) b.area = area.trim();
    if (phone != null) b.phone = phone.trim();
    if (b.isCurrent && name != null) branch = b.name;
    _changed();
  }

  void setCurrentBranch(Branch b) {
    for (final x in branches) {
      x.isCurrent = identical(x, b);
    }
    branch = b.name;
    log('branch.switch', b.name);
    _changed();
  }

  void removeBranch(Branch b) {
    if (b.isCurrent) throw StateError('ลบสาขาที่เครื่องนี้ใช้งานอยู่ไม่ได้');
    branches.remove(b);
    _changed();
  }

  // ─────────────────────────── affiliate ───────────────────────────

  /// Shop referral code — stable per terminal/shop.
  String get referralCode {
    final seed = productKey.isNotEmpty ? productKey : (deviceId.isNotEmpty ? deviceId : shopName);
    return 'TP${(fnv1a(seed) % 1679616).toRadixString(36).toUpperCase().padLeft(4, '0')}';
  }

  String get referralLink => 'https://thaiprompt.online/r/$referralCode';

  List<Customer> get referredCustomers => customers.where((c) => c.referralCode == referralCode).toList();

  // ─────────────────────────── reporting / aggregates ───────────────────────────

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// Orders that count as sales (paid, incl. partially refunded).
  List<Order> get paidOrders => orders.where((o) => o.status == OrderStatus.paid).toList();

  /// Paid + refunded (for histories that must show refunds too).
  List<Order> get settledOrders =>
      orders.where((o) => o.status == OrderStatus.paid || o.status == OrderStatus.refunded).toList();

  List<Order> ordersOn(DateTime day) => paidOrders.where((o) => _sameDay(o.createdAt, day)).toList();

  List<Order> ordersBetween(DateTime from, DateTime to) => settledOrders
      .where((o) => !o.createdAt.isBefore(from) && o.createdAt.isBefore(to))
      .toList();

  int get todaySales => ordersOn(_now()).fold(0, (s, o) => s + o.netTotal);
  int get todayOrderCount => ordersOn(_now()).length;
  int get todayItemCount => ordersOn(_now()).fold(0, (s, o) => s + o.itemCount);
  int get todayRefunds =>
      settledOrders.where((o) => o.refundedAt != null && _sameDay(o.refundedAt!, _now())).fold(0, (s, o) => s + o.refundAmount);

  int get avgBasket {
    final list = ordersOn(_now());
    final src = list.isEmpty ? paidOrders : list;
    if (src.isEmpty) return 0;
    return (src.fold<int>(0, (s, o) => s + o.netTotal) / src.length).round();
  }

  int get lifetimeSales => paidOrders.fold(0, (s, o) => s + o.netTotal);

  List<({DateTime day, int total, int orders})> salesByDay({int days = 7}) {
    final today = _now();
    final out = <({DateTime day, int total, int orders})>[];
    for (var i = days - 1; i >= 0; i--) {
      final day = DateTime(today.year, today.month, today.day).subtract(Duration(days: i));
      final list = ordersOn(day);
      out.add((day: day, total: list.fold<int>(0, (s, o) => s + o.netTotal), orders: list.length));
    }
    return out;
  }

  /// Sales per hour of [day] (24 buckets).
  List<int> salesByHour(DateTime day) {
    final out = List<int>.filled(24, 0);
    for (final o in ordersOn(day)) {
      out[o.createdAt.hour] += o.netTotal;
    }
    return out;
  }

  Map<PaymentMethod, int> salesByMethod(List<Order> list) {
    final m = <PaymentMethod, int>{for (final p in PaymentMethod.values) p: 0};
    for (final o in list) {
      if (o.status == OrderStatus.paid) m[o.method] = (m[o.method] ?? 0) + o.netTotal;
    }
    return m;
  }

  /// Revenue by category name across [list].
  Map<String, int> salesByCategory(List<Order> list) {
    final out = <String, int>{};
    for (final o in list) {
      if (o.status != OrderStatus.paid) continue;
      for (final l in o.lines) {
        final p = productByCode(l.code);
        final cat = p == null ? 'อื่น ๆ' : (categoryById(p.categoryId)?.name ?? 'อื่น ๆ');
        out[cat] = (out[cat] ?? 0) + (l.qty - l.refundedQty) * l.price;
      }
    }
    return out;
  }

  /// Best sellers by quantity across [list] (defaults to all paid orders).
  List<({String name, int qty, int revenue})> topProducts({int limit = 5, List<Order>? from}) {
    final qty = <String, int>{};
    final rev = <String, int>{};
    for (final o in from ?? paidOrders) {
      if (o.status != OrderStatus.paid) continue;
      for (final l in o.lines) {
        final q = l.qty - l.refundedQty;
        if (q <= 0) continue;
        qty[l.name] = (qty[l.name] ?? 0) + q;
        rev[l.name] = (rev[l.name] ?? 0) + q * l.price;
      }
    }
    final entries = qty.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).map((e) => (name: e.key, qty: e.value, revenue: rev[e.key] ?? 0)).toList();
  }

  /// P&L style summary for [list].
  ({int gross, int discounts, int tax, int refunds, int net, int cogs, int profit}) summarize(List<Order> list) {
    var gross = 0, disc = 0, tax = 0, refunds = 0, cogs = 0, total = 0;
    for (final o in list) {
      if (o.status == OrderStatus.open || o.status == OrderStatus.voided) continue;
      gross += o.subtotal;
      disc += o.discount;
      // VAT is taken from each bill (not today's settings) and the refunded
      // share of it is reversed, so a fully refunded bill nets to zero.
      final refundedTax = o.total == 0 ? 0 : (o.tax * o.refundAmount / o.total).round();
      tax += o.tax - refundedTax;
      refunds += o.refundAmount;
      total += o.total;
      cogs += o.cogs;
    }
    final net = total - refunds;
    final revenueExVat = net - tax;
    return (gross: gross, discounts: disc, tax: tax, refunds: refunds, net: net, cogs: cogs, profit: revenueExVat - cogs);
  }

  // ─────────────────────────── settings ───────────────────────────

  void updateSettings({
    String? shop,
    String? branchName,
    String? cashierName,
    double? vat,
    bool? vatOn,
    bool? vatIncluded,
    String? phone,
    String? address,
    String? taxNumber,
    String? promptPay,
    String? footer,
    bool? kitchen,
    bool? shiftRequired,
    bool? autoPrint,
    String? printer,
    int? paperWidth,
    bool? sound,
    String? printMode,
    String? printAddress,
    String? printDeviceName,
    bool? autoCut,
    bool? drawerAfterCash,
    bool? secondScreen,
    String? secondScreenDisplay,
    bool? autoUpdates,
  }) {
    if (shop != null) shopName = shop.trim();
    if (branchName != null) {
      branch = branchName.trim();
      currentBranch?.name = branch;
    }
    if (cashierName != null) cashier = cashierName;
    if (vat != null) vatRate = vat;
    if (vatOn != null) vatEnabled = vatOn;
    if (vatIncluded != null) vatInclusive = vatIncluded;
    if (phone != null) shopPhone = phone.trim();
    if (address != null) shopAddress = address.trim();
    if (taxNumber != null) taxId = taxNumber.replaceAll(RegExp(r'\D'), '');
    if (promptPay != null) promptPayId = promptPay.replaceAll(RegExp(r'\D'), '');
    if (footer != null) receiptFooter = footer.trim();
    if (kitchen != null) kitchenEnabled = kitchen;
    if (shiftRequired != null) requireShift = shiftRequired;
    if (autoPrint != null) autoPrintReceipt = autoPrint;
    if (printer != null) printerName = printer;
    if (paperWidth != null) paperWidthMm = paperWidth == 58 ? 58 : 80;
    if (sound != null) soundEnabled = sound;
    if (printMode != null) printerMode = const {'system', 'windows', 'network', 'bluetooth'}.contains(printMode) ? printMode : 'system';
    if (printAddress != null) printerAddress = printAddress.trim();
    if (printDeviceName != null) printerDeviceName = printDeviceName.trim();
    if (autoCut != null) printerAutoCut = autoCut;
    if (drawerAfterCash != null) drawerOnCash = drawerAfterCash;
    if (secondScreen != null) secondScreenEnabled = secondScreen;
    if (secondScreenDisplay != null) secondScreenId = secondScreenDisplay;
    if (autoUpdates != null) autoUpdate = autoUpdates;
    log('settings');
    _changed();
  }

  /// Update the terminal connection settings and restart the sync loop.
  void updateServerConfig({String? baseUrl, String? productKey, String? deviceId}) {
    if (baseUrl != null) serverBaseUrl = baseUrl.trim();
    if (productKey != null) this.productKey = productKey.trim();
    if (deviceId != null) this.deviceId = deviceId.trim();
    final cfg = sync?.config;
    if (cfg != null) {
      cfg.baseUrl = serverBaseUrl;
      cfg.productKey = this.productKey;
      cfg.deviceId = this.deviceId;
    }
    log('server.config', serverBaseUrl);
    _changed();
    sync?.start();
  }

  // ─────────────────────────── server catalog merge ───────────────────────────

  /// Merge real products from /api/pos/sync/products into the local catalog.
  /// Server shape: {id, sku, barcode, name, price, cost, stock, category_id,
  /// category_name, image_url}. Also accepts the local `code` key. Local-only
  /// fields (art, options, availability) survive a server refresh.
  void upsertProductsFromApi(List<dynamic> rows) {
    var changed = false;
    for (final raw in rows) {
      if (raw is! Map) continue;
      final j = raw.cast<String, dynamic>();
      final code = (j['sku'] ?? j['code'] ?? j['barcode'] ?? j['id'])?.toString();
      if (code == null || code.isEmpty) continue;
      final idx = products.indexWhere((p) => p.code == code);
      final old = idx >= 0 ? products[idx] : null;
      final name = (j['name'] as String?) ?? old?.name ?? code;
      final merged = Product(
        id: code,
        code: code,
        name: name,
        price: (j['price'] as num?)?.round() ?? old?.price ?? 0,
        categoryId: (j['category_id'] ?? j['categoryId'])?.toString() ?? old?.categoryId ?? '',
        hue: (j['hue'] as num?)?.toInt() ?? old?.hue ?? stableHue(name),
        kind: (j['kind'] as String?) ?? old?.kind ?? 'rect',
        tag: (j['tag'] as String?) ?? old?.tag,
        barcode: (j['barcode'] as String?) ?? old?.barcode ?? '',
        cost: (j['cost'] as num?)?.round() ?? old?.cost ?? 0,
        art: old?.art,
        imageUrl: (j['image_url'] as String?) ?? old?.imageUrl,
        description: old?.description ?? '',
        available: old?.available ?? true,
        trackStock: old?.trackStock ?? true,
        options: old?.options ?? const [],
        serverId: j['id'] is num ? (j['id'] as num).toInt() : int.tryParse('${j['id'] ?? ''}') ?? old?.serverId,
        stock: (j['stock'] as num?)?.round() ?? old?.stock ?? 0,
      );
      if (idx >= 0) {
        products[idx] = merged;
      } else {
        products.add(merged);
      }
      changed = true;
    }
    if (changed) _changed();
  }

  /// Replace local categories with the shop's real ones (/api/pos/sync/categories).
  void upsertCategoriesFromApi(List<dynamic> rows) {
    final next = <Category>[];
    for (final raw in rows) {
      if (raw is Map) next.add(Category.fromApi(raw.cast<String, dynamic>()));
    }
    if (next.isEmpty) return;
    // keep a local icon choice when the server category already existed
    for (final n in next) {
      final old = categoryById(n.id);
      if (old != null) n.iconKey = old.iconKey;
    }
    categories
      ..clear()
      ..addAll(next);
    _changed();
  }

  @override
  void dispose() {
    _disk.dispose();
    super.dispose();
  }
}
