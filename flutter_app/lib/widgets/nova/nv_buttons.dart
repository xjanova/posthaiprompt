// Thaiprompt POS — Nova buttons (mirrors .nv-btn--gold / --ghost on the web).
//
// NvButton variants:
//   gold    — primary CTA (foil gradient, inset highlight, gold glow)
//   navy    — secondary solid (gold text)
//   ghost   — outline; reads correctly on ivory and on night ([onNight])
//   danger  — lacquer red (void / delete / refund)
//   success — jade (confirm paid / receive goods)
//   soft    — quiet ivory chip-button
// Sizes sm 36 · md 44 · lg 52 · xl 64. Loading + disabled states built in.
//
// by xman studio

import 'package:flutter/material.dart';

import '../../theme/nv_tokens.dart';

enum NvButtonKind { gold, navy, ghost, danger, success, soft }

enum NvButtonSize { sm, md, lg, xl }

class NvButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailing;
  final NvButtonKind kind;
  final NvButtonSize size;
  final bool expand;
  final bool loading;
  final bool onNight; // ghost/soft palette for navy backgrounds
  final String? tooltip;

  const NvButton(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.trailing,
    this.kind = NvButtonKind.gold,
    this.size = NvButtonSize.md,
    this.expand = false,
    this.loading = false,
    this.onNight = false,
    this.tooltip,
  });

  const NvButton.gold(this.label,
      {super.key, this.onPressed, this.icon, this.trailing, this.size = NvButtonSize.md, this.expand = false, this.loading = false, this.tooltip})
      : kind = NvButtonKind.gold,
        onNight = false;

  const NvButton.navy(this.label,
      {super.key, this.onPressed, this.icon, this.trailing, this.size = NvButtonSize.md, this.expand = false, this.loading = false, this.tooltip})
      : kind = NvButtonKind.navy,
        onNight = false;

  const NvButton.ghost(this.label,
      {super.key, this.onPressed, this.icon, this.trailing, this.size = NvButtonSize.md, this.expand = false, this.loading = false, this.onNight = false, this.tooltip})
      : kind = NvButtonKind.ghost;

  const NvButton.danger(this.label,
      {super.key, this.onPressed, this.icon, this.trailing, this.size = NvButtonSize.md, this.expand = false, this.loading = false, this.tooltip})
      : kind = NvButtonKind.danger,
        onNight = false;

  const NvButton.success(this.label,
      {super.key, this.onPressed, this.icon, this.trailing, this.size = NvButtonSize.md, this.expand = false, this.loading = false, this.tooltip})
      : kind = NvButtonKind.success,
        onNight = false;

  const NvButton.soft(this.label,
      {super.key, this.onPressed, this.icon, this.trailing, this.size = NvButtonSize.md, this.expand = false, this.loading = false, this.onNight = false, this.tooltip})
      : kind = NvButtonKind.soft;

  @override
  State<NvButton> createState() => _NvButtonState();
}

class _NvButtonState extends State<NvButton> {
  bool _down = false;
  bool _hover = false;

  double get _h => switch (widget.size) {
        NvButtonSize.sm => 36,
        NvButtonSize.md => 44,
        NvButtonSize.lg => 52,
        NvButtonSize.xl => 64,
      };

  double get _fs => switch (widget.size) {
        NvButtonSize.sm => 13,
        NvButtonSize.md => 14.5,
        NvButtonSize.lg => 16,
        NvButtonSize.xl => 18,
      };

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final k = widget.kind;
    final night = widget.onNight;

    Gradient? gradient;
    Color? fill;
    Color fg;
    Border? border;
    List<BoxShadow> shadow = const [];

    switch (k) {
      case NvButtonKind.gold:
        gradient = Nv.btnGold;
        fg = const Color(0xFF1A1405);
        shadow = [
          const BoxShadow(color: Color(0xB3FFFFFF), offset: Offset(0, 1), blurStyle: BlurStyle.inner),
          const BoxShadow(color: Color(0x598A6420), offset: Offset(0, -2), blurStyle: BlurStyle.inner),
          ...Nv.goldGlow(_hover ? 1.25 : 1),
        ];
      case NvButtonKind.navy:
        gradient = Nv.btnNavy;
        fg = Nv.gold200;
        border = Border.all(color: Nv.lineNightStrong);
        shadow = Nv.tintGlow(Nv.navy700, _hover ? 1.2 : 0.9);
      case NvButtonKind.ghost:
        fill = night ? Colors.white.withValues(alpha: _hover ? 0.10 : 0.04) : (_hover ? Nv.gold100 : Colors.transparent);
        fg = night ? Nv.gold200 : Nv.goldInk;
        border = Border.all(color: night ? Nv.lineNightStrong : Nv.gold500.withValues(alpha: 0.7), width: 1.2);
      case NvButtonKind.danger:
        gradient = Nv.btnLacquer;
        fg = Colors.white;
        shadow = Nv.tintGlow(Nv.lacquer, _hover ? 1.2 : 0.9);
      case NvButtonKind.success:
        gradient = Nv.btnJade;
        fg = Colors.white;
        shadow = Nv.tintGlow(Nv.jade, _hover ? 1.2 : 0.9);
      case NvButtonKind.soft:
        fill = night ? Colors.white.withValues(alpha: _hover ? 0.12 : 0.07) : (_hover ? Nv.ivoryDeep : Nv.paper);
        fg = night ? Nv.onNight : Nv.ink2;
        border = Border.all(color: night ? Nv.lineNight : Nv.line);
    }

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: SizedBox(width: _fs + 2, height: _fs + 2, child: CircularProgressIndicator(strokeWidth: 2, color: fg)),
          )
        else if (widget.icon != null) ...[
          Icon(widget.icon, size: _fs + 2, color: fg),
          SizedBox(width: widget.label.isEmpty ? 0 : 9),
        ],
        if (widget.label.isNotEmpty)
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: Nv.fontUi, fontSize: _fs, fontWeight: FontWeight.w700, color: fg, height: 1.1),
            ),
          ),
        if (widget.trailing != null) ...[
          const SizedBox(width: 9),
          Icon(widget.trailing, size: _fs + 2, color: fg),
        ],
      ],
    );

    final radius = BorderRadius.circular(Nv.rPill);
    Widget btn = AnimatedScale(
      scale: _down ? 0.97 : 1,
      duration: Nv.fast,
      curve: Nv.ease,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.5,
        duration: Nv.fast,
        child: Container(
          height: _h,
          constraints: BoxConstraints(minWidth: widget.label.isEmpty ? _h : 64),
          decoration: BoxDecoration(gradient: gradient, color: fill, borderRadius: radius, border: border, boxShadow: enabled ? shadow : const []),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: radius,
              onTap: enabled ? widget.onPressed : null,
              onHighlightChanged: (v) => setState(() => _down = v),
              onHover: (v) => setState(() => _hover = v),
              splashColor: (k == NvButtonKind.gold ? Colors.white : Nv.gold300).withValues(alpha: 0.25),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: widget.label.isEmpty ? 0 : (_h * 0.42)),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
    if (widget.expand) btn = SizedBox(width: double.infinity, child: btn);
    if (widget.tooltip != null) btn = Tooltip(message: widget.tooltip!, child: btn);
    return btn;
  }
}

/// Round icon button (.nv-ibtn) with optional badge count.
class NvIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool onNight;
  final int badge;
  final double size;
  final Color? color;
  final bool active;

  const NvIconButton(
    this.icon, {
    super.key,
    this.onPressed,
    this.tooltip,
    this.onNight = false,
    this.badge = 0,
    this.size = 42,
    this.color,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = color ?? (active ? (onNight ? Nv.navy900 : Nv.gold100) : (onNight ? Nv.gold200 : Nv.ink2));
    Widget b = Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: active ? (onNight ? Nv.btnGold : Nv.btnNavy) : null,
            color: active ? null : (onNight ? Colors.white.withValues(alpha: 0.05) : Nv.paper),
            border: Border.all(color: onNight ? Nv.lineNight.withValues(alpha: 0.6) : Nv.line),
          ),
          child: Icon(icon, size: size * 0.42, color: onPressed == null ? fg.withValues(alpha: 0.4) : fg),
        ),
      ),
    );
    if (badge > 0) {
      b = Stack(
        clipBehavior: Clip.none,
        children: [
          b,
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 19),
              height: 19,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(gradient: Nv.btnGold, borderRadius: BorderRadius.circular(10), boxShadow: const [
                BoxShadow(color: Color(0x4D000000), blurRadius: 6, offset: Offset(0, 2)),
              ]),
              child: Text(badge > 99 ? '99+' : '$badge',
                  style: const TextStyle(fontFamily: Nv.fontUi, fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF1A1405))),
            ),
          ),
        ],
      );
    }
    return tooltip == null ? b : Tooltip(message: tooltip!, child: b);
  }
}
