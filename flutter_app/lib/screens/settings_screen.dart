// Thaiprompt POS — Settings (Nova).
//
// Sections, each with its own validation and "บันทึก" (all through
// PosStore.updateSettings): ร้านค้า · การรับชำระ (PromptPay + live ฿1 test QR,
// VAT) · ใบเสร็จและเครื่องพิมพ์ (footer, paper, printer type: system driver /
// USB on Windows / LAN-Wi-Fi / Bluetooth incl. Sunmi InnerPrinter, auto-cut,
// cash drawer after cash sales, real test print / connection / drawer tests
// with the unsaved choices) · การทำงาน · เซิร์ฟเวอร์ Thai Prompt (the original
// pairing flow: URL + product key + API key → pairTerminal, sync now, unpair
// with confirm + manager PIN) · อัปเดตแอป (UpdateWatcher: check, install,
// auto-update when idle) · เกี่ยวกับ. Every controller is owned by this State
// and disposed with it.
//
// by xman studio

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/api/api_exceptions.dart';
import '../core/hardware/printer_hub.dart';
import '../core/payments/promptpay.dart';
import '../core/print/print_service.dart';
import '../core/sync/sync_service.dart';
import '../display/second_screen_settings.dart';
import '../models/order_models.dart';
import '../print/print_actions.dart' show rollMedium;
import '../print/receipt_doc.dart';
import '../services/auto_updater.dart';
import '../services/update_watcher.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';

/// Printer modes offered in the receipt section.
const _escModes = {'windows', 'network', 'bluetooth'};

/// LAN printer host field (IP or hostname only — the port has its own field).
String? _hostError(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return 'ใส่ IP ของเครื่องพิมพ์';
  if (t.contains(RegExp(r'[\s/]'))) return 'ใส่เฉพาะ IP หรือชื่อเครื่อง (ไม่ต้องมี http://)';
  if (RegExp(r'^[^:]+:\d*$').hasMatch(t)) return 'ใส่พอร์ตในช่อง "พอร์ต" แยกต่างหาก';
  return null;
}

/// Update texts must never show hosting details or raw URLs.
String _safeUpdateText(String s) {
  final l = s.toLowerCase();
  return l.contains('github') || l.contains('http') ? 'เชื่อมต่อเซิร์ฟเวอร์อัปเดตไม่ได้ — ตรวจอินเทอร์เน็ตแล้วลองใหม่' : s;
}

enum _Sec { shop, payment, receipt, display, ops, server, update, about }

extension _SecX on _Sec {
  String get title => switch (this) {
        _Sec.shop => 'ร้านค้า',
        _Sec.payment => 'การรับชำระ',
        _Sec.receipt => 'ใบเสร็จและเครื่องพิมพ์',
        _Sec.display => 'จอลูกค้า (จอที่สอง)',
        _Sec.ops => 'การทำงาน',
        _Sec.server => 'เซิร์ฟเวอร์ Thai Prompt',
        _Sec.update => 'อัปเดตแอป',
        _Sec.about => 'เกี่ยวกับ',
      };

  String get art => switch (this) {
        _Sec.shop => 'branch',
        _Sec.payment => 'promptpay',
        _Sec.receipt => 'printer',
        _Sec.display => 'display',
        _Sec.ops => 'shift',
        _Sec.server => 'sync',
        _Sec.update => 'settings',
        _Sec.about => 'pos',
      };
}

/// Thai 13-digit tax / citizen id with its mod-11 check digit.
bool _validTaxId(String d) {
  if (!RegExp(r'^\d{13}$').hasMatch(d)) return false;
  var sum = 0;
  for (var i = 0; i < 12; i++) {
    sum += (d.codeUnitAt(i) - 48) * (13 - i);
  }
  return (11 - sum % 11) % 10 == d.codeUnitAt(12) - 48;
}

/// VAT rate ↔ text, through whole hundredths of a percent (no raw double text).
int _rateHundredths(double rate) => (rate * 10000).round();
String _rateText(int hundredths) => hundredths % 100 == 0 ? '${hundredths ~/ 100}' : (hundredths / 100).toStringAsFixed(2);
int? _parseRate(String raw) {
  final v = double.tryParse(raw.trim().replaceAll(',', '.'));
  return v == null ? null : (v * 100).round();
}

/// Server URL must be https (http only for local development hosts).
String? _urlError(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return 'กรุณาใส่ที่อยู่เซิร์ฟเวอร์';
  final u = Uri.tryParse(t);
  if (u == null || u.host.isEmpty || !(u.scheme == 'https' || u.scheme == 'http')) return 'รูปแบบไม่ถูกต้อง เช่น https://main.thaiprompt.online';
  final localDev = u.host == 'localhost' || u.host == '127.0.0.1' || u.host == '10.0.2.2' || u.host.endsWith('.test') || u.host.endsWith('.localhost');
  if (u.scheme == 'http' && !localDev) return 'ต้องใช้ https เพื่อความปลอดภัยของข้อมูล';
  return null;
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ── controllers (owned + disposed here) ──
  final _shop = TextEditingController();
  final _branch = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _taxId = TextEditingController();
  final _promptPay = TextEditingController();
  final _vatRate = TextEditingController();
  final _footer = TextEditingController();
  final _baseUrl = TextEditingController();
  final _productKey = TextEditingController();
  final _apiKey = TextEditingController();
  final _host = TextEditingController();
  final _port = TextEditingController(text: '9100');
  final _scroll = ScrollController();

  final _shopForm = GlobalKey<FormState>();
  final _payForm = GlobalKey<FormState>();
  final _receiptForm = GlobalKey<FormState>();
  final _serverForm = GlobalKey<FormState>();
  final Map<_Sec, GlobalKey> _secKeys = {for (final s in _Sec.values) s: GlobalKey()};

  bool _vatOn = true;
  bool _vatIncl = false;
  int _paper = 80;
  String _printer = '';
  bool _autoPrint = false;
  bool _requireShift = true;
  bool _kitchen = true;
  bool _sound = true;

  // ── receipt printer hardware (draft until "บันทึก") ──
  String _mode = 'system'; // system | windows | network | bluetooth
  String _btMac = '';
  String _btName = '';
  bool _autoCut = true;
  bool _drawerOnCash = true;
  List<({String name, String mac})> _btDevices = <({String name, String mac})>[];
  bool _btLoading = false;
  bool _btLoadedOnce = false;
  String? _btError;
  bool _testingConn = false;
  bool _testingDrawer = false;

  List<String> _printers = <String>[];
  bool _loadingPrinters = false;
  bool _testing = false;
  bool _showKey = false;
  bool _pairing = false;
  bool _syncing = false;
  bool _loaded = false;

  // ── app version + update check result ──
  String _version = '…';
  String _build = '…';
  String? _checkMsg;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((p) {
      if (!mounted) return;
      setState(() {
        _version = p.version;
        _build = p.buildNumber;
      });
    }).catchError((_) {});
    _loadingPrinters = true;
    _fetchPrinters();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final s = AppScope.read(context);
    _shop.text = s.shopName;
    _branch.text = s.branch;
    _phone.text = s.shopPhone;
    _address.text = s.shopAddress;
    _taxId.text = s.taxId;
    _resetPayment(s);
    _resetReceipt(s);
    _resetOps(s);
    _baseUrl.text = s.serverBaseUrl;
    _productKey.text = s.productKey;
    if (_mode == 'bluetooth' && PrinterConfig.bluetoothSupported) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadBt();
      });
    }
  }

  void _resetShop(PosStore s) {
    _shop.text = s.shopName;
    _branch.text = s.branch;
    _phone.text = s.shopPhone;
    _address.text = s.shopAddress;
    _taxId.text = s.taxId;
  }

  void _resetPayment(PosStore s) {
    _promptPay.text = s.promptPayId;
    _vatRate.text = _rateText(_rateHundredths(s.vatRate));
    _vatOn = s.vatEnabled;
    _vatIncl = s.vatInclusive;
  }

  void _resetReceipt(PosStore s) {
    _footer.text = s.receiptFooter;
    _paper = s.paperWidthMm == 58 ? 58 : 80;
    _printer = s.printerName;
    _autoPrint = s.autoPrintReceipt;
    _mode = s.printerMode;
    _autoCut = s.printerAutoCut;
    _drawerOnCash = s.drawerOnCash;
    final hp = s.printerMode == 'network' ? parseHostPort(s.printerAddress) : null;
    _host.text = hp?.host ?? '';
    _port.text = '${hp?.port ?? 9100}';
    _btMac = s.printerMode == 'bluetooth' ? s.printerAddress : '';
    _btName = s.printerMode == 'bluetooth' ? s.printerDeviceName : '';
  }

  void _resetOps(PosStore s) {
    _requireShift = s.requireShift;
    _kitchen = s.kitchenEnabled;
    _sound = s.soundEnabled;
  }

  @override
  void dispose() {
    for (final c in [_shop, _branch, _phone, _address, _taxId, _promptPay, _vatRate, _footer, _baseUrl, _productKey, _apiKey, _host, _port]) {
      c.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  // ───────────────────────── dirty checks ─────────────────────────

  bool _shopDirty(PosStore s) =>
      _shop.text.trim() != s.shopName ||
      _branch.text.trim() != s.branch ||
      _phone.text.trim() != s.shopPhone ||
      _address.text.trim() != s.shopAddress ||
      _taxId.text.trim() != s.taxId;

  bool _payDirty(PosStore s) =>
      _promptPay.text.replaceAll(RegExp(r'\D'), '') != s.promptPayId ||
      _vatOn != s.vatEnabled ||
      _vatIncl != s.vatInclusive ||
      _parseRate(_vatRate.text) != _rateHundredths(s.vatRate);

  bool _receiptDirty(PosStore s) =>
      _footer.text.trim() != s.receiptFooter ||
      _paper != s.paperWidthMm ||
      _printer != s.printerName ||
      _autoPrint != s.autoPrintReceipt ||
      _mode != s.printerMode ||
      _addressDirty(s) ||
      _draftDeviceName(s) != s.printerDeviceName ||
      _autoCut != s.printerAutoCut ||
      _drawerOnCash != s.drawerOnCash;

  // ── printer draft (what the form would save) ──

  int? get _portValue => int.tryParse(_port.text.trim());

  String get _netAddress {
    final h = _host.text.trim();
    if (h.isEmpty) return '';
    final p = _portValue ?? 9100;
    return h.contains(':') ? '[$h]:$p' : '$h:$p';
  }

  /// network → host:port · bluetooth → MAC · other modes keep the saved value.
  String _draftAddress(PosStore s) => switch (_mode) {
        'network' => _netAddress,
        'bluetooth' => _btMac,
        _ => s.printerAddress,
      };

  String _draftDeviceName(PosStore s) => switch (_mode) {
        'windows' => _printer,
        'bluetooth' => _btName,
        'network' => '',
        _ => s.printerDeviceName,
      };

  bool _addressDirty(PosStore s) {
    if (_mode == 'network') {
      final cur = parseHostPort(s.printerAddress);
      return cur == null || cur.host != _host.text.trim() || cur.port != _portValue;
    }
    return _draftAddress(s) != s.printerAddress;
  }

  PrinterConfig _draft(PosStore s) => PrinterConfig(
        mode: _mode,
        address: _draftAddress(s),
        deviceName: _draftDeviceName(s),
        queue: _mode == 'windows' ? _printer : '',
        paperWidthMm: _paper,
        autoCut: _autoCut,
      );

  bool get _modeSupported => switch (_mode) {
        'windows' => PrinterConfig.windowsRawSupported,
        'bluetooth' => PrinterConfig.bluetoothSupported,
        _ => true,
      };

  /// ESC/POS mode chosen and usable on this device.
  bool get _escMode => _escModes.contains(_mode) && _modeSupported;

  /// Thai reason the printer choice can't be used yet (null = OK).
  String? _printerSetupError() {
    switch (_mode) {
      case 'windows':
        if (!PrinterConfig.windowsRawSupported) return 'เครื่องพิมพ์ USB แบบนี้ใช้ได้เฉพาะบน Windows — เลือกชนิดอื่น';
        if (_printer.isEmpty) return 'เลือกเครื่องพิมพ์ USB จากรายการก่อน';
      case 'network':
        final hostErr = _hostError(_host.text);
        if (hostErr != null) return hostErr;
        final p = _portValue;
        if (p == null || p < 1 || p > 65535) return 'พอร์ตต้องอยู่ระหว่าง 1–65535';
        if (parseHostPort(_netAddress) == null) return 'IP หรือชื่อเครื่องพิมพ์ไม่ถูกต้อง';
      case 'bluetooth':
        if (!PrinterConfig.bluetoothSupported) return 'เครื่องพิมพ์บลูทูธใช้ได้บน Android และ iOS — เลือกชนิดอื่น';
        if (_btMac.isEmpty) return 'เลือกเครื่องพิมพ์บลูทูธจากรายการก่อน';
    }
    return null;
  }

  bool _opsDirty(PosStore s) => _requireShift != s.requireShift || _kitchen != s.kitchenEnabled || _sound != s.soundEnabled;

  bool _serverDirty(PosStore s) =>
      _baseUrl.text.trim() != s.serverBaseUrl || _productKey.text.trim() != s.productKey || _apiKey.text.trim().isNotEmpty;

  // ───────────────────────── saves ─────────────────────────

  void _saveShop() {
    if (!(_shopForm.currentState?.validate() ?? false)) return;
    AppScope.read(context).updateSettings(
      shop: _shop.text,
      branchName: _branch.text,
      phone: _phone.text,
      address: _address.text,
      taxNumber: _taxId.text,
    );
    setState(() {});
    nvToast(context, 'บันทึกข้อมูลร้านแล้ว', kind: NvToastKind.success);
  }

  void _savePayment() {
    if (!(_payForm.currentState?.validate() ?? false)) return;
    final store = AppScope.read(context);
    final rate = _parseRate(_vatRate.text) ?? _rateHundredths(store.vatRate);
    store.updateSettings(
      promptPay: _promptPay.text,
      vatOn: _vatOn,
      vat: rate / 10000,
      vatIncluded: _vatIncl,
    );
    setState(() {});
    nvToast(context, 'บันทึกการรับชำระและ VAT แล้ว', kind: NvToastKind.success);
  }

  void _saveReceipt() {
    if (!(_receiptForm.currentState?.validate() ?? false)) return;
    final err = _printerSetupError();
    if (err != null) {
      nvToast(context, err, kind: NvToastKind.warning);
      return;
    }
    final store = AppScope.read(context);
    store.updateSettings(
      footer: _footer.text,
      paperWidth: _paper,
      printer: _printer,
      autoPrint: _autoPrint,
      printMode: _mode,
      printAddress: _draftAddress(store),
      printDeviceName: _draftDeviceName(store),
      autoCut: _autoCut,
      drawerAfterCash: _drawerOnCash,
    );
    setState(() {});
    nvToast(context, 'บันทึกการตั้งค่าใบเสร็จและเครื่องพิมพ์แล้ว', kind: NvToastKind.success);
  }

  void _saveOps() {
    AppScope.read(context).updateSettings(shiftRequired: _requireShift, kitchen: _kitchen, sound: _sound);
    setState(() {});
    nvToast(context, 'บันทึกการทำงานแล้ว', kind: NvToastKind.success);
  }

  // ───────────────────────── printer ─────────────────────────

  Future<void> _loadPrinters() async {
    if (_loadingPrinters) return;
    setState(() => _loadingPrinters = true);
    await _fetchPrinters();
  }

  Future<void> _fetchPrinters() async {
    final list = await PrintService.printers();
    if (!mounted) return;
    setState(() {
      _printers = list.where((p) => p.trim().isNotEmpty).toSet().toList(); // dropdown values must be unique
      _loadingPrinters = false;
    });
  }

  Future<void> _testPrint() async {
    if (_testing) return;
    final store = AppScope.read(context);
    final setupError = _printerSetupError();
    if (setupError != null) {
      nvToast(context, setupError, kind: NvToastKind.warning);
      return;
    }
    final hw = _draft(store);
    final sample = Order(
      id: 'TEST',
      createdAt: DateTime.now(),
      lines: [
        OrderLine(name: 'ทดสอบเครื่องพิมพ์ (ไม่ใช่รายการขาย)', code: 'TEST', note: 'ตรวจความคมชัด ภาษาไทย และบาร์โค้ด', qty: 1, price: 1, hue: 40),
      ],
      subtotal: 1,
      discount: 0,
      tax: 0,
      total: 1,
      method: PaymentMethod.cash,
      type: OrderType.takeaway,
      cashier: store.actorName,
      cashReceived: 1,
      prep: PrepStatus.served,
    );
    final footer = _footer.text.trim();
    final shop = ShopInfo(
      name: store.shopName,
      branch: store.branch,
      phone: store.shopPhone,
      address: store.shopAddress,
      taxId: store.taxId,
      terminalId: store.terminalId,
      footer: '*** ใบทดสอบการพิมพ์ — ไม่ใช่ใบเสร็จรับเงิน ***${footer.isEmpty ? '' : '\n$footer'}',
      vatEnabled: false, // never print a test as a tax document
    );
    setState(() => _testing = true);
    try {
      final res = await PrintService.printDoc(
        context,
        ReceiptDoc(order: sample, shop: shop, narrow: _paper == 58),
        jobName: 'ทดสอบเครื่องพิมพ์',
        medium: rollMedium(_paper),
        printerName: _printer,
        precache: ReceiptDoc.precache,
        hardware: hw, // the unsaved choice in this form (system → driver path)
      );
      if (!mounted) return;
      nvToast(context, res.message, kind: res.ok ? NvToastKind.success : NvToastKind.warning);
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  /// Validate the draft for an ESC/POS test; toasts and returns null when not ready.
  PrinterConfig? _escDraftOrToast() {
    final err = _escMode ? _printerSetupError() : 'เลือกชนิดเครื่องพิมพ์ USB / LAN / บลูทูธ ก่อนทดสอบ';
    if (err != null) {
      nvToast(context, err, kind: NvToastKind.warning);
      return null;
    }
    return _draft(AppScope.read(context));
  }

  Future<void> _testConnection() async {
    if (_testingConn) return;
    final cfg = _escDraftOrToast();
    if (cfg == null) return;
    setState(() => _testingConn = true);
    try {
      await PrinterHub.instance.testConnection(config: cfg);
      if (!mounted) return;
      nvToast(context, 'เชื่อมต่อ ${cfg.label} สำเร็จ', kind: NvToastKind.success);
    } on PrinterException catch (e) {
      if (mounted) nvToast(context, e.message, kind: NvToastKind.error);
    } catch (e) {
      if (mounted) nvToast(context, 'เชื่อมต่อไม่สำเร็จ: $e', kind: NvToastKind.error);
    } finally {
      if (mounted) setState(() => _testingConn = false);
    }
  }

  Future<void> _testDrawer() async {
    if (_testingDrawer) return;
    final cfg = _escDraftOrToast();
    if (cfg == null) return;
    setState(() => _testingDrawer = true);
    try {
      await PrinterHub.instance.openDrawer(config: cfg);
      if (!mounted) return;
      final store = AppScope.read(context);
      store.log('drawer.open', 'ทดสอบเปิดลิ้นชักจากหน้าตั้งค่า (${cfg.label})');
      store.flush().ignore();
      nvToast(context, 'ส่งคำสั่งเปิดลิ้นชักไปที่ ${cfg.label} แล้ว', kind: NvToastKind.success);
    } on PrinterException catch (e) {
      if (mounted) nvToast(context, e.message, kind: NvToastKind.error);
    } catch (e) {
      if (mounted) nvToast(context, 'เปิดลิ้นชักไม่สำเร็จ: $e', kind: NvToastKind.error);
    } finally {
      if (mounted) setState(() => _testingDrawer = false);
    }
  }

  Future<void> _loadBt() async {
    if (_btLoading || !PrinterConfig.bluetoothSupported) return;
    setState(() {
      _btLoading = true;
      _btError = null;
    });
    try {
      final list = await PrinterHub.instance.pairedBluetooth();
      if (!mounted) return;
      setState(() {
        _btDevices = list;
        _btLoadedOnce = true;
      });
    } on PrinterException catch (e) {
      if (mounted) setState(() => _btError = e.message);
    } catch (e) {
      if (mounted) setState(() => _btError = 'อ่านรายการบลูทูธไม่ได้: $e');
    } finally {
      if (mounted) setState(() => _btLoading = false);
    }
  }

  void _setMode(String m) {
    if (m == _mode) return;
    setState(() => _mode = m);
    if (m == 'bluetooth' && PrinterConfig.bluetoothSupported && !_btLoadedOnce) _loadBt();
    if (m == 'windows' && _printers.isEmpty && !_loadingPrinters) _loadPrinters();
  }

  // ───────────────────────── server pairing (original flow) ─────────────────────────

  Future<void> _pair() async {
    if (_pairing) return;
    if (!(_serverForm.currentState?.validate() ?? false)) return;
    final store = AppScope.read(context);
    setState(() => _pairing = true);
    try {
      store.updateServerConfig(baseUrl: _baseUrl.text, productKey: _productKey.text);
      final apiKey = _apiKey.text.trim();
      if (apiKey.isEmpty) {
        nvToast(
          context,
          store.auth?.isServerPaired == true ? 'บันทึกการตั้งค่าเซิร์ฟเวอร์แล้ว' : 'บันทึกแล้ว — ใส่ API Key เพื่อจับคู่เครื่อง',
          kind: NvToastKind.success,
        );
        return;
      }
      final auth = store.auth;
      if (auth == null) {
        nvToast(context, 'ระบบเชื่อมต่อเซิร์ฟเวอร์ยังไม่พร้อมในเครื่องนี้', kind: NvToastKind.error);
        return;
      }
      final s = await auth.pairTerminal(apiKey: apiKey);
      store.log('server.pair', s.name);
      store.flush().ignore();
      _apiKey.clear();
      store.sync?.syncNow();
      if (!mounted) return;
      nvToast(context, 'จับคู่สำเร็จ: ${s.name}', kind: NvToastKind.success);
    } on ApiException catch (e) {
      if (mounted) nvToast(context, 'จับคู่ไม่สำเร็จ: ${e.message}', kind: NvToastKind.error);
    } catch (_) {
      if (mounted) nvToast(context, 'จับคู่ไม่สำเร็จ — ตรวจการเชื่อมต่อแล้วลองใหม่', kind: NvToastKind.error);
    } finally {
      if (mounted) setState(() => _pairing = false);
    }
  }

  Future<void> _syncNow() async {
    final sync = AppScope.read(context).sync;
    if (sync == null || _syncing) return;
    setState(() => _syncing = true);
    try {
      await sync.syncNow();
      if (!mounted) return;
      final ok = sync.state == SyncState.idle;
      nvToast(context, ok ? 'ซิงก์สำเร็จ' : (sync.message ?? sync.state.label), kind: ok ? NvToastKind.success : NvToastKind.warning);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _unpair() async {
    final store = AppScope.read(context);
    final pending = store.sync?.pendingCount ?? 0;
    final ok = await showNvConfirm(
      context,
      title: 'เลิกจับคู่เครื่องนี้?',
      message: 'ลบคีย์ API ออกจากเครื่อง — ยังขายแบบออฟไลน์ได้ แต่บิลจะไม่ถูกส่งขึ้นเซิร์ฟเวอร์จนกว่าจะจับคู่ใหม่'
          '${pending > 0 ? ' (บิลค้างส่ง $pending บิลจะรออยู่ในคิว)' : ''}',
      confirmLabel: 'เลิกจับคู่',
    );
    if (!ok || !mounted) return;
    final mgr = await showManagerPin(context, reason: 'เลิกจับคู่เครื่องกับเซิร์ฟเวอร์ Thai Prompt', alwaysAsk: true);
    if (mgr == null || !mounted) return;
    try {
      await store.auth?.signOut();
      store.log('server.unpair', 'อนุมัติโดย ${mgr.name}');
      store.flush().ignore();
      store.sync?.syncNow(); // settles the pill to "not paired"
      if (!mounted) return;
      setState(() {});
      nvToast(context, 'เลิกจับคู่แล้ว — เครื่องทำงานแบบออฟไลน์', kind: NvToastKind.success);
    } catch (_) {
      if (mounted) nvToast(context, 'เลิกจับคู่ไม่สำเร็จ ลองใหม่อีกครั้ง', kind: NvToastKind.error);
    }
  }

  Future<void> _copyDeviceId(String id) async {
    await Clipboard.setData(ClipboardData(text: id));
    if (!mounted) return;
    nvToast(context, 'คัดลอก Device ID แล้ว', kind: NvToastKind.success);
  }

  // ───────────────────────── updater (UpdateWatcher) ─────────────────────────

  Future<void> _check() async {
    final w = UpdateWatcher.instance;
    if (w.checking || w.installing) return;
    setState(() => _checkMsg = null);
    final info = await w.check();
    if (!mounted) return;
    setState(() {
      if (info == null) {
        _checkMsg = 'ตรวจสอบไม่ได้ — ตรวจอินเทอร์เน็ต หรือยังไม่มีไฟล์ติดตั้งในรุ่นล่าสุด';
      } else if (!info.hasUpdate) {
        _checkMsg = 'ใช้เวอร์ชันล่าสุดแล้ว (v${info.currentVersion})';
      }
    });
  }

  void _setAutoUpdate(bool v) {
    AppScope.read(context).updateSettings(autoUpdates: v);
    nvToast(context, v ? 'เปิดอัปเดตอัตโนมัติแล้ว' : 'ปิดอัปเดตอัตโนมัติแล้ว', kind: NvToastKind.success);
  }

  // ───────────────────────── build ─────────────────────────

  void _jump(_Sec s) {
    final ctx = _secKeys[s]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx, duration: Nv.med, curve: Nv.ease, alignment: 0.02);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final dirty = <_Sec, bool>{
      _Sec.shop: _shopDirty(store),
      _Sec.payment: _payDirty(store),
      _Sec.receipt: _receiptDirty(store),
      _Sec.ops: _opsDirty(store),
      _Sec.server: _serverDirty(store),
    };

    final sections = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _section(_Sec.shop, 'ชื่อร้าน สาขา และข้อมูลบนหัวใบเสร็จ', dirty[_Sec.shop]!, _shopBody(), onSave: _saveShop, onReset: () => setState(() => _resetShop(store))),
        _section(_Sec.payment, 'พร้อมเพย์และภาษีมูลค่าเพิ่ม', dirty[_Sec.payment]!, _paymentBody(store),
            onSave: _savePayment, onReset: () => setState(() => _resetPayment(store))),
        _section(_Sec.receipt, 'ท้ายใบเสร็จ ขนาดกระดาษ เครื่องพิมพ์ และลิ้นชักเงินสด', dirty[_Sec.receipt]!, _receiptBody(store),
            onSave: _saveReceipt, onReset: () => setState(() => _resetReceipt(store))),
        _section(_Sec.display, 'แสดงรายการ ยอดชำระ QR และคำขอบคุณ บนจอที่หันหาลูกค้า', false, const SecondScreenSettingsCard(framed: false)),
        _section(_Sec.ops, 'กะการขาย ครัว และเสียง', dirty[_Sec.ops]!, _opsBody(), onSave: _saveOps, onReset: () => setState(() => _resetOps(store))),
        _section(_Sec.server, 'จับคู่เครื่องเพื่อส่งบิลและดึงสินค้าจากร้านออนไลน์', dirty[_Sec.server]!, _serverBody(store)),
        _section(_Sec.update, 'ตรวจและติดตั้งเวอร์ชันใหม่', false, _updateBody(store)),
        _section(_Sec.about, 'เวอร์ชันและผู้พัฒนา', false, _aboutBody()),
      ],
    );

    return NvScaffold(
      title: 'ตั้งค่า',
      eyebrow: 'ร้าน · ใบเสร็จ · เครื่องพิมพ์ · เซิร์ฟเวอร์',
      subtitle: '${store.shopName} · ${store.branch}',
      art: 'settings',
      body: LayoutBuilder(builder: (context, c) {
        final scroller = SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.only(bottom: 32),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 980), child: sections),
          ),
        );
        if (c.maxWidth < 1100) return scroller;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 236,
              child: NvSheet(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final s in _Sec.values)
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _jump(s),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Row(
                            children: [
                              NvArt.icon(s.art, size: 30),
                              const SizedBox(width: 10),
                              Expanded(child: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(13.5, weight: FontWeight.w600))),
                              if (dirty[s] ?? false)
                                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Nv.amber, shape: BoxShape.circle)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: scroller),
          ],
        );
      }),
    );
  }

  Widget _section(_Sec s, String subtitle, bool dirty, Widget body, {VoidCallback? onSave, VoidCallback? onReset}) {
    return Padding(
      key: _secKeys[s],
      padding: const EdgeInsets.only(bottom: 16),
      child: NvSheet(
        goldEdge: dirty,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                NvArt.icon(s.art, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.title, style: Nv.display(19)),
                      Text(subtitle, style: Nv.ui(12.5, color: Nv.ink3)),
                    ],
                  ),
                ),
                if (dirty) const NvBadge('ยังไม่บันทึก', tint: NvTint.amber),
              ],
            ),
            const SizedBox(height: 16),
            body,
            if (onSave != null) ...[
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (dirty && onReset != null) NvButton.soft('คืนค่าเดิม', icon: NvIcons.rotate, size: NvButtonSize.sm, onPressed: onReset),
                  NvButton.gold('บันทึก', icon: NvIcons.floppy, size: NvButtonSize.sm, onPressed: dirty ? onSave : null),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Two fields side by side on wide sections, stacked on narrow ones.
  Widget _pair2(Widget a, Widget b) => LayoutBuilder(builder: (context, c) {
        if (c.maxWidth < 560) return Column(children: [a, const SizedBox(height: 12), b]);
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)]);
      });

  void _touch(String _) => setState(() {});

  Widget _switchRow(String title, String subtitle, bool value, ValueChanged<bool>? onChanged) => SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        value: value,
        onChanged: onChanged,
        title: Text(title, style: Nv.ui(14, weight: FontWeight.w600, color: onChanged == null ? Nv.ink4 : Nv.ink)),
        subtitle: Text(subtitle, style: Nv.ui(12, color: Nv.ink3, height: 1.35)),
      );

  // ── ร้านค้า ──
  Widget _shopBody() => Form(
        key: _shopForm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _pair2(
              NvField(
                label: 'ชื่อร้าน *',
                controller: _shop,
                icon: NvIcons.store,
                onChanged: _touch,
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return 'กรุณาใส่ชื่อร้าน';
                  return t.length > 60 ? 'ชื่อร้านยาวเกิน 60 ตัวอักษร' : null;
                },
              ),
              NvField(
                label: 'ชื่อสาขา',
                controller: _branch,
                icon: NvIcons.branch,
                onChanged: _touch,
                validator: (v) => (v ?? '').trim().length > 60 ? 'ยาวเกิน 60 ตัวอักษร' : null,
              ),
            ),
            const SizedBox(height: 12),
            _pair2(
              NvField(
                label: 'เบอร์โทรร้าน',
                controller: _phone,
                icon: NvIcons.phone,
                keyboard: TextInputType.phone,
                formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                onChanged: _touch,
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return null;
                  return (t.length == 9 || t.length == 10) && t.startsWith('0') ? null : 'เบอร์โทร 9–10 หลัก ขึ้นต้นด้วย 0';
                },
              ),
              NvField(
                label: 'เลขประจำตัวผู้เสียภาษี (13 หลัก)',
                controller: _taxId,
                icon: NvIcons.tax,
                keyboard: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(13)],
                onChanged: _touch,
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return null;
                  if (t.length != 13) return 'ต้องมี 13 หลัก (ตอนนี้ ${t.length} หลัก)';
                  return _validTaxId(t) ? null : 'เลขไม่ถูกต้อง (หลักตรวจสอบไม่ตรง)';
                },
              ),
            ),
            const SizedBox(height: 12),
            NvField(
              label: 'ที่อยู่ร้าน (พิมพ์บนใบเสร็จและใบกำกับภาษี)',
              controller: _address,
              icon: NvIcons.location,
              maxLines: 2,
              onChanged: _touch,
              validator: (v) => (v ?? '').trim().length > 200 ? 'ยาวเกิน 200 ตัวอักษร' : null,
            ),
          ],
        ),
      );

  // ── การรับชำระ ──
  Widget _paymentBody(PosStore store) {
    final ppDigits = _promptPay.text.replaceAll(RegExp(r'\D'), '');
    final ppValid = ppDigits.isNotEmpty && PromptPay.isValidId(ppDigits);
    final rate = _parseRate(_vatRate.text);
    final r = (rate ?? 0) / 10000;
    final exampleIncl = r <= 0 ? 0.0 : 100 * r / (1 + r);
    final qr = ppValid
        ? Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Nv.gold500.withValues(alpha: 0.5))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QrImageView(
                  data: PromptPay.payload(ppDigits, amountBaht: 1),
                  size: 148,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Nv.navy900),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Nv.navy900),
                ),
                const SizedBox(height: 6),
                Text('ทดสอบ ฿1 · ${PromptPay.mask(ppDigits)}', style: Nv.money(11.5, color: Nv.ink2, weight: FontWeight.w600)),
              ],
            ),
          )
        : Container(
            width: 172,
            height: 196,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Nv.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: Nv.line)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(NvIcons.qrcode, size: 34, color: Nv.ink4),
                const SizedBox(height: 10),
                Text(ppDigits.isEmpty ? 'ใส่รหัสพร้อมเพย์เพื่อดู QR ทดสอบ' : 'รหัสยังไม่ถูกต้อง',
                    textAlign: TextAlign.center, style: Nv.ui(12, color: Nv.ink3)),
              ],
            ),
          );

    final fields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NvField(
          label: 'รหัสพร้อมเพย์ของร้าน',
          controller: _promptPay,
          icon: NvIcons.qrcode,
          hint: 'มือถือ 10 หลัก · เลขบัตร/ภาษี 13 หลัก · e-Wallet 15 หลัก',
          keyboard: TextInputType.number,
          formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(15)],
          onChanged: _touch,
          validator: (v) {
            final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
            if (d.isEmpty) return null;
            return PromptPay.isValidId(d) ? null : 'รหัสไม่ถูกต้อง (มือถือ 10 หลักขึ้นต้น 0 / 13 / 15 หลัก)';
          },
        ),
        const SizedBox(height: 6),
        Text(
          ppDigits.isEmpty
              ? 'ไม่ใส่ = หน้าชำระเงินจะไม่แสดง QR พร้อมเพย์'
              : 'สแกน QR ด้วยแอปธนาคารเพื่อตรวจว่าชื่อบัญชีถูกต้อง (ไม่ต้องกดโอนจริง)',
          style: Nv.ui(12, color: Nv.ink3, height: 1.4),
        ),
        const SizedBox(height: 10),
        _switchRow('คิดภาษีมูลค่าเพิ่ม (VAT)', 'ปิดถ้าร้านยังไม่จดทะเบียน VAT — ใบเสร็จจะไม่แสดงเป็นใบกำกับภาษีอย่างย่อ', _vatOn,
            (v) => setState(() => _vatOn = v)),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 150,
              child: NvField(
                label: 'อัตรา VAT',
                controller: _vatRate,
                icon: NvIcons.percent,
                suffixText: '%',
                enabled: _vatOn,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')), LengthLimitingTextInputFormatter(5)],
                onChanged: _touch,
                validator: (v) {
                  if (!_vatOn) return null;
                  final h = _parseRate(v ?? '');
                  if (h == null) return 'ใส่ตัวเลข';
                  return h <= 0 || h > 3000 ? '0–30%' : null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _switchRow(
                'ราคาสินค้ารวม VAT แล้ว',
                _vatOn && rate != null && rate > 0
                    ? (_vatIncl
                        ? 'ราคา ฿100 = สินค้า ฿${(100 - exampleIncl).toStringAsFixed(2)} + VAT ฿${exampleIncl.toStringAsFixed(2)}'
                        : 'ราคา ฿100 + VAT ฿${_rateText(rate)} = จ่าย ฿${(100 + rate / 100).toStringAsFixed(2)}')
                    : 'เปิด VAT ก่อนจึงเลือกได้',
                _vatIncl,
                _vatOn ? (v) => setState(() => _vatIncl = v) : null,
              ),
            ),
          ],
        ),
      ],
    );

    return Form(
      key: _payForm,
      child: LayoutBuilder(builder: (context, c) {
        if (c.maxWidth < 620) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [fields, const SizedBox(height: 14), Center(child: qr)]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: fields), const SizedBox(width: 18), qr]);
      }),
    );
  }

  // ── ใบเสร็จและเครื่องพิมพ์ ──
  Widget _caption(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(text, style: Nv.ui(12.5, color: Nv.ink2, weight: FontWeight.w600)),
      );

  Widget _hint(String text, {Color? color}) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(text, style: Nv.ui(12, color: color ?? Nv.ink3, height: 1.4)),
      );

  List<(String, String, IconData)> get _modeOptions => [
        ('system', 'ระบบ (ไดรเวอร์/หน้าต่างพิมพ์)', NvIcons.print),
        if (PrinterConfig.windowsRawSupported || _mode == 'windows') ('windows', 'USB บน Windows', NvIcons.link),
        ('network', 'LAN / Wi-Fi', NvIcons.wifi),
        if (PrinterConfig.bluetoothSupported || _mode == 'bluetooth') ('bluetooth', 'บลูทูธ', NvIcons.signal),
      ];

  String get _modeHint {
    final text = switch (_mode) {
      'windows' => 'ส่งคำสั่ง ESC/POS ตรงเข้าคิวเครื่องพิมพ์ของ Windows (เครื่องพิมพ์ USB) — ภาษาไทยคมชัด ตัดกระดาษและเปิดลิ้นชักได้ '
          '· ต้องติดตั้งไดรเวอร์ของเครื่องพิมพ์ หรือ "Generic / Text Only" บนพอร์ต USB ก่อน',
      'network' => 'เครื่องพิมพ์ที่ต่อสาย LAN หรือ Wi-Fi (ESC/POS พอร์ต 9100) — ควรตั้ง IP ของเครื่องพิมพ์ให้คงที่',
      'bluetooth' => 'เครื่องพิมพ์บลูทูธที่จับคู่ (pair) กับเครื่องนี้แล้ว รวมถึงเครื่องพิมพ์ในตัวของ Sunmi',
      _ => 'พิมพ์เป็น PDF ผ่านไดรเวอร์ของระบบ — ใช้ได้กับทุกเครื่องพิมพ์ แต่การตัดกระดาษ/เปิดลิ้นชักขึ้นกับไดรเวอร์',
    };
    return _modeSupported ? text : '$text · เครื่องนี้ไม่รองรับชนิดนี้ กรุณาเลือกชนิดอื่น';
  }

  Widget _queueDropdown() {
    final windows = _mode == 'windows';
    final options = <String>['', ..._printers];
    if (_printer.isNotEmpty && !options.contains(_printer)) options.add(_printer);
    String label(String p) {
      if (p.isEmpty) return windows ? 'เลือกเครื่องพิมพ์…' : 'ถามทุกครั้ง (หน้าต่างพิมพ์ของระบบ)';
      return _printers.contains(p) ? p : '$p (ไม่พบในเครื่องตอนนี้)';
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _caption(windows ? 'เครื่องพิมพ์ USB (คิวเครื่องพิมพ์ของ Windows)' : 'เครื่องพิมพ์ใบเสร็จ'),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Nv.paper,
                    borderRadius: BorderRadius.circular(Nv.rSm),
                    border: Border.all(color: windows && _printer.isEmpty ? Nv.amber : Nv.line),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _printer,
                      isExpanded: true,
                      icon: const Icon(NvIcons.chevronDown, size: 12, color: Nv.ink3),
                      borderRadius: BorderRadius.circular(Nv.rSm),
                      dropdownColor: Nv.ivory2,
                      style: Nv.ui(14, color: Nv.ink),
                      items: [
                        for (final p in options)
                          DropdownMenuItem(value: p, child: Text(label(p), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (v) => setState(() => _printer = v ?? ''),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _loadingPrinters
                  ? const SizedBox(width: 42, height: 42, child: Padding(padding: EdgeInsets.all(11), child: CircularProgressIndicator(strokeWidth: 2)))
                  : NvIconButton(NvIcons.sync, tooltip: 'ค้นหาเครื่องพิมพ์อีกครั้ง', onPressed: _loadPrinters),
            ],
          ),
        ],
      ),
    );
  }

  Widget _networkFields() {
    final host = NvField(
      label: 'IP หรือชื่อเครื่องพิมพ์ *',
      controller: _host,
      icon: NvIcons.wifi,
      hint: 'เช่น 192.168.1.100',
      keyboard: TextInputType.url,
      onChanged: _touch,
      validator: (v) => _mode == 'network' ? _hostError(v ?? '') : null,
    );
    final port = NvField(
      label: 'พอร์ต',
      controller: _port,
      icon: NvIcons.link,
      keyboard: TextInputType.number,
      formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
      onChanged: _touch,
      validator: (v) {
        if (_mode != 'network') return null;
        final p = int.tryParse((v ?? '').trim());
        return p == null || p < 1 || p > 65535 ? '1–65535' : null;
      },
    );
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 460) return Column(children: [host, const SizedBox(height: 12), port]);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Expanded(child: host), const SizedBox(width: 12), SizedBox(width: 150, child: port)],
      );
    });
  }

  Widget _bluetoothPanel() {
    if (!PrinterConfig.bluetoothSupported) {
      return _hint('เครื่องนี้ไม่รองรับเครื่องพิมพ์บลูทูธ (ใช้ได้บน Android และ iOS) — เลือกชนิดอื่น', color: Nv.lacquer);
    }
    final known = {for (final d in _btDevices) d.mac.toUpperCase()};
    final devices = <({String name, String mac})>[
      if (_btMac.isNotEmpty && !known.contains(_btMac.toUpperCase())) (name: _btName.isEmpty ? _btMac : _btName, mac: _btMac),
      ..._btDevices,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _caption('เครื่องพิมพ์บลูทูธที่จับคู่ไว้')),
            _btLoading
                ? const SizedBox(width: 42, height: 42, child: Padding(padding: EdgeInsets.all(11), child: CircularProgressIndicator(strokeWidth: 2)))
                : NvIconButton(NvIcons.sync, tooltip: 'ค้นหาอุปกรณ์บลูทูธอีกครั้ง', onPressed: _loadBt),
          ],
        ),
        if (_btError != null)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Nv.amberTint,
              borderRadius: BorderRadius.circular(Nv.rSm),
              border: Border.all(color: Nv.amber.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(NvIcons.warning, size: 14, color: Nv.amber),
                const SizedBox(width: 8),
                Expanded(child: Text(_btError!, style: Nv.ui(12.5, color: Nv.ink, height: 1.4))),
              ],
            ),
          ),
        if (devices.isEmpty && !_btLoading && _btError == null)
          Text(
            _btLoadedOnce
                ? 'ไม่พบอุปกรณ์ที่จับคู่ไว้ — จับคู่เครื่องพิมพ์ในการตั้งค่าบลูทูธของเครื่องก่อน แล้วกดค้นหาอีกครั้ง'
                : 'กดปุ่มค้นหาเพื่อแสดงรายการเครื่องพิมพ์บลูทูธ',
            style: Nv.ui(12.5, color: Nv.ink3),
          ),
        for (final d in devices)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _btTile(d, missing: !known.contains(d.mac.toUpperCase())),
          ),
        _hint('เครื่อง Sunmi: เลือก "${BluetoothPrinter.sunmiInnerPrinterName}" (${BluetoothPrinter.sunmiInnerPrinterMac}) '
            '= เครื่องพิมพ์ในตัว · iOS แสดงเครื่องที่อยู่ใกล้ (ค้นหาประมาณ 5 วินาที)'),
      ],
    );
  }

  Widget _btTile(({String name, String mac}) d, {required bool missing}) {
    final selected = d.mac.toUpperCase() == _btMac.toUpperCase();
    final sunmi = d.mac.toUpperCase() == BluetoothPrinter.sunmiInnerPrinterMac || d.name == BluetoothPrinter.sunmiInnerPrinterName;
    return NvSheet(
      selected: selected,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: () => setState(() {
        _btMac = d.mac;
        _btName = d.name;
      }),
      child: Row(
        children: [
          Icon(sunmi ? NvIcons.print : NvIcons.signal, size: 16, color: selected ? Nv.goldInk : Nv.ink3),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(d.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(14, weight: FontWeight.w600)),
                Text(missing ? '${d.mac} · ไม่พบในรายการตอนนี้' : d.mac,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Nv.money(11.5, color: missing ? Nv.amber : Nv.ink3, weight: FontWeight.w500)),
              ],
            ),
          ),
          if (sunmi) ...[const SizedBox(width: 8), const NvBadge('เครื่องพิมพ์ในตัว Sunmi', tint: NvTint.sapphire)],
          if (selected) ...[const SizedBox(width: 8), const Icon(NvIcons.checkCircle, size: 16, color: Nv.jade)],
        ],
      ),
    );
  }

  Widget _receiptBody(PosStore store) {
    final esc = _escMode;
    return Form(
      key: _receiptForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NvField(
            label: 'ข้อความท้ายใบเสร็จ',
            controller: _footer,
            icon: NvIcons.comment,
            maxLines: 2,
            onChanged: _touch,
            validator: (v) => (v ?? '').trim().length > 120 ? 'ยาวเกิน 120 ตัวอักษร' : null,
          ),
          const SizedBox(height: 14),
          _caption('ชนิดเครื่องพิมพ์'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (value, text, icon) in _modeOptions)
                NvChip(text, icon: icon, selected: _mode == value, onTap: () => _setMode(value)),
            ],
          ),
          _hint(_modeHint, color: _modeSupported ? null : Nv.lacquer),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _caption('ขนาดกระดาษ'),
                  NvSegmented<int>(
                    options: const [(58, '58 มม.'), (80, '80 มม.')],
                    value: _paper,
                    onChanged: (v) => setState(() => _paper = v),
                  ),
                ],
              ),
              if (_mode == 'system' || (_mode == 'windows' && PrinterConfig.windowsRawSupported)) _queueDropdown(),
            ],
          ),
          if (_mode == 'system' && !_loadingPrinters && _printers.isEmpty)
            _hint('ระบบนี้ไม่ส่งรายชื่อเครื่องพิมพ์มาให้ — จะเปิดหน้าต่างพิมพ์ของระบบทุกครั้ง'),
          if (_mode == 'windows' && PrinterConfig.windowsRawSupported && !_loadingPrinters && _printers.isEmpty)
            _hint('ไม่พบเครื่องพิมพ์ใน Windows — ติดตั้งไดรเวอร์ของเครื่องพิมพ์ (หรือ Generic / Text Only บนพอร์ต USB) แล้วกดค้นหาอีกครั้ง',
                color: Nv.amber),
          if (_mode == 'network') ...[const SizedBox(height: 14), _networkFields()],
          if (_mode == 'bluetooth') ...[const SizedBox(height: 14), _bluetoothPanel()],
          const SizedBox(height: 8),
          _switchRow('พิมพ์ใบเสร็จอัตโนมัติหลังชำระเงิน', 'ส่งไปที่เครื่องพิมพ์ที่เลือกทันทีโดยไม่ต้องกดพิมพ์', _autoPrint,
              (v) => setState(() => _autoPrint = v)),
          _switchRow(
            'ตัดกระดาษอัตโนมัติ',
            esc ? 'ตัดกระดาษหลังพิมพ์ทุกใบ (เครื่องพิมพ์ที่มีมีดตัด)' : 'ใช้ได้เมื่อเลือก USB / LAN / บลูทูธ — แบบระบบให้ตั้งในไดรเวอร์',
            _autoCut,
            esc ? (v) => setState(() => _autoCut = v) : null,
          ),
          _switchRow(
            'เปิดลิ้นชักหลังรับเงินสด',
            esc
                ? 'ส่งสัญญาณเปิดลิ้นชักที่ต่อกับเครื่องพิมพ์ (สาย RJ11/RJ12) ทุกครั้งที่รับชำระด้วยเงินสด'
                : 'ใช้ได้เมื่อเลือก USB / LAN / บลูทูธ (ลิ้นชักต่อกับเครื่องพิมพ์ใบเสร็จ)',
            _drawerOnCash,
            esc ? (v) => setState(() => _drawerOnCash = v) : null,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              NvButton.navy('พิมพ์ทดสอบ', icon: NvIcons.print, size: NvButtonSize.sm, loading: _testing, onPressed: _testPrint),
              if (_escModes.contains(_mode)) ...[
                NvButton.soft('ทดสอบการเชื่อมต่อ',
                    icon: NvIcons.link, size: NvButtonSize.sm, loading: _testingConn, onPressed: esc && !_testingConn ? _testConnection : null),
                NvButton.soft('ทดสอบเปิดลิ้นชัก',
                    icon: NvIcons.drawer, size: NvButtonSize.sm, loading: _testingDrawer, onPressed: esc && !_testingDrawer ? _testDrawer : null),
              ],
            ],
          ),
          _hint('ทดสอบด้วยค่าที่เลือกด้านบน (ยังไม่ต้องบันทึก) · พิมพ์เป็นใบทดสอบ ไม่ใช่ใบเสร็จ'),
        ],
      ),
    );
  }

  // ── การทำงาน ──
  Widget _opsBody() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _switchRow('ต้องเปิดกะก่อนขาย', 'บังคับนับเงินทอนตั้งต้นก่อนรับชำระ เพื่อให้ปิดกะและนับเงินได้ถูกต้อง', _requireShift,
              (v) => setState(() => _requireShift = v)),
          _switchRow('ใช้จอครัว (KDS)', 'บิลที่ชำระแล้วและออเดอร์จากโต๊ะจะเข้าคิวครัว — ปิดถ้าร้านไม่มีครัวแยก', _kitchen,
              (v) => setState(() => _kitchen = v)),
          _switchRow('เสียงแจ้งเตือน', 'เสียงเมื่อสแกนสินค้า ออเดอร์ใหม่ และลูกค้าเรียกพนักงาน', _sound, (v) => setState(() => _sound = v)),
        ],
      );

  // ── เซิร์ฟเวอร์ ──
  Widget _serverBody(PosStore store) {
    final listenables = <Listenable>[?store.sync, ?store.auth];
    Widget status() {
      final sync = store.sync;
      final auth = store.auth;
      final paired = auth?.isServerPaired ?? false;
      final st = sync?.state;
      final tint = switch (st) {
        SyncState.idle => NvTint.jade,
        SyncState.syncing => NvTint.sapphire,
        SyncState.offline => NvTint.amber,
        SyncState.error => NvTint.lacquer,
        _ => NvTint.neutral,
      };
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Nv.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: Nv.line)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                NvBadge(paired ? 'จับคู่แล้ว · ${auth?.session?.name ?? ''}' : 'ยังไม่จับคู่', tint: paired ? NvTint.jade : NvTint.amber),
                NvBadge(st?.label ?? 'ไม่มีระบบซิงก์', tint: tint),
                if ((sync?.pendingCount ?? 0) > 0) NvBadge('รอส่ง ${sync!.pendingCount} บิล', tint: NvTint.amber),
              ],
            ),
            const SizedBox(height: 8),
            NvKeyValue('ซิงก์ล่าสุด', sync?.lastSyncAt == null ? 'ยังไม่เคย' : thaiDateTime(sync!.lastSyncAt!), mono: false),
            if (sync?.message != null) NvKeyValue('ข้อความ', sync!.message!, mono: false, valueColor: Nv.lacquerDeep),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('Device ID', style: Nv.ui(13.5, color: Nv.ink3, weight: FontWeight.w500)),
                const SizedBox(width: 12),
                Expanded(
                  child: SelectableText(store.deviceId.isEmpty ? '—' : store.deviceId,
                      textAlign: TextAlign.right, style: Nv.money(12.5, color: Nv.ink, weight: FontWeight.w600)),
                ),
                const SizedBox(width: 6),
                NvIconButton(NvIcons.copy, size: 34, tooltip: 'คัดลอก Device ID', onPressed: store.deviceId.isEmpty ? null : () => _copyDeviceId(store.deviceId)),
              ],
            ),
          ],
        ),
      );
    }

    final paired = store.auth?.isServerPaired ?? false;
    return Form(
      key: _serverForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          listenables.isEmpty ? status() : ListenableBuilder(listenable: Listenable.merge(listenables), builder: (context, _) => status()),
          const SizedBox(height: 14),
          NvField(
            label: 'ที่อยู่เซิร์ฟเวอร์',
            controller: _baseUrl,
            icon: NvIcons.server,
            hint: 'https://main.thaiprompt.online',
            keyboard: TextInputType.url,
            onChanged: _touch,
            validator: (v) => _urlError(v ?? ''),
          ),
          const SizedBox(height: 12),
          _pair2(
            NvField(
              label: 'Product Key',
              controller: _productKey,
              icon: NvIcons.key,
              onChanged: _touch,
              validator: (v) => _apiKey.text.trim().isNotEmpty && (v ?? '').trim().isEmpty ? 'ต้องใส่ Product Key ก่อนจับคู่' : null,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: NvField(
                    label: paired ? 'API Key (ว่างไว้ = ใช้คีย์เดิม)' : 'API Key',
                    controller: _apiKey,
                    icon: NvIcons.lock,
                    obscure: !_showKey,
                    onChanged: _touch,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: NvIconButton(_showKey ? NvIcons.eyeSlash : NvIcons.eye,
                      size: 40, tooltip: _showKey ? 'ซ่อนคีย์' : 'แสดงคีย์', onPressed: () => setState(() => _showKey = !_showKey)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Product Key และ API Key ออกให้จากหลังบ้าน Thai Prompt สำหรับเครื่องนี้ — ลงทะเบียน Device ID ด้านบนในหลังบ้านก่อน · '
            'คีย์ API เก็บใน secure storage ของระบบ ไม่แสดงซ้ำหลังจับคู่',
            style: Nv.ui(12, color: Nv.ink3, height: 1.45),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 10,
            children: [
              if (paired) NvButton.danger('เลิกจับคู่', icon: NvIcons.plugX, size: NvButtonSize.sm, onPressed: _unpair),
              NvButton.soft('ซิงก์ตอนนี้', icon: NvIcons.sync, size: NvButtonSize.sm, loading: _syncing, onPressed: paired && store.sync != null ? _syncNow : null),
              NvButton.gold(_apiKey.text.trim().isEmpty ? 'บันทึกการตั้งค่า' : 'บันทึกและจับคู่',
                  icon: NvIcons.link, size: NvButtonSize.sm, loading: _pairing, onPressed: _pair),
            ],
          ),
        ],
      ),
    );
  }

  // ── อัปเดตแอป ──
  Widget _updateBody(PosStore store) {
    final w = UpdateWatcher.instance;
    return ListenableBuilder(
      listenable: w,
      builder: (context, _) {
        final info = w.available;
        final canInstall = AutoUpdater.canSelfInstall;
        final String status;
        if (w.checking) {
          status = 'กำลังตรวจสอบเวอร์ชันใหม่…';
        } else if (w.installing) {
          status = w.status.isEmpty ? 'กำลังติดตั้งเวอร์ชันใหม่…' : _safeUpdateText(w.status);
        } else if (info != null) {
          status = 'มีอัปเดต: v${info.currentVersion} → v${info.latestVersion}';
        } else {
          status = _checkMsg ?? (w.lastCheck != null ? 'ใช้เวอร์ชันล่าสุดแล้ว (v$_version)' : 'ยังไม่ได้ตรวจสอบ');
        }
        final notes = info == null ? '' : cleanReleaseNotes(info.releaseNotes);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Nv.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: Nv.line)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(info != null ? NvIcons.download : NvIcons.info, size: 15, color: info != null ? Nv.goldInk : Nv.ink3),
                      const SizedBox(width: 10),
                      Expanded(child: Text(status, style: Nv.ui(13.5, color: Nv.ink, weight: FontWeight.w600))),
                    ],
                  ),
                  if (w.installing || w.progress > 0) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(value: w.progress > 0 ? (w.progress / 100).clamp(0.0, 1.0) : null, minHeight: 7),
                    ),
                  ],
                  if (w.error != null) ...[
                    const SizedBox(height: 8),
                    Text(_safeUpdateText(w.error!), style: Nv.ui(12.5, color: Nv.lacquer, weight: FontWeight.w600)),
                  ],
                  if (info != null) ...[
                    const SizedBox(height: 10),
                    NvKeyValue('เผยแพร่เมื่อ', thaiDate(info.publishedAt), mono: false),
                    if (info.sizeBytes > 0) NvKeyValue('ขนาดไฟล์', '${(info.sizeBytes / 1048576).toStringAsFixed(1)} MB'),
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 150),
                        child: SingleChildScrollView(child: Text(notes, style: Nv.ui(12.5, color: Nv.ink2, height: 1.45))),
                      ),
                    ],
                  ],
                  if (w.lastCheck != null) ...[
                    const SizedBox(height: 6),
                    Text('ตรวจล่าสุด ${thaiDateTime(w.lastCheck!)}', style: Nv.ui(11.5, color: Nv.ink4)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            _switchRow(
              'อัปเดตอัตโนมัติเมื่อเครื่องว่าง',
              canInstall
                  ? 'ติดตั้งเวอร์ชันใหม่เองที่หน้าเข้าสู่ระบบเมื่อไม่มีการขายค้างอยู่ (ยกเลิกได้ระหว่างนับถอยหลัง)'
                  : 'ติดตั้งเองได้บน Android และ Windows',
              store.autoUpdate,
              canInstall ? _setAutoUpdate : null,
            ),
            if (!canInstall)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text('ติดตั้งเวอร์ชันใหม่ผ่านร้านค้าแอปหรือติดต่อ xman studio (xman4289.com)',
                    style: Nv.ui(12.5, color: Nv.ink2, height: 1.45)),
              )
            else if (info != null && !info.hasInstaller)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text('รุ่นนี้ยังไม่มีไฟล์ติดตั้งสำหรับ ${AutoUpdater.platformLabel} — ติดต่อ xman studio (xman4289.com)',
                    style: Nv.ui(12.5, color: Nv.ink2, height: 1.45)),
              ),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 10,
              children: [
                NvButton.soft(w.checking ? 'กำลังตรวจสอบ…' : 'ตรวจสอบอัปเดต',
                    icon: NvIcons.sync, size: NvButtonSize.sm, loading: w.checking, onPressed: w.checking || w.installing ? null : _check),
                if (info != null && canInstall && info.hasInstaller)
                  NvButton.gold('ดาวน์โหลดและติดตั้ง v${info.latestVersion}',
                      icon: NvIcons.download,
                      size: NvButtonSize.sm,
                      loading: w.installing,
                      onPressed: w.installing ? null : () => showUpdateDialog(context, requireManager: false)),
              ],
            ),
          ],
        );
      },
    );
  }

  // ── เกี่ยวกับ ──
  Widget _aboutBody() {
    Widget link(String url, {String? label}) => Row(
          children: [
            const Icon(NvIcons.link, size: 12, color: Nv.goldInk),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (label != null) Text(label, style: Nv.ui(12.5, color: Nv.ink2, weight: FontWeight.w600)),
                  SelectableText(url, style: Nv.money(12.5, color: Nv.sapphire, weight: FontWeight.w500)),
                ],
              ),
            ),
            NvIconButton(NvIcons.copy, size: 32, tooltip: 'คัดลอก', onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (!mounted) return;
              nvToast(context, 'คัดลอกลิงก์แล้ว', kind: NvToastKind.success);
            }),
          ],
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            NvArt(NvAssets.logoOnLight, width: 132, height: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Thai Prompt POS', style: Nv.ui(16, weight: FontWeight.w700)),
                  Text('v$_version (build $_build) · ${AutoUpdater.platformLabel}',
                      style: Nv.money(12.5, color: Nv.ink3, weight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('ระบบขายหน้าร้านของ Thai Prompt · ทำงานออฟไลน์ได้เต็มรูปแบบ · สร้างโดย xman studio', style: Nv.ui(13, color: Nv.ink2)),
        const SizedBox(height: 8),
        link('https://thaiprompt.online', label: 'Thai Prompt'),
        const SizedBox(height: 4),
        link('https://xman4289.com', label: 'xman studio'),
      ],
    );
  }
}
