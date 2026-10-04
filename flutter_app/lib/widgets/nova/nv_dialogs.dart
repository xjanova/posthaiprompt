// Thaiprompt POS — Nova dialogs & feedback.
//
//   showNvDialog      — framed dialog (kanok medallion head, title, body, actions)
//   showNvConfirm     — destructive / important confirmation → Future<bool>
//   showManagerPin    — manager override keypad → Future<Staff?> (locks after 5 misses)
//   nvToast           — floating snackbar with an icon, by kind
//   NvPinPad          — the numeric keypad shared by login + overrides
//
// by xman studio

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/format.dart';
import '../../models/extra_models.dart';
import '../../state/app_scope.dart';
import '../../theme/nv_icons.dart';
import '../../theme/nv_tokens.dart';
import 'nv_art.dart';
import 'nv_buttons.dart';

enum NvToastKind { info, success, warning, error }

void nvToast(BuildContext context, String message, {NvToastKind kind = NvToastKind.info, String? actionLabel, VoidCallback? onAction}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final (icon, color) = switch (kind) {
    NvToastKind.info => (NvIcons.info, Nv.gold300),
    NvToastKind.success => (NvIcons.checkCircle, Nv.jadeLight),
    NvToastKind.warning => (NvIcons.warning, Nv.gold400),
    NvToastKind.error => (NvIcons.xCircle, Nv.lacquerLight),
  };
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      duration: Duration(milliseconds: kind == NvToastKind.error ? 4200 : 2600),
      content: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: Nv.ui(14, color: Nv.onNight))),
        ],
      ),
      action: actionLabel == null ? null : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
    ));
}

/// Framed Nova dialog. [body] is placed in a scrollable column.
Future<T?> showNvDialog<T>(
  BuildContext context, {
  required String title,
  String? subtitle,
  String? art, // NvAssets icon key shown in the medallion
  String? mascot, // or a mascot pose
  required Widget body,
  List<Widget> Function(BuildContext ctx)? actions,
  double maxWidth = 480,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Nv.navy950.withValues(alpha: 0.55),
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (art != null || mascot != null)
                Center(
                  child: mascot != null
                      ? NvArt.mascot(mascot, height: 120)
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            NvArt(NvAssets.kanokMedallion, width: 92, height: 90),
                            NvArt.icon(art!, size: 50),
                          ],
                        ),
                ),
              if (art != null || mascot != null) const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, style: Nv.display(21)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle, textAlign: TextAlign.center, style: Nv.ui(13.5, color: Nv.ink3, height: 1.4)),
              ],
              const SizedBox(height: 14),
              Flexible(child: SingleChildScrollView(child: body)),
              if (actions != null) ...[
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 10,
                  runSpacing: 10,
                  children: actions(ctx),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

/// Confirmation for destructive / irreversible actions. Returns true on confirm.
Future<bool> showNvConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'ยืนยัน',
  String cancelLabel = 'ยกเลิก',
  bool danger = true,
  IconData? icon,
  String? art,
}) async {
  final ok = await showNvDialog<bool>(
    context,
    title: title,
    art: art,
    body: Column(
      children: [
        if (art == null)
          Container(
            width: 56,
            height: 56,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(shape: BoxShape.circle, color: danger ? Nv.lacquerTint : Nv.gold100),
            child: Icon(icon ?? (danger ? NvIcons.warning : NvIcons.question), color: danger ? Nv.lacquer : Nv.goldInk, size: 22),
          ),
        Text(message, textAlign: TextAlign.center, style: Nv.ui(14.5, color: Nv.ink2, height: 1.5)),
      ],
    ),
    actions: (ctx) => [
      NvButton.soft(cancelLabel, onPressed: () => Navigator.of(ctx).pop(false)),
      danger
          ? NvButton.danger(confirmLabel, onPressed: () => Navigator.of(ctx).pop(true))
          : NvButton.gold(confirmLabel, onPressed: () => Navigator.of(ctx).pop(true)),
    ],
  );
  return ok ?? false;
}

/// Manager override keypad. Returns the approving manager, or null if
/// cancelled. If the signed-in staff is already a manager, approves at once
/// (unless [alwaysAsk]).
Future<Staff?> showManagerPin(BuildContext context, {required String reason, bool alwaysAsk = false, bool kiosk = false}) async {
  final store = AppScope.read(context);
  if (!alwaysAsk && store.isManager) return store.currentStaff;
  return showNvDialog<Staff>(
    context,
    title: 'ต้องอนุมัติโดยผู้จัดการ',
    subtitle: reason,
    art: 'shield',
    maxWidth: 380,
    body: _ManagerPinBody(kiosk: kiosk, onApproved: (s) => Navigator.of(context).pop(s)),
    actions: (ctx) => [NvButton.soft('ยกเลิก', onPressed: () => Navigator.of(ctx).pop())],
  );
}

class _ManagerPinBody extends StatefulWidget {
  final ValueChanged<Staff> onApproved;
  final bool kiosk;
  const _ManagerPinBody({required this.onApproved, this.kiosk = false});

  @override
  State<_ManagerPinBody> createState() => _ManagerPinBodyState();
}

class _ManagerPinBodyState extends State<_ManagerPinBody> {
  String _pin = '';
  String? _error;

  void _submit() {
    final store = AppScope.read(context);
    DateTime? lockOf() => widget.kiosk ? store.kioskLockedUntil : store.managerLockedUntil;
    final locked = lockOf();
    if (locked != null) {
      setState(() => _error = 'ล็อกชั่วคราวถึง ${hm(locked)} (ใส่ผิดหลายครั้ง)');
      return;
    }
    final s = store.verifyManagerPin(_pin, kiosk: widget.kiosk);
    if (s != null) {
      widget.onApproved(s);
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _pin = '';
        final l = lockOf();
        _error = l != null ? 'ใส่ผิดเกินกำหนด ล็อกถึง ${hm(l)}' : 'PIN ไม่ถูกต้อง';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        NvPinDots(length: _pin.length, error: _error != null),
        const SizedBox(height: 8),
        SizedBox(
          height: 20,
          child: Text(_error ?? '', style: Nv.ui(12.5, color: Nv.lacquer, weight: FontWeight.w600)),
        ),
        const SizedBox(height: 6),
        NvPinPad(
          onDigit: (d) {
            if (_pin.length >= 6) return;
            setState(() {
              _pin += d;
              _error = null;
            });
          },
          onBackspace: () => setState(() => _pin = _pin.isEmpty ? '' : _pin.substring(0, _pin.length - 1)),
          onSubmit: _pin.length >= 4 ? _submit : null,
          compact: true,
        ),
      ],
    );
  }
}

/// PIN dots (●●●○○○).
class NvPinDots extends StatelessWidget {
  final int length;
  final int max;
  final bool error;
  final bool onNight;
  const NvPinDots({super.key, required this.length, this.max = 6, this.error = false, this.onNight = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < max; i++)
          AnimatedContainer(
            duration: Nv.fast,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: i < length ? (error ? Nv.btnLacquer : Nv.btnGold) : null,
              color: i < length ? null : Colors.transparent,
              border: Border.all(
                color: error ? Nv.lacquerLight : (onNight ? Nv.lineNightStrong : Nv.gold500.withValues(alpha: 0.6)),
                width: 1.4,
              ),
              boxShadow: i < length && !error ? Nv.goldGlow(0.4) : null,
            ),
          ),
      ],
    );
  }
}

/// 3×4 numeric keypad. Physical keyboard digits/Backspace/Enter also work.
class NvPinPad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onSubmit;
  final bool onNight;
  final bool compact;

  const NvPinPad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.onSubmit,
    this.onNight = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 62.0 : 76.0;
    Widget key(String label, {IconData? icon, VoidCallback? onTap, bool gold = false}) {
      final enabled = onTap != null;
      return Padding(
        padding: EdgeInsets.all(compact ? 5 : 7),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Ink(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: gold && enabled ? Nv.btnGold : null,
                color: gold && enabled ? null : (onNight ? Colors.white.withValues(alpha: 0.06) : Nv.paper),
                border: Border.all(color: onNight ? Nv.lineNight : Nv.line),
                boxShadow: gold && enabled ? Nv.goldGlow(0.6) : null,
              ),
              child: Center(
                child: icon != null
                    ? Icon(icon, size: 20, color: gold ? (enabled ? const Color(0xFF1A1405) : Nv.ink4) : (onNight ? Nv.gold200 : Nv.ink2))
                    : Text(label, style: Nv.money(compact ? 22 : 26, color: onNight ? Nv.onNight : Nv.ink, weight: FontWeight.w600)),
              ),
            ),
          ),
        ),
      );
    }

    return Focus(
      autofocus: true,
      onKeyEvent: (node, e) {
        if (e is! KeyDownEvent) return KeyEventResult.ignored;
        final ch = e.character;
        if (ch != null && RegExp(r'^\d$').hasMatch(ch)) {
          onDigit(ch);
          return KeyEventResult.handled;
        }
        if (e.logicalKey == LogicalKeyboardKey.backspace) {
          onBackspace();
          return KeyEventResult.handled;
        }
        if ((e.logicalKey == LogicalKeyboardKey.enter || e.logicalKey == LogicalKeyboardKey.numpadEnter) && onSubmit != null) {
          onSubmit!();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Row(mainAxisSize: MainAxisSize.min, children: [for (final d in row) key(d, onTap: () => onDigit(d))]),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              key('', icon: NvIcons.backspace, onTap: onBackspace),
              key('0', onTap: () => onDigit('0')),
              key('', icon: NvIcons.check, onTap: onSubmit, gold: true),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ask for a whole-baht amount with a keypad-friendly field. Null = cancelled.
Future<int?> showNvAmountDialog(BuildContext context, {required String title, String? subtitle, int? initial, String? art, String confirmLabel = 'บันทึก'}) async {
  final c = TextEditingController(text: initial?.toString() ?? '');
  final res = await showNvDialog<int>(
    context,
    title: title,
    subtitle: subtitle,
    art: art,
    maxWidth: 380,
    body: TextField(
      controller: c,
      autofocus: true,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
      style: Nv.money(30),
      decoration: const InputDecoration(prefixText: '฿ ', hintText: '0'),
      onSubmitted: (v) => Navigator.of(context).pop(int.tryParse(v)),
    ),
    actions: (ctx) => [
      NvButton.soft('ยกเลิก', onPressed: () => Navigator.of(ctx).pop()),
      NvButton.gold(confirmLabel, onPressed: () => Navigator.of(ctx).pop(int.tryParse(c.text))),
    ],
  );
  // dispose after the route's exit animation has finished using the field
  WidgetsBinding.instance.addPostFrameCallback((_) => Future.delayed(const Duration(milliseconds: 400), c.dispose));
  return res;
}

/// Ask for a single line of text. Null = cancelled.
Future<String?> showNvTextDialog(BuildContext context,
    {required String title, String? subtitle, String? initial, String hint = '', String confirmLabel = 'บันทึก', int maxLines = 1, String? art}) async {
  final c = TextEditingController(text: initial ?? '');
  final res = await showNvDialog<String>(
    context,
    title: title,
    subtitle: subtitle,
    art: art,
    maxWidth: 440,
    body: TextField(
      controller: c,
      autofocus: true,
      maxLines: maxLines,
      decoration: InputDecoration(hintText: hint),
      onSubmitted: maxLines == 1 ? (v) => Navigator.of(context).pop(v.trim()) : null,
    ),
    actions: (ctx) => [
      NvButton.soft('ยกเลิก', onPressed: () => Navigator.of(ctx).pop()),
      NvButton.gold(confirmLabel, onPressed: () => Navigator.of(ctx).pop(c.text.trim())),
    ],
  );
  WidgetsBinding.instance.addPostFrameCallback((_) => Future.delayed(const Duration(milliseconds: 400), c.dispose));
  return res;
}
