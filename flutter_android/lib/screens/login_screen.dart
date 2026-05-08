// Thaiprompt POS — Login screen (PIN entry)
// by xman studio

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/tp_tokens.dart';
import '../widgets/tp_button.dart';
import '../widgets/tp_orb.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _pin = '';

  void _onDigit(String d) {
    if (_pin.length >= 4) return;
    setState(() => _pin += d);
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) context.go('/cashier');
      });
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: TpTokens.canvasGradient),
        child: Stack(
          children: [
            const TpOrb(color: TpTokens.teal, size: 380, alignment: Alignment.topLeft, offset: Offset(-160, -160)),
            const TpOrb(color: TpTokens.coral, size: 320, alignment: Alignment.bottomRight, offset: Offset(80, 80)),
            const TpOrb(color: TpTokens.gold, size: 220, alignment: Alignment.topRight, offset: Offset(-220, 80), opacity: 0.45),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Brand banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: TpTokens.tealGradient,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: TpTokens.coloredGlow(TpTokens.tealDeep, intensity: 0.35),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            right: -30, top: -30,
                            child: Container(
                              width: 140, height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: TpTokens.coral.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  TpBrandMark(size: 48),
                                  SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Thaiprompt',
                                          style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w700)),
                                      Text('POINT OF SALE',
                                          style: TextStyle(fontSize: 11, color: Colors.white,
                                              letterSpacing: 2, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 14),
                              Text('สวัสดีค่ะ', style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w700)),
                              Text('ยินดีต้อนรับ', style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w700)),
                              SizedBox(height: 6),
                              Text('เข้าสู่ระบบเพื่อเริ่มขาย', style: TextStyle(fontSize: 13, color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // User pickers (5 chips)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        _UserChip(name: 'ปริม', gradient: TpTokens.goldGradient, selected: true),
                        const SizedBox(width: 8),
                        _UserChip(name: 'ธนา', gradient: TpTokens.tealGradient),
                        const SizedBox(width: 8),
                        _UserChip(name: 'นิด', gradient: TpTokens.coralGradient),
                        const SizedBox(width: 8),
                        _UserChip(name: 'เม', gradient: TpTokens.purpleGradient),
                        const SizedBox(width: 8),
                        _UserChipPlus(),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    const Text('กรอกรหัส PIN',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: TpTokens.ink)),
                    const SizedBox(height: 16),

                    // PIN dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) {
                        final filled = i < _pin.length;
                        return Container(
                          width: 56, height: 64,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: TpTokens.line),
                            boxShadow: TpTokens.shadowSoft,
                          ),
                          alignment: Alignment.center,
                          child: filled
                              ? Container(
                                  width: 16, height: 16,
                                  decoration: const BoxDecoration(shape: BoxShape.circle, color: TpTokens.indigo),
                                )
                              : null,
                        );
                      }),
                    ),
                    const SizedBox(height: 22),

                    // Numpad
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.5,
                      children: [
                        for (var i = 1; i <= 9; i++)
                          _Key(label: '$i', onTap: () => _onDigit('$i')),
                        _Key(label: 'ลืมรหัส', tiny: true, onTap: () {}),
                        _Key(label: '0', onTap: () => _onDigit('0')),
                        _Key(label: '⌫', danger: true, onTap: _onBackspace),
                      ],
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: TpCoralButton(
                        label: 'ลงชื่อเข้าใช้',
                        trailing: Icons.arrow_forward,
                        onPressed: () => context.go('/cashier'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.go('/'),
                      child: const Text('← ภาพรวม', style: TextStyle(color: TpTokens.inkMute)),
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

class _UserChip extends StatelessWidget {
  final String name;
  final LinearGradient gradient;
  final bool selected;

  const _UserChip({required this.name, required this.gradient, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
        gradient: gradient,
        shape: BoxShape.circle,
        border: selected ? Border.all(color: TpTokens.tealDeep, width: 3) : null,
        boxShadow: selected ? TpTokens.coloredGlow(TpTokens.teal) : null,
      ),
      alignment: Alignment.center,
      child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }
}

class _UserChipPlus extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: TpTokens.line, style: BorderStyle.solid, width: 2),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.add, color: TpTokens.inkMute),
    );
  }
}

class _Key extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool tiny;
  final bool danger;

  const _Key({
    required this.label,
    required this.onTap,
    this.tiny = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: TpTokens.line),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: tiny ? 13 : 22,
              fontWeight: FontWeight.w600,
              color: danger ? TpTokens.coralDeep : TpTokens.ink,
            ),
          ),
        ),
      ),
    );
  }
}
