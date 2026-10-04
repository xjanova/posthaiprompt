// Thaiprompt POS — ผู้ให้บริการขนส่ง · /shipping/providers
//
// The shop's delivery / parcel providers (store.shippingProviders) grouped by
// kind (อาหาร / พัสดุ / ส่งเอง): enable switch (updateProvider enabled —
// enabled providers appear in the delivery form), base fee and the shop's
// merchant/account id (edit dialog). Honest status: jobs are recorded by
// staff — there is no partner API integration yet.
//
// by xman studio

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../models/extra_models.dart';
import '../state/app_scope.dart';
import '../widgets/nova/nova.dart';

const _groups = [
  ('food', 'เดลิเวอรี่อาหาร', NvIcons.delivery),
  ('parcel', 'ขนส่งพัสดุ', NvIcons.shipping),
  ('self', 'ส่งเองโดยร้าน', NvIcons.store),
];

String _kindOf(ShippingProvider p) => (p.kind == 'food' || p.kind == 'self') ? p.kind : 'parcel';

String _kindLabel(String k) => switch (k) {
      'food' => 'อาหาร',
      'self' => 'ส่งเอง',
      _ => 'พัสดุ',
    };

class ShippingProvidersScreen extends StatelessWidget {
  const ShippingProvidersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final all = store.shippingProviders;
    final enabled = all.where((p) => p.enabled).length;
    final compact = MediaQuery.sizeOf(context).width < 760;
    return NvScaffold(
      title: 'ผู้ให้บริการขนส่ง',
      eyebrow: 'SHIPPING PROVIDERS',
      subtitle: 'เลือกผู้ให้บริการที่ร้านใช้ ค่าส่งเริ่มต้น และรหัสร้านของแต่ละเจ้า',
      art: 'shipping',
      actions: [
        NvButton.ghost(compact ? '' : 'งานจัดส่ง', icon: NvIcons.delivery, tooltip: 'งานจัดส่ง', onPressed: () => context.go('/delivery')),
      ],
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          NvSheet(
            color: Nv.amberTint,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(padding: EdgeInsets.only(top: 2), child: Icon(NvIcons.info, size: 16, color: Nv.amber)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('บันทึกงานด้วยตนเอง — ยังไม่เชื่อม API ผู้ให้บริการ', style: Nv.ui(14.5, weight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        'ผู้ให้บริการที่เปิดใช้จะแสดงให้เลือกในหน้างานจัดส่ง พร้อมเติมค่าส่งเริ่มต้นให้อัตโนมัติ — '
                        'การเรียกไรเดอร์ เลขพัสดุ และสถานะ ต้องทำในแอปของผู้ให้บริการแล้วบันทึกกลับในหน้างานจัดส่ง',
                        style: Nv.ui(13, color: Nv.ink2, height: 1.45),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text('เปิดใช้ $enabled จาก ${all.length} ราย', style: Nv.ui(13, color: Nv.ink3, weight: FontWeight.w600)),
          ),
          for (final g in _groups) ...[
            Builder(builder: (context) {
              final list = all.where((p) => _kindOf(p) == g.$1).toList();
              if (list.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NvSectionTitle(g.$2, icon: g.$3, trailing: '${list.length} ราย'),
                    LayoutBuilder(builder: (context, c) {
                      final cols = c.maxWidth > 1200 ? 3 : (c.maxWidth > 740 ? 2 : 1);
                      final w = (c.maxWidth - (cols - 1) * 14) / cols;
                      return Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [for (final p in list) SizedBox(width: w, child: _ProviderCard(provider: p, icon: g.$3))],
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final ShippingProvider provider;
  final IconData icon;
  const _ProviderCard({required this.provider, required this.icon});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final p = provider;
    final jobs = store.deliveries.where((d) => d.providerId == p.id).toList();
    final active = jobs.where((d) => d.status != DeliveryStatus.delivered && d.status != DeliveryStatus.cancelled).length;
    final self = _kindOf(p) == 'self';
    return NvSheet(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      goldEdge: p.enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: p.enabled ? Nv.btnNavy : null,
                  color: p.enabled ? null : Nv.ivoryDeep,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: p.enabled ? Nv.gold200 : Nv.ink3),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(15.5, weight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Wrap(spacing: 6, runSpacing: 4, children: [
                      NvBadge(_kindLabel(_kindOf(p)), tint: NvTint.sapphire),
                      NvBadge(p.enabled ? 'เปิดใช้' : 'ปิดอยู่', tint: p.enabled ? NvTint.jade : NvTint.neutral),
                    ]),
                  ],
                ),
              ),
              Tooltip(
                message: p.enabled ? 'ปิดผู้ให้บริการนี้' : 'เปิดใช้ผู้ให้บริการนี้',
                child: Switch(
                  value: p.enabled,
                  onChanged: (v) {
                    final s = AppScope.read(context);
                    s.updateProvider(p, enabled: v);
                    if (!v && active > 0) {
                      nvToast(context, 'ปิด ${p.name} แล้ว — ยังมีงานค้าง $active งานที่ใช้ผู้ให้บริการนี้ (งานเดิมไม่เปลี่ยน)', kind: NvToastKind.warning);
                    } else if (!v && s.enabledProviders.isEmpty) {
                      nvToast(context, 'ปิดครบทุกรายแล้ว — ฟอร์มงานจัดส่งจะแสดงผู้ให้บริการทั้งหมดแทน', kind: NvToastKind.warning);
                    } else {
                      nvToast(context, v ? 'เปิดใช้ ${p.name} แล้ว' : 'ปิด ${p.name} แล้ว', kind: NvToastKind.success);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          NvKeyValue('ค่าส่งเริ่มต้น', baht(p.baseFee)),
          NvKeyValue('รหัสร้าน / บัญชี',
              p.accountId.isEmpty ? 'ยังไม่ได้ระบุ' : (p.accountId.length > 22 ? '${p.accountId.substring(0, 22)}…' : p.accountId),
              mono: p.accountId.isNotEmpty,
              valueColor: p.accountId.isEmpty ? Nv.ink4 : null),
          NvKeyValue('ลิงก์ติดตามพัสดุ', p.trackingUrl.isEmpty ? 'ไม่มี' : 'มี (คัดลอกได้จากงานจัดส่ง)', mono: false,
              valueColor: p.trackingUrl.isEmpty ? Nv.ink4 : null),
          NvKeyValue('งานจัดส่ง', 'ค้าง $active · ทั้งหมด ${jobs.length}', mono: false),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(self ? NvIcons.store : NvIcons.plugX, size: 12, color: Nv.ink3),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  self ? 'ร้านจัดส่งเอง — อัปเดตสถานะในหน้างานจัดส่ง' : 'บันทึกงานด้วยตนเอง — ยังไม่เชื่อม API ผู้ให้บริการ',
                  style: Nv.ui(11.5, color: Nv.ink3),
                ),
              ),
              NvButton.soft('แก้ไข', icon: NvIcons.edit, size: NvButtonSize.sm, onPressed: () => _editProvider(context, p)),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _editProvider(BuildContext context, ShippingProvider p) async {
  final key = GlobalKey<_ProviderFormState>();
  final res = await showNvDialog<({String name, int fee, String account})>(
    context,
    title: 'แก้ไข ${p.name}',
    art: 'shipping',
    maxWidth: 460,
    body: _ProviderForm(key: key, provider: p),
    actions: (ctx) => [
      NvButton.soft('ยกเลิก', onPressed: () => _close(ctx)),
      NvButton.gold('บันทึก', icon: NvIcons.floppy, onPressed: () => key.currentState?._save()),
    ],
  );
  if (res == null || !context.mounted) return;
  AppScope.read(context).updateProvider(p, name: res.name, baseFee: res.fee, accountId: res.account);
  nvToast(context, 'บันทึก ${p.name} แล้ว', kind: NvToastKind.success);
}

class _ProviderForm extends StatefulWidget {
  final ShippingProvider provider;
  const _ProviderForm({super.key, required this.provider});

  @override
  State<_ProviderForm> createState() => _ProviderFormState();
}

class _ProviderFormState extends State<_ProviderForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.provider.name);
  late final _fee = TextEditingController(text: '${widget.provider.baseFee}');
  late final _account = TextEditingController(text: widget.provider.accountId);

  @override
  void dispose() {
    _name.dispose();
    _fee.dispose();
    _account.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_form.currentState?.validate() ?? false)) return;
    _close(context, (name: _name.text.trim(), fee: int.tryParse(_fee.text) ?? 0, account: _account.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NvField(
            label: 'ชื่อที่แสดง *',
            controller: _name,
            icon: NvIcons.tag,
            formatters: [LengthLimitingTextInputFormatter(40)],
            validator: (v) => (v ?? '').trim().isEmpty ? 'กรุณากรอกชื่อ' : null,
          ),
          const SizedBox(height: 12),
          NvField(
            label: 'ค่าส่งเริ่มต้น (บาท)',
            controller: _fee,
            icon: NvIcons.moneyBill,
            keyboard: TextInputType.number,
            suffixText: '฿',
            formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
          ),
          const SizedBox(height: 12),
          NvField(
            label: 'รหัสร้าน / Merchant ID / บัญชีลูกค้า',
            controller: _account,
            icon: NvIcons.idBadge,
            hint: 'ใช้อ้างอิงเวลาติดต่อผู้ให้บริการ',
            formatters: [LengthLimitingTextInputFormatter(60)],
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 10),
          Text('ข้อมูลนี้บันทึกไว้ในเครื่องเพื่ออ้างอิง — ยังไม่ได้ใช้เชื่อมต่อระบบของผู้ให้บริการ',
              style: Nv.ui(12, color: Nv.ink3, height: 1.4)),
        ],
      ),
    );
  }
}

/// Pop [ctx]'s route only while it is still the top route — a double tap
/// during the exit animation must never pop the page underneath.
void _close(BuildContext ctx, [Object? result]) {
  if (ModalRoute.of(ctx)?.isCurrent ?? false) Navigator.of(ctx).pop(result);
}
