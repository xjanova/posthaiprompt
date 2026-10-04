// Thaiprompt POS — Settings (Nova).
//
// Sections, each with its own validation and "บันทึก" (all through
// PosStore.updateSettings): ร้านค้า · การรับชำระ (PromptPay + live ฿1 test QR,
// VAT) · ใบเสร็จและเครื่องพิมพ์ (footer, paper, OS printer list, auto-print,
// real test print) · การทำงาน · เซิร์ฟเวอร์ Thai Prompt (the original pairing
// flow: URL + product key + API key → pairTerminal, sync now, unpair with
// confirm + manager PIN) · อัปเดตแอป (GitHub Releases auto-updater) ·
// เกี่ยวกับ. Every controller is owned by this State and disposed with it.
//
// by xman studio

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/api/api_exceptions.dart';
import '../core/payments/promptpay.dart';
import '../core/print/print_service.dart';
import '../core/sync/sync_service.dart';
import '../models/order_models.dart';
import '../print/print_actions.dart' show rollMedium;
import '../print/receipt_doc.dart';
import '../services/auto_updater.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';

const _repoOwner = 'xjanova';
const _repoName = 'posthaiprompt';

enum _Sec { shop, payment, receipt, ops, server, update, about }

extension _SecX on _Sec {
  String get title => switch (this) {
        _Sec.shop => 'ร้านค้า',
        _Sec.payment => 'การรับชำระ',
        _Sec.receipt => 'ใบเสร็จและเครื่องพิมพ์',
        _Sec.ops => 'การทำงาน',
        _Sec.server => 'เซิร์ฟเวอร์ Thai Prompt',
        _Sec.update => 'อัปเดตแอป',
        _Sec.about => 'เกี่ยวกับ',
      };

  String get art => switch (this) {
        _Sec.shop => 'branch',
        _Sec.payment => 'promptpay',
        _Sec.receipt => 'printer',
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

  List<String> _printers = <String>[];
  bool _loadingPrinters = false;
  bool _testing = false;
  bool _showKey = false;
  bool _pairing = false;
  bool _syncing = false;
  bool _loaded = false;

  // ── app version + updater (kept from the previous settings screen) ──
  String _version = '…';
  String _build = '…';
  String _status = 'ยังไม่ได้ตรวจสอบ';
  bool _checking = false;
  bool _installing = false;
  double? _progress;
  UpdateInfo? _info;

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
  }

  void _resetOps(PosStore s) {
    _requireShift = s.requireShift;
    _kitchen = s.kitchenEnabled;
    _sound = s.soundEnabled;
  }

  @override
  void dispose() {
    for (final c in [_shop, _branch, _phone, _address, _taxId, _promptPay, _vatRate, _footer, _baseUrl, _productKey, _apiKey]) {
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
      _footer.text.trim() != s.receiptFooter || _paper != s.paperWidthMm || _printer != s.printerName || _autoPrint != s.autoPrintReceipt;

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
    AppScope.read(context).updateSettings(footer: _footer.text, paperWidth: _paper, printer: _printer, autoPrint: _autoPrint);
    setState(() {});
    nvToast(context, 'บันทึกการตั้งค่าใบเสร็จแล้ว', kind: NvToastKind.success);
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
      );
      if (!mounted) return;
      nvToast(context, res.message, kind: res.ok ? NvToastKind.success : NvToastKind.warning);
    } finally {
      if (mounted) setState(() => _testing = false);
    }
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

  // ───────────────────────── updater (original logic) ─────────────────────────

  bool get _canSelfInstall => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  String get _platform {
    if (kIsWeb) return 'Web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.windows => 'Windows',
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.linux => 'Linux',
      TargetPlatform.fuchsia => 'Fuchsia',
    };
  }

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _status = 'กำลังตรวจสอบ GitHub Releases…';
    });
    final info = await AutoUpdater(owner: _repoOwner, repo: _repoName).checkForUpdate();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _info = info;
      if (info == null) {
        _status = 'ตรวจสอบไม่ได้ — ตรวจอินเทอร์เน็ต หรือยังไม่มีไฟล์ติดตั้งในรุ่นล่าสุด';
      } else if (info.hasUpdate) {
        _status = 'มีอัปเดต: v${info.currentVersion} → v${info.latestVersion}';
      } else {
        _status = 'ใช้เวอร์ชันล่าสุดแล้ว (v${info.currentVersion})';
      }
    });
  }

  Future<void> _install() async {
    final info = _info;
    if (info == null || !info.hasUpdate || _installing) return;
    final ok = await showNvConfirm(
      context,
      title: 'ติดตั้ง v${info.latestVersion}?',
      message: 'ดาวน์โหลดและติดตั้งทับเวอร์ชันเดิม — ข้อมูลร้านในเครื่องยังอยู่ครบ แอปจะเปิดใหม่หลังติดตั้ง',
      confirmLabel: 'ดาวน์โหลดและติดตั้ง',
      danger: false,
      art: 'settings',
    );
    if (!ok || !mounted) return;
    setState(() {
      _installing = true;
      _progress = 0;
      _status = 'กำลังเริ่มดาวน์โหลด…';
    });
    await AutoUpdater(owner: _repoOwner, repo: _repoName).downloadAndInstall(
      info,
      onProgress: (pct, status) {
        if (mounted) {
          setState(() {
            _progress = (pct / 100).clamp(0.0, 1.0);
            _status = status;
          });
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _installing = false;
            _progress = null;
            _status = 'ผิดพลาด: $e';
          });
        }
      },
      onComplete: () {
        if (mounted) setState(() => _installing = false);
      },
    );
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
        _section(_Sec.receipt, 'ท้ายใบเสร็จ ขนาดกระดาษ และเครื่องพิมพ์', dirty[_Sec.receipt]!, _receiptBody(store),
            onSave: _saveReceipt, onReset: () => setState(() => _resetReceipt(store))),
        _section(_Sec.ops, 'กะการขาย ครัว และเสียง', dirty[_Sec.ops]!, _opsBody(), onSave: _saveOps, onReset: () => setState(() => _resetOps(store))),
        _section(_Sec.server, 'จับคู่เครื่องเพื่อส่งบิลและดึงสินค้าจากร้านออนไลน์', dirty[_Sec.server]!, _serverBody(store)),
        _section(_Sec.update, 'ตรวจและติดตั้งเวอร์ชันใหม่', false, _updateBody()),
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
  Widget _receiptBody(PosStore store) {
    final options = <String>['', ..._printers];
    if (_printer.isNotEmpty && !options.contains(_printer)) options.add(_printer);
    String label(String p) {
      if (p.isEmpty) return 'ถามทุกครั้ง (หน้าต่างพิมพ์ของระบบ)';
      return _printers.contains(p) ? p : '$p (ไม่พบในเครื่องตอนนี้)';
    }

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
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Text('ขนาดกระดาษ', style: Nv.ui(12.5, color: Nv.ink2, weight: FontWeight.w600)),
                  ),
                  NvSegmented<int>(
                    options: const [(58, '58 มม.'), (80, '80 มม.')],
                    value: _paper,
                    onChanged: (v) => setState(() => _paper = v),
                  ),
                ],
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 6),
                      child: Text('เครื่องพิมพ์ใบเสร็จ', style: Nv.ui(12.5, color: Nv.ink2, weight: FontWeight.w600)),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(color: Nv.paper, borderRadius: BorderRadius.circular(Nv.rSm), border: Border.all(color: Nv.line)),
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
              ),
            ],
          ),
          if (!_loadingPrinters && _printers.isEmpty) ...[
            const SizedBox(height: 8),
            Text('ระบบนี้ไม่ส่งรายชื่อเครื่องพิมพ์มาให้ — จะเปิดหน้าต่างพิมพ์ของระบบทุกครั้ง', style: Nv.ui(12, color: Nv.ink3)),
          ],
          const SizedBox(height: 8),
          _switchRow('พิมพ์ใบเสร็จอัตโนมัติหลังชำระเงิน', 'ส่งไปที่เครื่องพิมพ์ที่เลือกทันทีโดยไม่ต้องกดพิมพ์', _autoPrint,
              (v) => setState(() => _autoPrint = v)),
          const SizedBox(height: 8),
          Row(
            children: [
              NvButton.navy('พิมพ์ทดสอบ', icon: NvIcons.print, size: NvButtonSize.sm, loading: _testing, onPressed: _testPrint),
              const SizedBox(width: 12),
              Expanded(
                child: Text('ใช้ขนาดกระดาษและเครื่องพิมพ์ที่เลือกด้านบน (ยังไม่ต้องบันทึก) · พิมพ์เป็นใบทดสอบ ไม่ใช่ใบเสร็จ',
                    style: Nv.ui(12, color: Nv.ink3, height: 1.4)),
              ),
            ],
          ),
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
  Widget _updateBody() {
    final info = _info;
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
                  Icon(info?.hasUpdate == true ? NvIcons.download : NvIcons.info, size: 15, color: info?.hasUpdate == true ? Nv.goldInk : Nv.ink3),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_status, style: Nv.ui(13.5, color: Nv.ink, weight: FontWeight.w600))),
                ],
              ),
              if (_progress != null) ...[
                const SizedBox(height: 10),
                ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: _progress, minHeight: 7)),
              ],
              if (info != null && info.hasUpdate) ...[
                const SizedBox(height: 10),
                NvKeyValue('เผยแพร่เมื่อ', thaiDate(info.publishedAt), mono: false),
                if (info.sizeBytes > 0) NvKeyValue('ขนาดไฟล์', '${(info.sizeBytes / 1048576).toStringAsFixed(1)} MB'),
                if (info.releaseNotes.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: SingleChildScrollView(
                      child: Text(info.releaseNotes.trim(), style: Nv.ui(12.5, color: Nv.ink2, height: 1.45)),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (info != null && info.hasUpdate && !_canSelfInstall)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'การติดตั้งอัตโนมัติรองรับเฉพาะ Android — บน $_platform ดาวน์โหลดตัวติดตั้งเวอร์ชันใหม่ได้ที่ github.com/$_repoOwner/$_repoName/releases',
              style: Nv.ui(12.5, color: Nv.ink2, height: 1.45),
            ),
          ),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 10,
          runSpacing: 10,
          children: [
            NvButton.soft(_checking ? 'กำลังตรวจสอบ…' : 'ตรวจสอบอัปเดต',
                icon: NvIcons.sync, size: NvButtonSize.sm, loading: _checking, onPressed: _checking || _installing ? null : _check),
            if (info != null && info.hasUpdate && _canSelfInstall)
              NvButton.gold('ดาวน์โหลดและติดตั้ง v${info.latestVersion}',
                  icon: NvIcons.download, size: NvButtonSize.sm, loading: _installing, onPressed: _installing ? null : _install),
          ],
        ),
      ],
    );
  }

  // ── เกี่ยวกับ ──
  Widget _aboutBody() {
    Widget link(String text) => Row(
          children: [
            const Icon(NvIcons.link, size: 12, color: Nv.goldInk),
            const SizedBox(width: 8),
            Expanded(child: SelectableText(text, style: Nv.money(12.5, color: Nv.sapphire, weight: FontWeight.w500))),
            NvIconButton(NvIcons.copy, size: 32, tooltip: 'คัดลอก', onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
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
                  Text('v$_version (build $_build) · $_platform', style: Nv.money(12.5, color: Nv.ink3, weight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('ระบบขายหน้าร้านของ Thai Prompt · ทำงานออฟไลน์ได้เต็มรูปแบบ · สร้างโดย xman studio', style: Nv.ui(13, color: Nv.ink2)),
        const SizedBox(height: 8),
        link('https://thaiprompt.online'),
        link('https://github.com/$_repoOwner/$_repoName'),
      ],
    );
  }
}
