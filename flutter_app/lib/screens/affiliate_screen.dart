// Thaiprompt POS — แนะนำเพื่อน (Thai Prompt affiliate) · /affiliate
//
// The shop's real referral identity from the store: referralCode +
// referralLink (https://thaiprompt.online/r/<code>) with copy buttons and a
// scannable QR, plus the members recorded with this code on this terminal
// (store.referredCustomers) and their spend. Commission is NOT computed here —
// it is tracked on thaiprompt.online, and the screen says so plainly.
//
// by xman studio

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/catalog_models.dart' show stableHue;
import '../models/extra_models.dart';
import '../state/app_scope.dart';
import '../widgets/nova/nova.dart';

class AffiliateScreen extends StatelessWidget {
  const AffiliateScreen({super.key});

  Future<void> _copy(BuildContext context, String text, String what) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    nvToast(context, 'คัดลอก$whatแล้ว', kind: NvToastKind.success);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final code = store.referralCode;
    final link = store.referralLink;
    final referred = List.of(store.referredCustomers)..sort((a, b) => b.spent.compareTo(a.spent));
    final totalSpent = referred.fold<int>(0, (s, c) => s + c.spent);

    return NvScaffold(
      title: 'แนะนำเพื่อน',
      eyebrow: 'THAI PROMPT AFFILIATE',
      subtitle: 'ชวนร้านค้าและลูกค้ามาใช้ Thai Prompt ด้วยลิงก์ของร้านคุณ',
      art: 'affiliate',
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _Hero(
            code: code,
            link: link,
            onCopyLink: () => _copy(context, link, 'ลิงก์แนะนำ'),
            onCopyCode: () => _copy(context, code, 'รหัส $code '),
          ),
          if (store.productKey.isEmpty) ...[
            const SizedBox(height: 12),
            NvSheet(
              color: Nv.amberTint,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(NvIcons.warning, size: 16, color: Nv.amber),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'เครื่องนี้ยังไม่ได้จับคู่กับบัญชีร้านบน thaiprompt.online — รหัสนี้คำนวณจากข้อมูลในเครื่อง และอาจเปลี่ยนเมื่อจับคู่เครื่องแล้ว',
                      style: Nv.ui(13, color: Nv.ink2, height: 1.4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  NvButton.soft('ตั้งค่าเซิร์ฟเวอร์', icon: NvIcons.server, size: NvButtonSize.sm, onPressed: () => context.go('/settings')),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          NvSheet(
            color: Nv.sapphireTint,
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(padding: EdgeInsets.only(top: 2), child: Icon(NvIcons.info, size: 15, color: Nv.sapphire)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ค่าคอมมิชชั่น ยอดแนะนำ และการจ่ายผลตอบแทน ติดตามได้ที่ thaiprompt.online ในบัญชีร้านของคุณ — '
                    'POS เครื่องนี้แสดงเฉพาะรหัส/ลิงก์ของร้าน และสมาชิกที่บันทึกรหัสนี้ในเครื่อง ไม่ได้คำนวณหรือจ่ายค่าคอมมิชชั่น',
                    style: Nv.ui(13, color: Nv.ink2, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const NvSectionTitle('ทำงานอย่างไร', icon: NvIcons.route),
          LayoutBuilder(builder: (context, c) {
            final cols = c.maxWidth > 820 ? 3 : 1;
            final w = (c.maxWidth - (cols - 1) * 12) / cols;
            const steps = [
              (NvIcons.share, 'แชร์ลิงก์หรือ QR', 'ส่งลิงก์ให้เพื่อนร้านค้า หรือให้ลูกค้าสแกน QR จากหน้าจอนี้'),
              (NvIcons.userPlus, 'สมัครผ่านลิงก์', 'ผู้ที่สมัครผ่านลิงก์จะถูกผูกกับรหัสแนะนำของร้านคุณบน thaiprompt.online'),
              (NvIcons.chartLine, 'ดูผลตอบแทนออนไลน์', 'เข้าสู่ระบบ thaiprompt.online เพื่อดูยอดแนะนำและค่าคอมมิชชั่น'),
            ];
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < steps.length; i++)
                  SizedBox(
                    width: w,
                    child: NvSheet(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(gradient: Nv.btnNavy, shape: BoxShape.circle),
                            child: Text('${i + 1}', style: Nv.money(16, color: Nv.gold200)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Icon(steps[i].$1, size: 13, color: Nv.goldInk),
                                  const SizedBox(width: 8),
                                  Flexible(child: Text(steps[i].$2, style: Nv.ui(14.5, weight: FontWeight.w700))),
                                ]),
                                const SizedBox(height: 4),
                                Text(steps[i].$3, style: Nv.ui(12.5, color: Nv.ink3, height: 1.4)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }),
          const SizedBox(height: 20),
          NvSectionTitle(
            'สมาชิกที่บันทึกรหัส $code',
            icon: NvIcons.users,
            trailing: '${referred.length} คน · ยอดซื้อรวม ${baht(totalSpent)}',
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 2),
            child: Text('สมาชิกที่เพิ่มจากเครื่องนี้จะถูกบันทึกรหัสแนะนำของร้านไว้อัตโนมัติ', style: Nv.ui(12.5, color: Nv.ink3)),
          ),
          if (referred.isEmpty)
            NvSheet(
              child: NvEmptyState(
                mascot: 'wai',
                size: 130,
                title: 'ยังไม่มีสมาชิกที่บันทึกรหัสนี้',
                message: 'เพิ่มสมาชิกที่เมนู "สมาชิก" แล้วรายชื่อจะแสดงที่นี่พร้อมยอดซื้อ',
                actionLabel: 'ไปหน้าสมาชิก',
                actionIcon: NvIcons.members,
                onAction: () => context.go('/crm'),
              ),
            )
          else
            NvSheet(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  for (var i = 0; i < referred.length; i++) ...[
                    if (i > 0) const Divider(height: 1, color: Nv.lineSoft, indent: 16, endIndent: 16),
                    _ReferredRow(customer: referred[i]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ReferredRow extends StatelessWidget {
  final Customer customer;
  const _ReferredRow({required this.customer});

  @override
  Widget build(BuildContext context) {
    final c = customer;
    final narrow = MediaQuery.sizeOf(context).width < 700;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          NvAvatar(c.initials, hue: stableHue(c.id), size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(14.5, weight: FontWeight.w700)),
                Text(
                  '${c.phone.isEmpty ? 'ไม่มีเบอร์' : phoneFmt(c.phone)} · สมัคร ${thaiDate(c.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Nv.ui(12, color: Nv.ink3),
                ),
              ],
            ),
          ),
          if (!narrow) ...[
            SizedBox(
              width: 90,
              child: Text('${groupDigits(c.visits)} ครั้ง', textAlign: TextAlign.right, style: Nv.money(13, color: Nv.ink2, weight: FontWeight.w500)),
            ),
            const SizedBox(width: 12),
          ],
          SizedBox(width: 100, child: Text(baht(c.spent), textAlign: TextAlign.right, style: Nv.money(14.5))),
        ],
      ),
    );
  }
}

// ───────────────────────────── hero ─────────────────────────────

class _Hero extends StatelessWidget {
  final String code;
  final String link;
  final VoidCallback onCopyLink;
  final VoidCallback onCopyCode;
  const _Hero({required this.code, required this.link, required this.onCopyLink, required this.onCopyCode});

  @override
  Widget build(BuildContext context) {
    final qr = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Nv.rMd),
            border: Border.all(color: Nv.gold400, width: 2),
            boxShadow: Nv.goldGlow(0.6),
          ),
          child: QrImageView(
            data: link,
            size: 176,
            padding: EdgeInsets.zero,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Nv.navy900),
            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Nv.navy900),
          ),
        ),
        const SizedBox(height: 8),
        Text('สแกนเพื่อเปิดลิงก์แนะนำ', style: Nv.ui(12, color: Nv.onNight3)),
      ],
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(Nv.rXl),
      child: Container(
        decoration: BoxDecoration(
          gradient: Nv.night,
          borderRadius: BorderRadius.circular(Nv.rXl),
          border: Border.all(color: Nv.lineNightStrong),
        ),
        child: Stack(
          children: [
            const NvKanokCorners(size: 64, opacity: 0.55, inset: EdgeInsets.all(4)),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
              child: LayoutBuilder(builder: (context, c) {
                final info = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('รหัสแนะนำของร้าน', style: Nv.eyebrow(color: Nv.gold300)),
                    const SizedBox(height: 6),
                    NvFoilText(code, style: Nv.money(44)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(Nv.rSm),
                        border: Border.all(color: Nv.lineNight),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(NvIcons.link, size: 13, color: Nv.gold300),
                          const SizedBox(width: 10),
                          Flexible(child: SelectableText(link, style: Nv.ui(14, color: Nv.onNight, weight: FontWeight.w600))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        NvButton.gold('คัดลอกลิงก์', icon: NvIcons.copy, onPressed: onCopyLink),
                        NvButton.ghost('คัดลอกรหัส', icon: NvIcons.copy, onNight: true, onPressed: onCopyCode),
                      ],
                    ),
                  ],
                );
                if (c.maxWidth < 640) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [info, const SizedBox(height: 20), Center(child: qr)],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: info),
                    const SizedBox(width: 24),
                    qr,
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
