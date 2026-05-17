// Thaiprompt POS — Payment screen
// by xman studio

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/tp_tokens.dart';
import '../widgets/tp_button.dart';
import '../widgets/tp_orb.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: TpTokens.canvasGradient),
        child: Stack(
          children: [
            const TpOrb(color: TpTokens.coral, size: 360, alignment: Alignment.topLeft, offset: Offset(-140, -140)),
            const TpOrb(color: TpTokens.teal, size: 320, alignment: Alignment.bottomRight, offset: Offset(80, 80)),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: TpTokens.inkSoft),
                          onPressed: () => context.go('/cashier'),
                        ),
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            gradient: TpTokens.coralGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.payment, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('คำสั่งซื้อ #A1042',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                              Text('โต๊ะ 7 · 3 รายการ',
                                  style: TextStyle(fontSize: 11, color: TpTokens.inkMute)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Total card (glass with decorative orb)
                    Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.96),
                                Colors.white.withValues(alpha: 0.82),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
                            boxShadow: TpTokens.glassShadow(),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Decorative orb (top-right)
                              Positioned(
                                right: -30, top: -30,
                                child: Container(
                                  width: 100, height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: TpTokens.indigo.withValues(alpha: 0.08),
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('ยอดรวม',
                                      style: TextStyle(fontSize: 11, color: TpTokens.inkMute,
                                          letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  ShaderMask(
                                    shaderCallback: (b) => TpTokens.indigoGradient.createShader(b),
                                    child: const Text('฿268',
                                        style: TextStyle(fontSize: 52, fontWeight: FontWeight.w800,
                                            color: Colors.white, height: 1.0)),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    child: Divider(height: 1, color: TpTokens.lineSoft),
                                  ),
                                  const _Line(label: 'ยอดรวมย่อย', value: '฿280'),
                                  const _Line(label: 'ส่วนลด', value: '−฿30', color: TpTokens.coralDeep),
                                  const _Line(label: 'ภาษี VAT 7%', value: '฿18'),
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: TpTokens.mintGradient,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: TpTokens.coloredGlow(TpTokens.mint, intensity: 0.5),
                                    ),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Positioned(
                                          right: -10, top: -20,
                                          child: Container(
                                            width: 60, height: 60,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white.withValues(alpha: 0.18),
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: const [
                                            Icon(Icons.payments, color: Colors.white, size: 20),
                                            SizedBox(width: 10),
                                            Expanded(child: Text('เงินทอน',
                                                style: TextStyle(fontSize: 12, color: Colors.white,
                                                    letterSpacing: 1.5, fontWeight: FontWeight.w700))),
                                            Text('฿232',
                                                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800,
                                                    color: Colors.white)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 10),
                      child: Text('วิธีชำระเงิน',
                          style: TextStyle(fontSize: 11, letterSpacing: 1.5, color: TpTokens.inkMute, fontWeight: FontWeight.w700)),
                    ),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.95,
                      children: [
                        _Method(icon: '💵', label: 'เงินสด', gradient: TpTokens.mintGradient, selected: true),
                        _Method(icon: '📱', label: 'QR PromptPay'),
                        _Method(icon: '💳', label: 'บัตรเครดิต'),
                        _Method(icon: '📲', label: 'e-Wallet'),
                        _Method(icon: '🏷', label: 'วอเชอร์'),
                        _Method(icon: '🎁', label: 'คูปอง'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Quick amounts
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F8FB),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Text('💵 รับเงิน', style: TextStyle(fontSize: 12, color: TpTokens.inkMute)),
                          const SizedBox(width: 8),
                          for (final v in ['฿100', '฿500', '฿1000', 'พอดี'])
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    gradient: v == 'พอดี' ? TpTokens.tealGradient : null,
                                    color: v == 'พอดี' ? null : Colors.white,
                                    border: v == 'พอดี' ? null : Border.all(color: TpTokens.line),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(v, style: TextStyle(
                                    color: v == 'พอดี' ? Colors.white : TpTokens.inkSoft,
                                    fontSize: 11, fontWeight: FontWeight.w700,
                                  )),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(child: TpGhostButton(
                          label: 'ยกเลิก',
                          icon: Icons.close,
                          onPressed: () => context.go('/cashier'),
                        )),
                        const SizedBox(width: 10),
                        Expanded(flex: 2, child: TpCoralButton(
                          label: 'ยืนยันการชำระเงิน',
                          icon: Icons.check,
                          onPressed: () => context.go('/receipt'),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _Line({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: color ?? TpTokens.inkSoft))),
          Text(value, style: TextStyle(fontSize: 13, color: color ?? TpTokens.inkSoft, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Method extends StatelessWidget {
  final String icon, label;
  final LinearGradient? gradient;
  final bool selected;

  const _Method({
    required this.icon,
    required this.label,
    this.gradient,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: selected ? gradient : null,
        color: selected ? null : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: selected
            ? TpTokens.coloredGlow(gradient!.colors.last, intensity: 0.4)
            : TpTokens.shadowSoft,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: selected ? Colors.white.withValues(alpha: 0.25) : TpTokens.bg2,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 22)),
          ),
          const Spacer(),
          Text(label, style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : TpTokens.ink,
          )),
        ],
      ),
    );
  }
}
