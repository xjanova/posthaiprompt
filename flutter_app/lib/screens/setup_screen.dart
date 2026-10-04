// Thaiprompt POS — First-run setup (create the shop + owner PIN).
//
// Shown only while no staff exists. Creates the owner account (hashed PIN),
// names the shop/branch and optionally stores the PromptPay id, then signs
// the owner in. Server pairing stays optional (Settings → จับคู่เครื่อง).
//
// by xman studio

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/payments/promptpay.dart';
import '../core/security/pin.dart';
import '../models/extra_models.dart';
import '../state/app_scope.dart';
import '../widgets/nova/nova.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _form = GlobalKey<FormState>();
  final _shop = TextEditingController();
  final _branch = TextEditingController(text: 'สาขาหลัก');
  final _owner = TextEditingController();
  final _pin = TextEditingController();
  final _pin2 = TextEditingController();
  final _pp = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_shop, _branch, _owner, _pin, _pin2, _pp]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    final store = AppScope.read(context);
    final owner = store.setupOwner(name: _owner.text, pin: _pin.text, shop: _shop.text, branchName: _branch.text);
    if (_pp.text.trim().isNotEmpty) store.updateSettings(promptPay: _pp.text);
    final res = store.login(owner.id, _pin.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (res is LoginOk) {
      nvToast(context, 'ตั้งค่าร้านเรียบร้อย ยินดีต้อนรับ ${owner.name}', kind: NvToastKind.success);
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Nv.navy950,
      body: NvBackdrop.night(
        image: NvAssets.art('login-hero'),
        imageOpacity: 0.55,
        imageAlignment: Alignment.centerRight,
        child: LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth > 980;
          final card = ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: NvSheet(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
              radius: Nv.rXl,
              goldEdge: true,
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: NvArt(NvAssets.logoOnLight, height: 46, width: 170)),
                    const SizedBox(height: 10),
                    Text('ตั้งค่าร้านครั้งแรก', textAlign: TextAlign.center, style: Nv.display(26)),
                    const SizedBox(height: 4),
                    Text('สร้างบัญชีเจ้าของร้านและรหัส PIN สำหรับเข้าเครื่อง POS',
                        textAlign: TextAlign.center, style: Nv.ui(13.5, color: Nv.ink3)),
                    const SizedBox(height: 6),
                    const NvKanokDivider(width: 220, thin: true),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: NvField(
                            label: 'ชื่อร้าน',
                            controller: _shop,
                            icon: NvIcons.store,
                            hint: 'เช่น ไทยพร้อม คาเฟ่',
                            validator: (v) => (v ?? '').trim().isEmpty ? 'กรุณากรอกชื่อร้าน' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: NvField(label: 'สาขา', controller: _branch, icon: NvIcons.branch)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    NvField(
                      label: 'ชื่อเจ้าของร้าน',
                      controller: _owner,
                      icon: NvIcons.staff,
                      hint: 'ชื่อที่จะแสดงบนใบเสร็จและรายงาน',
                      validator: (v) => (v ?? '').trim().isEmpty ? 'กรุณากรอกชื่อ' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: NvField(
                            label: 'PIN 4–6 หลัก',
                            controller: _pin,
                            icon: NvIcons.key,
                            obscure: true,
                            keyboard: TextInputType.number,
                            formatters: NvField.digits,
                            validator: (v) {
                              final p = v ?? '';
                              if (!PinHasher.isValidPin(p)) return 'PIN ต้องเป็นตัวเลข 4–6 หลัก';
                              if (PinHasher.isWeak(p)) return 'PIN เดาง่ายเกินไป';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: NvField(
                            label: 'ยืนยัน PIN',
                            controller: _pin2,
                            icon: NvIcons.key,
                            obscure: true,
                            keyboard: TextInputType.number,
                            formatters: NvField.digits,
                            validator: (v) => v != _pin.text ? 'PIN ไม่ตรงกัน' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    NvField(
                      label: 'พร้อมเพย์สำหรับรับเงิน (ไม่บังคับ)',
                      controller: _pp,
                      icon: NvIcons.qrcode,
                      hint: 'เบอร์มือถือ หรือเลขประจำตัวผู้เสียภาษี',
                      keyboard: TextInputType.number,
                      formatters: NvField.digits,
                      validator: (v) => (v ?? '').isEmpty || PromptPay.isValidId(v!) ? null : 'รูปแบบพร้อมเพย์ไม่ถูกต้อง',
                    ),
                    const SizedBox(height: 20),
                    NvButton.gold('เริ่มใช้งาน', icon: NvIcons.arrowRight, size: NvButtonSize.lg, expand: true, loading: _busy, onPressed: _submit),
                    const SizedBox(height: 10),
                    Text('จับคู่กับ Thai Prompt (ดึงเมนูจากหลังร้าน) ได้ภายหลังที่ ตั้งค่า → เซิร์ฟเวอร์',
                        textAlign: TextAlign.center, style: Nv.ui(12, color: Nv.ink3)),
                  ],
                ),
              ),
            ),
          );
          return Stack(
            children: [
              if (wide) Positioned(right: 40, bottom: 0, child: NvArt.mascot('welcome', height: c.maxHeight * 0.78)),
              Align(
                alignment: wide ? const Alignment(-0.55, 0) : Alignment.center,
                child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: card),
              ),
            ],
          );
        }),
      ),
    );
  }
}
