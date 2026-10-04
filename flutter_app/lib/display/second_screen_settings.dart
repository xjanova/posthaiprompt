// Thai Prompt POS — settings card for the customer-facing second screen.
//
// by xman studio

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../state/app_scope.dart';
import '../widgets/nova/nova.dart';
import 'second_screen_service.dart';

class SecondScreenSettingsCard extends StatefulWidget {
  /// false = just the controls (the host section draws the frame and title).
  final bool framed;
  const SecondScreenSettingsCard({super.key, this.framed = true});

  @override
  State<SecondScreenSettingsCard> createState() => _SecondScreenSettingsCardState();
}

class _SecondScreenSettingsCardState extends State<SecondScreenSettingsCard> {
  List<ScreenInfo> _displays = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final list = await SecondScreenService.instance.displays();
    if (!mounted) return;
    setState(() {
      _displays = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final svc = SecondScreenService.instance;
    final supported = svc.supported;
    final candidates = _displays.where((d) => !d.primary).toList();

    final content = ListenableBuilder(
        listenable: svc,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.framed && svc.active) const Align(alignment: Alignment.centerLeft, child: NvBadge('กำลังแสดงผล', tint: NvTint.jade)),
            if (widget.framed) Row(
              children: [
                NvArt.icon('display', size: 54),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('จอที่สองสำหรับลูกค้า', style: Nv.display(19)),
                      Text('แสดงรายการ ยอดชำระ QR พร้อมเพย์ และคำขอบคุณ บนจอที่หันหาลูกค้า',
                          style: Nv.ui(13, color: Nv.ink3)),
                    ],
                  ),
                ),
                if (svc.active) const NvBadge('กำลังแสดงผล', tint: NvTint.jade),
              ],
            ),
            if (widget.framed) const SizedBox(height: 14),
            if (!supported)
              Text('อุปกรณ์นี้ยังไม่รองรับจอที่สอง — ใช้หน้า "จอฝั่งลูกค้า" บนอีกเครื่องแทนได้',
                  style: Nv.ui(13.5, color: Nv.ink2))
            else ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: store.secondScreenEnabled,
                title: Text('เปิดจอลูกค้าอัตโนมัติเมื่อเปิดแอป', style: Nv.ui(14.5, weight: FontWeight.w600)),
                subtitle: Text(
                  !kIsWeb && Platform.isAndroid
                      ? 'เครื่อง POS จอคู่ เช่น Sunmi T2/D2, iMin'
                      : 'ต่อจอที่สองแล้วตั้งค่า Windows เป็น "ขยายจอ (Extend)"',
                  style: Nv.ui(12.5, color: Nv.ink3),
                ),
                onChanged: (v) => store.updateSettings(secondScreen: v),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _loading
                        ? const LinearProgressIndicator()
                        : DropdownButtonFormField<String>(
                            initialValue: candidates.any((d) => d.id == store.secondScreenId) ? store.secondScreenId : '',
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'จอที่ใช้แสดง'),
                            items: [
                              const DropdownMenuItem(value: '', child: Text('อัตโนมัติ (จอที่สองที่พบ)')),
                              for (final d in candidates) DropdownMenuItem(value: d.id, child: Text(d.label)),
                            ],
                            onChanged: (v) => store.updateSettings(secondScreenDisplay: v ?? ''),
                          ),
                  ),
                  const SizedBox(width: 8),
                  NvIconButton(NvIcons.sync, tooltip: 'ค้นหาจออีกครั้ง', onPressed: _refresh),
                ],
              ),
              if (!_loading && candidates.isEmpty) ...[
                const SizedBox(height: 8),
                Text('ยังไม่พบจอที่สองที่เชื่อมต่ออยู่', style: Nv.ui(13, color: Nv.amber, weight: FontWeight.w600)),
              ],
              if (svc.error != null) ...[
                const SizedBox(height: 8),
                Text(svc.error!, style: Nv.ui(13, color: Nv.lacquer, weight: FontWeight.w600)),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (!svc.active)
                    NvButton.gold('เปิดจอลูกค้าตอนนี้', icon: NvIcons.display, loading: svc.busy, onPressed: () async {
                      final ok = await svc.start();
                      if (!context.mounted) return;
                      nvToast(context, ok ? 'เปิดจอลูกค้าแล้ว' : (svc.error ?? 'เปิดไม่สำเร็จ'),
                          kind: ok ? NvToastKind.success : NvToastKind.warning);
                    })
                  else
                    NvButton.soft('ปิดจอลูกค้า', icon: NvIcons.xmark, onPressed: svc.stop),
                  NvButton.ghost('ดูตัวอย่างบนจอนี้', icon: NvIcons.eye, onPressed: () => context.go('/display/customer')),
                ],
              ),
            ],
          ],
        ),
      );
    return widget.framed ? NvSheet(padding: const EdgeInsets.all(20), child: content) : content;
  }
}
