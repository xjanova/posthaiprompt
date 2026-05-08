// Thaiprompt POS — Receipt screen (thermal 80mm preview)
// by xman studio

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/tp_tokens.dart';
import '../widgets/tp_button.dart';
import '../widgets/tp_orb.dart';

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: TpTokens.canvasGradient),
        child: Stack(
          children: [
            const TpOrb(color: TpTokens.gold, size: 320, alignment: Alignment.topLeft, offset: Offset(-100, -100)),
            const TpOrb(color: TpTokens.teal, size: 260, alignment: Alignment.bottomRight, offset: Offset(60, 60)),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Action row
                    Row(
                      children: [
                        Expanded(child: TpGhostButton(
                          label: 'หน้าขาย',
                          icon: Icons.arrow_back,
                          onPressed: () => context.go('/cashier'),
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: TpGhostButton(
                          label: 'พิมพ์อีกครั้ง',
                          icon: Icons.print,
                          onPressed: () {},
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: TpGhostButton(
                          label: 'แดชบอร์ด',
                          icon: Icons.dashboard,
                          onPressed: () => context.go('/dashboard'),
                        )),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Receipt paper
                    Container(
                      width: 360,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: TpTokens.shadowDeep,
                      ),
                      child: Column(
                        children: [
                          const TpBrandMark(size: 48),
                          const SizedBox(height: 8),
                          const Text('ไทยพร้อม คาเฟ่',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          const Text('สาขา สยาม สแควร์',
                              style: TextStyle(fontSize: 11, color: TpTokens.inkMute, fontFamily: 'monospace')),
                          const Text('เลขที่ภาษี 0125567891234',
                              style: TextStyle(fontSize: 11, color: TpTokens.inkMute, fontFamily: 'monospace')),
                          const _Sep(),
                          _Row(label: 'เลขที่', value: 'A1042'),
                          _Row(label: 'แคชเชียร์', value: 'ปริม สุข'),
                          _Row(label: 'วันที่', value: '2026-05-09 14:42'),
                          _Row(label: 'โต๊ะ', value: '7 / 4 ที่'),
                          const _Sep(),
                          _Row(label: 'ชาไทยเย็น', value: '2 × ฿65 = ฿130'),
                          _Row(label: 'มัทฉะลาเต้ (L)', value: '1 × ฿95 = ฿95'),
                          _Row(label: 'ครัวซองต์', value: '1 × ฿55 = ฿55'),
                          const _Sep(),
                          _Row(label: 'ยอดรวมย่อย', value: '฿280'),
                          _Row(label: 'ส่วนลด TP-MAY30', value: '−฿30'),
                          _Row(label: 'ภาษี VAT 7%', value: '฿18'),
                          const _Sep(),
                          _Row(label: 'รวมทั้งสิ้น', value: '฿268', bold: true),
                          _Row(label: 'เงินสด', value: '฿500'),
                          _Row(label: 'เงินทอน', value: '฿232'),
                          const _Sep(),
                          const SizedBox(height: 4),
                          const Text('ขอบคุณค่ะ พบกันใหม่นะคะ',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          const Text('(อย่างย่อ — ไม่ใช่ใบกำกับภาษี)',
                              style: TextStyle(fontSize: 10, color: TpTokens.inkMute, fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Built with ❤ by xman studio',
                        style: TextStyle(fontSize: 11, color: TpTokens.inkMute.withValues(alpha: 0.85))),
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

class _Row extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _Row({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'monospace',
      fontSize: bold ? 16 : 12,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _Sep extends StatelessWidget {
  const _Sep();
  @override
  Widget build(BuildContext context) =>
    Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Container(
      height: 1,
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: TpTokens.inkMute, style: BorderStyle.solid))),
    ));
}
