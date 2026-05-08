// Thaiprompt POS — Cashier (main POS) screen — high-fidelity port of mockup
// by xman studio

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/tp_tokens.dart';
import '../widgets/tp_button.dart';
import '../widgets/tp_orb.dart';
import '../widgets/tp_product_img.dart';

class CashierScreen extends StatelessWidget {
  const CashierScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: TpTokens.canvasGradient),
        child: Stack(
          children: [
            const TpOrbBackdrop(),
            SafeArea(
              child: Column(
                children: [
                  // ═══ Top order bar (glass) ═══
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                        boxShadow: TpTokens.glassShadow(intensity: 0.7),
                      ),
                      padding: const EdgeInsets.fromLTRB(8, 10, 14, 10),
                      child: Row(
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.arrow_back_ios_new, color: TpTokens.inkSoft, size: 18),
                            onPressed: () => context.go('/'),
                          ),
                          const TpBrandMark(size: 38),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('คำสั่งซื้อ #A1042',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: TpTokens.ink)),
                                    SizedBox(width: 6),
                                    _StatusChip(label: 'เปิด', color: TpTokens.success),
                                  ],
                                ),
                                SizedBox(height: 2),
                                Text('โต๊ะ 7 · 4 ที่นั่ง · เริ่ม 14:18',
                                    style: TextStyle(fontSize: 11, color: TpTokens.inkMute)),
                              ],
                            ),
                          ),
                          _StatusPill(text: 'ออนไลน์', icon: Icons.wifi, color: TpTokens.success),
                        ],
                      ),
                    ),
                  ),

                  // ═══ Search bar ═══
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: TpTokens.shadowSoft,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: TpTokens.inkMute, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'ค้นหาสินค้า / สแกนบาร์โค้ด…',
                                hintStyle: TextStyle(color: TpTokens.inkMute, fontSize: 13),
                                border: InputBorder.none,
                                isCollapsed: true,
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: TpTokens.bg2,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('F2', style: TextStyle(
                                fontFamily: 'monospace', fontSize: 10, color: TpTokens.inkMute,
                                fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ═══ Categories ═══
                  SizedBox(
                    height: 84,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      children: const [
                        _Cat(icon: '🔥', name: 'ของร้อน', count: 18, gradient: TpTokens.coralGradient,
                             glow: TpTokens.coral, selected: true),
                        SizedBox(width: 10),
                        _Cat(icon: '🥤', name: 'ของเย็น', count: 22, gradient: TpTokens.mintGradient, glow: TpTokens.mint),
                        SizedBox(width: 10),
                        _Cat(icon: '☕', name: 'กาแฟ', count: 14, gradient: TpTokens.goldGradient, glow: TpTokens.gold),
                        SizedBox(width: 10),
                        _Cat(icon: '🥐', name: 'เบเกอรี่', count: 11, gradient: TpTokens.purpleGradient, glow: TpTokens.purple),
                        SizedBox(width: 10),
                        _Cat(icon: '⭐', name: 'ชุดเซ็ต', count: 6, gradient: TpTokens.indigoGradient, glow: TpTokens.indigo),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Section header + filter chips
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 14, 8),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text('🔥  ของร้อน · 18 รายการ',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: TpTokens.ink)),
                        ),
                        _FilterChip('ทั้งหมด', selected: true),
                        const SizedBox(width: 6),
                        _FilterChip('ขายดี'),
                      ],
                    ),
                  ),

                  // ═══ Product grid 2-col ═══
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.78,
                        children: const [
                          _Prod(name: 'ชาไทยเย็น', price: 65, hue: 25, code: 'TT-01', tag: 'ขายดี'),
                          _Prod(name: 'มัทฉะลาเต้', price: 85, hue: 145, code: 'MT-02', kind: 'circle'),
                          _Prod(name: 'อเมริกาโน่', price: 70, hue: 35, code: 'AM-03'),
                          _Prod(name: 'ลาเต้ร้อน', price: 75, hue: 50, code: 'LT-04', kind: 'circle'),
                          _Prod(name: 'โกโก้ปั่น', price: 80, hue: 28, code: 'CC-05', tag: 'ใหม่'),
                          _Prod(name: 'ชามะนาวโซดา', price: 55, hue: 105, code: 'LM-06', kind: 'circle'),
                        ],
                      ),
                    ),
                  ),

                  // ═══ Cart summary + pay ═══
                  Container(
                    margin: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.96),
                          Colors.white.withValues(alpha: 0.82),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
                      boxShadow: TpTokens.glassShadow(),
                    ),
                    child: Column(
                      children: [
                        // Mini cart preview (3 items)
                        Row(
                          children: [
                            const _MiniThumb(hue: 25),
                            const SizedBox(width: -8),
                            const _MiniThumb(hue: 145),
                            const SizedBox(width: -8),
                            const _MiniThumb(hue: 35),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('3 รายการในตะกร้า',
                                      style: TextStyle(fontSize: 12, color: TpTokens.inkMute, letterSpacing: 1.2)),
                                  SizedBox(height: 2),
                                  Text('ชาไทยเย็น · มัทฉะ · ครัวซองต์',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                          color: TpTokens.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Indigo gradient total card
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: TpTokens.indigoGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: TpTokens.coloredGlow(TpTokens.indigo, intensity: 0.45),
                          ),
                          child: Row(
                            children: const [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('รวมทั้งสิ้น',
                                        style: TextStyle(fontSize: 12, color: Colors.white,
                                            letterSpacing: 1.3, fontWeight: FontWeight.w500)),
                                    SizedBox(height: 2),
                                    Text('฿268.00',
                                        style: TextStyle(fontSize: 30, color: Colors.white,
                                            fontWeight: FontWeight.w800, height: 1.0)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('คูปอง · TP-MAY30',
                                      style: TextStyle(fontSize: 10, color: Colors.white,
                                          fontFamily: 'monospace', letterSpacing: 1.2)),
                                  SizedBox(height: 2),
                                  Text('−฿30',
                                      style: TextStyle(fontSize: 13, color: Colors.white,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          child: TpCoralButton(
                            label: 'ชำระเงิน · ฿268',
                            trailing: Icons.arrow_forward,
                            onPressed: () => context.go('/payment'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────── helpers ─────────────

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _StatusPill({required this.text, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
        borderRadius: BorderRadius.circular(999),
        boxShadow: TpTokens.coloredGlow(color, intensity: 0.35),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _Cat extends StatelessWidget {
  final String icon, name;
  final int count;
  final LinearGradient gradient;
  final Color glow;
  final bool selected;

  const _Cat({
    required this.icon, required this.name, required this.count,
    required this.gradient, required this.glow, this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: selected ? gradient : null,
        color: selected ? null : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: selected ? null : Border.all(color: Colors.white.withValues(alpha: 0.7)),
        boxShadow: selected
            ? TpTokens.coloredGlow(glow, intensity: 0.45)
            : TpTokens.shadowSoft,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              gradient: selected
                ? null
                : gradient,
              color: selected ? Colors.white.withValues(alpha: 0.22) : null,
              borderRadius: BorderRadius.circular(12),
              border: selected ? Border.all(color: Colors.white.withValues(alpha: 0.4)) : null,
              boxShadow: selected ? null : TpTokens.coloredGlow(glow, intensity: 0.3),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800,
                color: selected ? Colors.white : TpTokens.ink,
              )),
              Text('$count รายการ', style: TextStyle(
                fontSize: 11,
                color: selected ? Colors.white.withValues(alpha: 0.85) : TpTokens.inkMute,
              )),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  // ignore: unused_element_parameter
  const _FilterChip(this.label, {this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: selected ? TpTokens.indigoGradient : null,
        color: selected ? null : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: selected ? null : Border.all(color: TpTokens.line),
        boxShadow: selected
            ? TpTokens.coloredGlow(TpTokens.indigo, intensity: 0.35)
            : null,
      ),
      child: Text(label, style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w700,
        color: selected ? Colors.white : TpTokens.inkSoft,
      )),
    );
  }
}

class _Prod extends StatelessWidget {
  final String name;
  final int price;
  final int hue;
  final String code;
  final String kind;
  final String? tag;

  const _Prod({
    required this.name,
    required this.price,
    required this.hue,
    required this.code,
    this.kind = 'rect',
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
        boxShadow: TpTokens.glassShadow(intensity: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: AspectRatio(
                  aspectRatio: 1.5,
                  child: TpProductImg(hue: hue, label: code, kind: kind, borderRadius: 14),
                ),
              ),
              if (tag != null)
                Positioned(
                  top: 16, left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: tag == 'ใหม่' ? TpTokens.tealGradient : TpTokens.coralGradient,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: TpTokens.coloredGlow(
                          tag == 'ใหม่' ? TpTokens.teal : TpTokens.coral,
                          intensity: 0.35),
                    ),
                    child: Text(tag!, style: const TextStyle(
                        color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: TpTokens.ink),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('฿$price', style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800, color: TpTokens.tealDeep,
                    )),
                    const SizedBox(width: 2),
                    const Text('/แก้ว', style: TextStyle(
                        fontSize: 10, color: TpTokens.inkMute, fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        gradient: TpTokens.tealGradient,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: TpTokens.coloredGlow(TpTokens.teal, intensity: 0.4),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.add, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniThumb extends StatelessWidget {
  final int hue;
  const _MiniThumb({required this.hue});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36, height: 36,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: TpProductImg(hue: hue, kind: 'rect', borderRadius: 10),
      ),
    );
  }
}
