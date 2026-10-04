// Thaiprompt POS — Nova building blocks: badges, chips, segmented toggles,
// stat tiles, page/section headers, empty states (with น้องพร้อม), search &
// form fields, avatars, money text, key-value rows.
//
// by xman studio

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/format.dart';
import '../../theme/nv_icons.dart';
import '../../theme/nv_tokens.dart';
import 'nv_art.dart';
import 'nv_buttons.dart';
import 'nv_surfaces.dart';

enum NvTint { gold, jade, amber, lacquer, sapphire, navy, neutral, amethyst }

({Color fg, Color bg}) nvTint(NvTint t) => switch (t) {
  NvTint.gold => (fg: Nv.goldInk, bg: Nv.gold100),
  NvTint.jade => (fg: const Color(0xFF1F6B44), bg: Nv.jadeTint),
  NvTint.amber => (fg: const Color(0xFF8A5A00), bg: Nv.amberTint),
  NvTint.lacquer => (fg: Nv.lacquerDeep, bg: Nv.lacquerTint),
  NvTint.sapphire => (fg: Nv.sapphire, bg: Nv.sapphireTint),
  NvTint.navy => (fg: Nv.gold200, bg: Nv.navy700),
  NvTint.neutral => (fg: Nv.ink2, bg: Nv.ivoryDeep),
  NvTint.amethyst => (fg: Colors.white, bg: Nv.amethyst),
};

/// Small status pill with a dot (ชำระแล้ว · ค้างชำระ · สต็อกต่ำ).
class NvBadge extends StatelessWidget {
  final String label;
  final NvTint tint;
  final bool dot;
  final IconData? icon;
  const NvBadge(this.label, {super.key, this.tint = NvTint.gold, this.dot = true, this.icon});

  @override
  Widget build(BuildContext context) {
    final c = nvTint(tint);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(Nv.rPill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: c.fg),
            const SizedBox(width: 5),
          ] else if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: c.fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(fontFamily: Nv.fontUi, fontSize: 12, fontWeight: FontWeight.w600, color: c.fg, height: 1.2),
          ),
        ],
      ),
    );
  }
}

/// Filter chip — selected = navy pill with gold text (like the web nav).
class NvChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final int? count;
  final bool onNight;
  const NvChip(this.label, {super.key, this.selected = false, this.onTap, this.icon, this.count, this.onNight = false});

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Nv.gold200 : (onNight ? Nv.onNight2 : Nv.ink2);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(Nv.rPill),
      child: InkWell(
        borderRadius: BorderRadius.circular(Nv.rPill),
        onTap: onTap,
        child: AnimatedContainer(
          duration: Nv.fast,
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            gradient: selected ? Nv.btnNavy : null,
            color: selected ? null : (onNight ? Colors.white.withValues(alpha: 0.05) : Nv.paper),
            borderRadius: BorderRadius.circular(Nv.rPill),
            border: Border.all(color: selected ? Nv.gold500.withValues(alpha: 0.7) : (onNight ? Nv.lineNight : Nv.line)),
            boxShadow: selected ? Nv.tintGlow(Nv.navy700, 0.7) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: selected ? Nv.gold300 : (onNight ? Nv.gold300 : Nv.goldInk)),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: TextStyle(fontFamily: Nv.fontUi, fontSize: 13.5, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: fg),
              ),
              if (count != null) ...[
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected ? Nv.gold400.withValues(alpha: 0.2) : (onNight ? Colors.white.withValues(alpha: 0.08) : Nv.ivoryDeep),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: Nv.money(11, color: selected ? Nv.gold200 : (onNight ? Nv.onNight2 : Nv.ink3), weight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Segmented control (2–5 options) — gold thumb on an ivory track.
class NvSegmented<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;
  final bool onNight;
  const NvSegmented({super.key, required this.options, required this.value, required this.onChanged, this.onNight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: onNight ? Colors.white.withValues(alpha: 0.06) : Nv.ivoryDeep,
        borderRadius: BorderRadius.circular(Nv.rPill),
        border: Border.all(color: onNight ? Nv.lineNight : Colors.transparent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final o in options)
            GestureDetector(
              onTap: () => onChanged(o.$1),
              child: AnimatedContainer(
                duration: Nv.fast,
                curve: Nv.ease,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: o.$1 == value ? Nv.btnGold : null,
                  borderRadius: BorderRadius.circular(Nv.rPill),
                  boxShadow: o.$1 == value ? Nv.goldGlow(0.5) : null,
                ),
                child: Text(
                  o.$2,
                  style: TextStyle(
                    fontFamily: Nv.fontUi,
                    fontSize: 13.5,
                    fontWeight: o.$1 == value ? FontWeight.w700 : FontWeight.w500,
                    color: o.$1 == value ? const Color(0xFF1A1405) : (onNight ? Nv.onNight2 : Nv.ink2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// KPI tile: 3D art (or icon), label, big mono value, optional delta/caption.
class NvStatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? art; // NvAssets icon key
  final IconData? icon;
  final String? caption;
  final NvTint tint;
  final bool night;
  final VoidCallback? onTap;

  const NvStatTile({
    super.key,
    required this.label,
    required this.value,
    this.art,
    this.icon,
    this.caption,
    this.tint = NvTint.gold,
    this.night = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final body = Row(
      children: [
        if (art != null)
          NvArt.icon(art!, size: 54)
        else if (icon != null)
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: nvTint(tint).bg, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, size: 19, color: nvTint(tint).fg),
          ),
        if (art != null || icon != null) const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Nv.ui(12.5, color: night ? Nv.onNight3 : Nv.ink3, weight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: Nv.money(24, color: night ? Nv.gold200 : Nv.ink)),
              ),
              if (caption != null) ...[
                const SizedBox(height: 3),
                Text(
                  caption!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Nv.ui(11.5, color: night ? Nv.onNight3 : nvTint(tint).fg, weight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
      ],
    );
    return night
        ? NvNightCard(padding: const EdgeInsets.all(16), onTap: onTap, child: body)
        : NvSheet(padding: const EdgeInsets.all(16), onTap: onTap, child: body);
  }
}

/// Page header: optional 3D art, eyebrow, Trirong title, subtitle, actions.
class NvPageHeader extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final String? subtitle;
  final String? art;
  final List<Widget> actions;
  final bool onNight;

  const NvPageHeader({super.key, required this.title, this.eyebrow, this.subtitle, this.art, this.actions = const [], this.onNight = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (art != null) ...[NvArt.icon(art!, size: 60), const SizedBox(width: 14)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (eyebrow != null) ...[Text(eyebrow!, style: Nv.eyebrow(color: onNight ? Nv.gold300 : Nv.goldInk)), const SizedBox(height: 3)],
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Nv.display(26, color: onNight ? Nv.onNight : Nv.ink),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Nv.ui(13.5, color: onNight ? Nv.onNight3 : Nv.ink3),
                ),
              ],
            ],
          ),
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(width: 12),
          Wrap(spacing: 10, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: actions),
        ],
      ],
    );
  }
}

/// Section title inside a page / card.
class NvSectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;
  final Widget? action;
  final bool onNight;
  final IconData? icon;
  const NvSectionTitle(this.title, {super.key, this.trailing, this.action, this.onNight = false, this.icon});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        if (icon != null) ...[Icon(icon, size: 15, color: onNight ? Nv.gold300 : Nv.goldInk), const SizedBox(width: 8)],
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(gradient: Nv.btnGold, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: Nv.ui(15.5, color: onNight ? Nv.onNight : Nv.ink, weight: FontWeight.w700),
          ),
        ),
        if (trailing != null) Text(trailing!, style: Nv.ui(12.5, color: onNight ? Nv.onNight3 : Nv.ink3)),
        ?action,
      ],
    ),
  );
}

/// Empty state with a mascot pose (empty · search · sleepy · chef · gift · clock …).
class NvEmptyState extends StatelessWidget {
  final String mascot;
  final String title;
  final String? message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final bool onNight;
  final double size;

  const NvEmptyState({
    super.key,
    this.mascot = 'empty',
    required this.title,
    this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.onNight = false,
    this.size = 170,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NvArt.mascot(mascot, height: size),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Nv.display(19, color: onNight ? Nv.onNight : Nv.ink),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: Nv.ui(13.5, color: onNight ? Nv.onNight3 : Nv.ink3, height: 1.45),
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              NvButton.gold(actionLabel!, icon: actionIcon, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

/// Search box (controller-friendly; clears with ×).
class NvSearchField extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextEditingController? controller;
  final bool autofocus;
  final bool onNight;
  final FocusNode? focusNode;
  final IconData icon;

  const NvSearchField({
    super.key,
    this.hint = 'ค้นหา…',
    required this.onChanged,
    this.onSubmitted,
    this.controller,
    this.autofocus = false,
    this.onNight = false,
    this.focusNode,
    this.icon = NvIcons.search,
  });

  @override
  State<NvSearchField> createState() => _NvSearchFieldState();
}

class _NvSearchFieldState extends State<NvSearchField> {
  late final TextEditingController _c = widget.controller ?? TextEditingController();

  @override
  void dispose() {
    if (widget.controller == null) _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final night = widget.onNight;
    return TextField(
      controller: _c,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onChanged: (v) {
        widget.onChanged(v);
        setState(() {});
      },
      onSubmitted: widget.onSubmitted,
      style: Nv.ui(14.5, color: night ? Nv.onNight : Nv.ink),
      cursorColor: Nv.gold500,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: Nv.ui(14, color: night ? Nv.onNight3 : Nv.ink4),
        filled: true,
        fillColor: night ? Colors.white.withValues(alpha: 0.06) : Nv.paper,
        prefixIcon: Icon(widget.icon, size: 16, color: night ? Nv.gold300 : Nv.goldInk),
        suffixIcon: _c.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(NvIcons.xmark, size: 14, color: night ? Nv.onNight3 : Nv.ink3),
                onPressed: () {
                  _c.clear();
                  widget.onChanged('');
                  setState(() {});
                },
              ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Nv.rPill),
          borderSide: BorderSide(color: night ? Nv.lineNight : Nv.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Nv.rPill),
          borderSide: BorderSide(color: night ? Nv.lineNight : Nv.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Nv.rPill),
          borderSide: const BorderSide(color: Nv.gold500, width: 1.6),
        ),
      ),
    );
  }
}

/// Labelled text field for forms/dialogs.
class NvField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboard;
  final bool obscure;
  final int maxLines;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? formatters;
  final bool autofocus;
  final String? suffixText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  const NvField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.icon,
    this.keyboard,
    this.obscure = false,
    this.maxLines = 1,
    this.validator,
    this.formatters,
    this.autofocus = false,
    this.suffixText,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
  });

  /// Digits only (prices, qty, PIN).
  static final digits = <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: Nv.ui(12.5, color: Nv.ink2, weight: FontWeight.w600),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          obscureText: obscure,
          maxLines: obscure ? 1 : maxLines,
          validator: validator,
          inputFormatters: formatters,
          autofocus: autofocus,
          enabled: enabled,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          style: Nv.ui(14.5),
          cursorColor: Nv.gold600,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon == null ? null : Icon(icon, size: 15, color: Nv.goldInk),
            suffixText: suffixText,
          ),
        ),
      ],
    );
  }
}

/// Circle avatar with initials on a hue (staff / members).
class NvAvatar extends StatelessWidget {
  final String text;
  final int hue;
  final double size;
  final bool ring;
  const NvAvatar(this.text, {super.key, this.hue = 40, this.size = 40, this.ring = false});

  @override
  Widget build(BuildContext context) {
    final c1 = HSLColor.fromAHSL(1, hue.toDouble(), 0.42, 0.42).toColor();
    final c2 = HSLColor.fromAHSL(1, hue.toDouble(), 0.5, 0.26).toColor();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c1, c2]),
        border: Border.all(color: ring ? Nv.gold400 : Colors.white.withValues(alpha: 0.6), width: ring ? 2 : 1),
      ),
      child: Text(
        text,
        style: TextStyle(fontFamily: Nv.fontUi, fontSize: size * 0.42, fontWeight: FontWeight.w700, color: Colors.white, height: 1),
      ),
    );
  }
}

/// ฿ amount in mono/tnum.
class NvMoney extends StatelessWidget {
  final int amount;
  final double size;
  final Color? color;
  final bool decimals;
  final FontWeight weight;
  const NvMoney(this.amount, {super.key, this.size = 16, this.color, this.decimals = false, this.weight = FontWeight.w700});

  @override
  Widget build(BuildContext context) => Text(
    baht(amount, decimals: decimals),
    style: Nv.money(size, color: color ?? Nv.ink, weight: weight),
  );
}

/// "label ........ value" row for summaries / receipts / settings.
class NvKeyValue extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;
  final bool onNight;
  final Color? valueColor;
  final bool mono;
  const NvKeyValue(this.label, this.value, {super.key, this.strong = false, this.onNight = false, this.valueColor, this.mono = true});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Nv.ui(
              strong ? 15 : 13.5,
              color: onNight ? (strong ? Nv.onNight : Nv.onNight2) : (strong ? Nv.ink : Nv.ink3),
              weight: strong ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: mono
              ? Nv.money(strong ? 17 : 14, color: valueColor ?? (onNight ? Nv.onNight : Nv.ink), weight: strong ? FontWeight.w700 : FontWeight.w600)
              : Nv.ui(14, color: valueColor ?? (onNight ? Nv.onNight : Nv.ink), weight: FontWeight.w600),
        ),
      ],
    ),
  );
}

/// Tiny quantity stepper (− 2 +).
class NvStepper extends StatelessWidget {
  final int value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final bool onNight;
  const NvStepper({super.key, required this.value, this.onMinus, this.onPlus, this.onNight = false});

  @override
  Widget build(BuildContext context) {
    // 36 px visual, 44 px touch target (Material / Apple minimum for fingers)
    Widget b(IconData i, VoidCallback? f) => InkResponse(
      onTap: f,
      radius: 24,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: onNight ? Colors.white.withValues(alpha: 0.07) : Nv.paper,
            border: Border.all(color: onNight ? Nv.lineNight : Nv.line),
          ),
          child: Icon(i, size: 13, color: f == null ? Nv.ink4 : (onNight ? Nv.gold200 : Nv.ink2)),
        ),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        b(NvIcons.minus, onMinus),
        SizedBox(
          width: 34,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: Nv.money(15, color: onNight ? Nv.onNight : Nv.ink),
          ),
        ),
        b(NvIcons.plus, onPlus),
      ],
    );
  }
}
