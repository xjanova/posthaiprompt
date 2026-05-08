// Thaiprompt POS — Dashboard
// by xman studio

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/tp_tokens.dart';
import '../widgets/glass_card.dart';
import '../widgets/tp_orb.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: TpTokens.canvasGradient),
        child: Stack(
          children: [
            const TpOrb(color: TpTokens.purple, size: 380, alignment: Alignment.topLeft, offset: Offset(-140, -140)),
            const TpOrb(color: TpTokens.teal, size: 320, alignment: Alignment.topRight, offset: Offset(80, -100)),
            const TpOrb(color: TpTokens.gold, size: 280, alignment: Alignment.bottomRight, offset: Offset(80, 80)),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: TpTokens.inkSoft),
                          onPressed: () => context.go('/cashier'),
                        ),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('📊 แดชบอร์ดยอดขาย',
                                  style: TextStyle(fontSize: 11, color: TpTokens.inkMute, letterSpacing: 1.5)),
                              Text('สาขา สยาม สแควร์',
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: const [
                        _Kpi(label: 'ยอดขายวันนี้', value: '฿42,580', delta: '↑ 12.4%', icon: '💰', gradient: TpTokens.tealGradient),
                        _Kpi(label: 'ออเดอร์', value: '248', delta: '↑ 8.1%', icon: '🧾', gradient: TpTokens.purpleGradient),
                        _Kpi(label: 'ลูกค้าใหม่', value: '32', delta: '↑ 22%', icon: '👥', gradient: TpTokens.goldGradient),
                        _Kpi(label: 'ตะกร้าเฉลี่ย', value: '฿172', delta: '↓ 3.2%', icon: '🛒', gradient: TpTokens.coralGradient, down: true),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Container(
                      height: 280,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: TpTokens.shadowSoft,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.show_chart, color: TpTokens.teal),
                              SizedBox(width: 8),
                              Text('ยอดขาย · 7 วันล่าสุด',
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text('Chart placeholder — implement using fl_chart in M2',
                              style: TextStyle(fontSize: 11, color: TpTokens.inkMute)),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F8FB),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.center,
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('📊', style: TextStyle(fontSize: 40)),
                                  SizedBox(height: 8),
                                  Text('Chart placeholder',
                                      style: TextStyle(fontSize: 13, color: TpTokens.inkMute)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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

class _Kpi extends StatelessWidget {
  final String label, value, delta, icon;
  final LinearGradient gradient;
  final bool down;

  const _Kpi({
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
    required this.gradient,
    this.down = false,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(icon, style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 11, color: TpTokens.inkMute, letterSpacing: 1.2),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: down ? const Color(0xFFFCE0DC) : const Color(0xFFD8F5DD),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(delta, style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: down ? TpTokens.coralDeep : TpTokens.success,
            )),
          ),
        ],
      ),
    );
  }
}
