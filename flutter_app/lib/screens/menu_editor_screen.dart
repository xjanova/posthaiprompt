// Thaiprompt POS — Menu & product editor (/menu-editor) · Nova.
//
// Left: categories (store.sortedCategories + a "ไม่มีหมวด" bucket that also
// catches orphan category ids) with product counts — add, rename / re-icon,
// move up/down, delete (products become uncategorised). Right: search +
// availability filter over real products (picture, code, price, cost → margin,
// stock, on/off toggle). Tap a product or "เพิ่มเมนูใหม่" → full-height editor:
// name, price, cost, category, code (auto for new), barcode, tag, food-art
// picture, description, availability, stock tracking (+ opening stock through
// the ledger for new items) and option groups (required / multi, choices with
// price deltas, reorder / remove). Delete needs a manager PIN + confirm.
//
// by xman studio

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../models/catalog_models.dart';
import '../models/extra_models.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';

enum _Avail { all, on, off }

/// Bucket id for products without a (valid) category.
const String _kNoCat = '';

bool _isUncategorised(PosStore s, Product p) => p.categoryId.isEmpty || s.categoryById(p.categoryId) == null;

/// (label, color) for the margin readout.
(String, Color) _marginOf(int price, int cost) {
  if (cost <= 0) return ('ยังไม่ใส่ทุน', nvTint(NvTint.amber).fg);
  if (price <= 0) return ('—', Nv.ink3);
  final pct = ((price - cost) * 100 / price).round();
  final c = pct < 0 ? Nv.lacquer : (pct < 20 ? nvTint(NvTint.amber).fg : nvTint(NvTint.jade).fg);
  return ('กำไร $pct%', c);
}

class MenuEditorScreen extends StatefulWidget {
  const MenuEditorScreen({super.key});

  @override
  State<MenuEditorScreen> createState() => _MenuEditorScreenState();
}

class _MenuEditorScreenState extends State<MenuEditorScreen> {
  String? _cat; // null = all · '' = uncategorised · else category id
  String _q = '';
  _Avail _avail = _Avail.all;
  // owned here so the query survives wide ↔ narrow layout switches
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // ───────────────────────── category actions ─────────────────────────

  Future<void> _editCategory(Category? c) async {
    final res = await showNvDialog<(String, String)>(
      context,
      title: c == null ? 'เพิ่มหมวดหมู่' : 'แก้ไขหมวดหมู่',
      art: 'menu',
      maxWidth: 480,
      body: _CategoryForm(initial: c),
    );
    if (res == null || !mounted) return;
    final store = AppScope.read(context);
    if (c == null) {
      final nc = store.addCategory(res.$1, iconKey: res.$2);
      setState(() => _cat = nc.id);
      nvToast(context, 'เพิ่มหมวด "${nc.name}" แล้ว', kind: NvToastKind.success);
    } else {
      store.updateCategory(c, name: res.$1, iconKey: res.$2);
      nvToast(context, 'บันทึกหมวด "${c.name}" แล้ว', kind: NvToastKind.success);
    }
  }

  Future<void> _deleteCategory(Category c) async {
    final store = AppScope.read(context);
    final n = store.productCountIn(c.id);
    final ok = await showNvConfirm(
      context,
      title: 'ลบหมวด "${c.name}"?',
      message: n > 0
          ? 'สินค้า $n รายการในหมวดนี้จะย้ายไปอยู่ "ไม่มีหมวด"\nตัวสินค้าไม่ถูกลบ'
          : 'หมวดนี้ยังไม่มีสินค้า ลบได้ทันที',
      confirmLabel: 'ลบหมวด',
    );
    if (!ok || !mounted) return;
    store.deleteCategory(c);
    if (_cat == c.id) setState(() => _cat = null);
    nvToast(context, 'ลบหมวด "${c.name}" แล้ว', kind: NvToastKind.success);
  }

  void _moveCategory(Category c, int delta) => AppScope.read(context).moveCategory(c, delta);

  /// Narrow layouts: the category manager opens as a dialog.
  void _openCategoryManager() {
    showNvDialog<void>(
      context,
      title: 'หมวดหมู่',
      art: 'menu',
      maxWidth: 440,
      body: SizedBox(
        height: 420,
        child: Builder(
          builder: (dctx) => _CategoryPanel(
            selected: _cat,
            framed: false,
            onSelect: (id) {
              setState(() => _cat = id);
              Navigator.of(dctx).pop();
            },
            onAdd: () => _editCategory(null),
            onEdit: _editCategory,
            onMove: _moveCategory,
            onDelete: _deleteCategory,
          ),
        ),
      ),
      actions: (ctx) => [NvButton.soft('ปิด', onPressed: () => Navigator.of(ctx).pop())],
    );
  }

  // ───────────────────────── product actions ─────────────────────────

  Future<void> _openEditor(Product? p) async {
    final store = AppScope.read(context);
    final code = p?.code ?? store.nextProductCode();
    final defaultCat = (p == null && _cat != null && _cat!.isNotEmpty) ? _cat : null;
    final msg = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierColor: Nv.navy950.withValues(alpha: 0.55),
      builder: (_) => _ProductEditor(product: p, code: code, defaultCategoryId: defaultCat),
    );
    if (msg == null || !mounted) return;
    nvToast(context, msg, kind: NvToastKind.success);
  }

  void _toggle(Product p, bool on) {
    final store = AppScope.read(context);
    final fresh = store.productByCode(p.code);
    if (fresh == null) return;
    store.setProductAvailable(fresh, on);
    nvToast(context, on ? 'เปิดขาย "${p.name}" แล้ว' : 'ปิดขาย "${p.name}" ชั่วคราว', kind: on ? NvToastKind.success : NvToastKind.info);
  }

  // ───────────────────────── build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final cats = store.sortedCategories;
    final catIndex = {for (var i = 0; i < cats.length; i++) cats[i].id: i};
    // a deleted / unknown selection falls back to "all" (never mutate in build)
    final effCat = (_cat != null && _cat!.isNotEmpty && store.categoryById(_cat!) == null) ? null : _cat;

    final q = _q.trim().toLowerCase();
    final list = store.products.where((p) {
      final key = _isUncategorised(store, p) ? _kNoCat : p.categoryId;
      if (effCat != null && key != effCat) return false;
      if (_avail == _Avail.on && !p.available) return false;
      if (_avail == _Avail.off && p.available) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) || p.code.toLowerCase().contains(q) || p.barcode.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) {
        final ca = catIndex[a.categoryId] ?? 1 << 20;
        final cb = catIndex[b.categoryId] ?? 1 << 20;
        return ca != cb ? ca.compareTo(cb) : a.name.compareTo(b.name);
      });

    final onCount = store.products.where((p) => p.available).length;

    return NvScaffold(
      title: 'เมนูและสินค้า',
      eyebrow: 'สินค้าและสต็อก',
      subtitle: '${store.products.length} รายการ · ${cats.length} หมวด · เปิดขาย $onCount',
      art: 'menu',
      actions: [
        NvButton.ghost('คลังสินค้า', icon: NvIcons.inventory, onPressed: () => context.go('/inventory')),
        NvButton.gold('เพิ่มเมนูใหม่', icon: NvIcons.plus, onPressed: () => _openEditor(null)),
      ],
      body: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 900;
        final products = _ProductsArea(
          store: store,
          list: list,
          wideRows: (wide ? c.maxWidth - 298 : c.maxWidth) >= 740, // products area width
          search: _search,
          avail: _avail,
          onQuery: (v) => setState(() => _q = v),
          onAvail: (v) => setState(() => _avail = v),
          onOpen: _openEditor,
          onToggle: _toggle,
          onAdd: () => _openEditor(null),
          filtered: q.isNotEmpty || effCat != null || _avail != _Avail.all,
        );
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 280,
                child: _CategoryPanel(
                  selected: effCat,
                  onSelect: (id) => setState(() => _cat = id),
                  onAdd: () => _editCategory(null),
                  onEdit: _editCategory,
                  onMove: _moveCategory,
                  onDelete: _deleteCategory,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(child: products),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 42, child: _categoryChips(store, cats, effCat)),
            const SizedBox(height: 10),
            Expanded(child: products),
          ],
        );
      }),
    );
  }

  Widget _categoryChips(PosStore store, List<Category> cats, String? effCat) {
    final uncat = store.products.where((p) => _isUncategorised(store, p)).length;
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        NvChip('ทั้งหมด', selected: effCat == null, count: store.products.length, onTap: () => setState(() => _cat = null)),
        for (final c in cats) ...[
          const SizedBox(width: 8),
          NvChip(c.name, icon: c.icon, selected: effCat == c.id, count: store.productCountIn(c.id), onTap: () => setState(() => _cat = c.id)),
        ],
        const SizedBox(width: 8),
        NvChip('ไม่มีหมวด', selected: effCat == _kNoCat, count: uncat, onTap: () => setState(() => _cat = _kNoCat)),
        const SizedBox(width: 8),
        NvChip('จัดการหมวด', icon: NvIcons.sliders, onTap: _openCategoryManager),
      ],
    );
  }
}

// ═════════════════════════════ categories ═════════════════════════════

class _CategoryPanel extends StatelessWidget {
  final String? selected;
  final bool framed;
  final ValueChanged<String?> onSelect;
  final VoidCallback onAdd;
  final ValueChanged<Category> onEdit;
  final void Function(Category c, int delta) onMove;
  final ValueChanged<Category> onDelete;

  const _CategoryPanel({
    required this.selected,
    required this.onSelect,
    required this.onAdd,
    required this.onEdit,
    required this.onMove,
    required this.onDelete,
    this.framed = true,
  });

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final cats = store.sortedCategories;
    final uncat = store.products.where((p) => _isUncategorised(store, p)).length;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NvSectionTitle(
          'หมวดหมู่',
          trailing: '${cats.length} หมวด',
          action: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: NvIconButton(NvIcons.plus, size: 34, tooltip: 'เพิ่มหมวดหมู่', onPressed: onAdd),
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              _CatTile(
                label: 'ทั้งหมด',
                icon: NvIcons.grid,
                count: store.products.length,
                selected: selected == null,
                onTap: () => onSelect(null),
              ),
              for (var i = 0; i < cats.length; i++)
                _CatTile(
                  label: cats[i].name,
                  icon: cats[i].icon,
                  count: store.productCountIn(cats[i].id),
                  selected: selected == cats[i].id,
                  onTap: () => onSelect(cats[i].id),
                  menu: PopupMenuButton<String>(
                    tooltip: 'จัดการหมวด',
                    icon: const Icon(NvIcons.ellipsisV, size: 14, color: Nv.ink3),
                    onSelected: (v) {
                      final c = cats[i];
                      switch (v) {
                        case 'edit':
                          onEdit(c);
                        case 'up':
                          onMove(c, -1);
                        case 'down':
                          onMove(c, 1);
                        case 'delete':
                          onDelete(c);
                      }
                    },
                    itemBuilder: (_) => [
                      _menuItem('edit', NvIcons.edit, 'เปลี่ยนชื่อ / ไอคอน'),
                      _menuItem('up', NvIcons.arrowUp, 'เลื่อนขึ้น', enabled: i > 0),
                      _menuItem('down', NvIcons.arrowDown, 'เลื่อนลง', enabled: i < cats.length - 1),
                      const PopupMenuDivider(),
                      _menuItem('delete', NvIcons.trash, 'ลบหมวด', danger: true),
                    ],
                  ),
                ),
              _CatTile(
                label: 'ไม่มีหมวด',
                icon: NvIcons.boxOpen,
                count: uncat,
                selected: selected == _kNoCat,
                muted: true,
                onTap: () => onSelect(_kNoCat),
              ),
              if (cats.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 14, 6, 6),
                  child: Text('ยังไม่มีหมวดหมู่ — แตะ + เพื่อสร้างหมวดแรก เช่น "เครื่องดื่ม" หรือ "อาหารจานเดียว"',
                      style: Nv.ui(12.5, color: Nv.ink3, height: 1.45)),
                ),
            ],
          ),
        ),
      ],
    );
    return framed ? NvSheet(padding: const EdgeInsets.fromLTRB(14, 14, 10, 10), child: content) : content;
  }

  static PopupMenuItem<String> _menuItem(String v, IconData i, String t, {bool enabled = true, bool danger = false}) =>
      PopupMenuItem<String>(
        value: v,
        enabled: enabled,
        child: Row(children: [
          Icon(i, size: 13, color: danger ? Nv.lacquer : (enabled ? Nv.goldInk : Nv.ink4)),
          const SizedBox(width: 10),
          Text(t, style: Nv.ui(14, color: danger ? Nv.lacquer : (enabled ? Nv.ink : Nv.ink4))),
        ]),
      );
}

class _CatTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final int count;
  final bool selected;
  final bool muted;
  final VoidCallback onTap;
  final Widget? menu;

  const _CatTile({
    required this.label,
    required this.icon,
    required this.count,
    required this.selected,
    required this.onTap,
    this.muted = false,
    this.menu,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Nv.rSm),
        child: InkWell(
          borderRadius: BorderRadius.circular(Nv.rSm),
          onTap: onTap,
          child: AnimatedContainer(
            duration: Nv.fast,
            height: 48,
            padding: EdgeInsets.only(left: 8, right: menu == null ? 10 : 0),
            decoration: BoxDecoration(
              color: selected ? Nv.gold100 : Colors.transparent,
              borderRadius: BorderRadius.circular(Nv.rSm),
              border: Border.all(color: selected ? Nv.gold500.withValues(alpha: 0.7) : Colors.transparent),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: muted ? null : Nv.btnNavy,
                    color: muted ? Nv.ivoryDeep : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 14, color: muted ? Nv.ink3 : Nv.gold300),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Nv.ui(14, weight: selected ? FontWeight.w700 : FontWeight.w500, color: muted ? Nv.ink2 : Nv.ink)),
                ),
                Text('$count', style: Nv.money(12.5, color: Nv.ink3, weight: FontWeight.w600)),
                ?menu,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Add / edit a category: name + icon. Pops `(name, iconKey)`.
class _CategoryForm extends StatefulWidget {
  final Category? initial;
  const _CategoryForm({this.initial});

  @override
  State<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<_CategoryForm> {
  late final TextEditingController _name = TextEditingController(text: widget.initial?.name ?? '');
  late String _icon = widget.initial?.iconKey ?? 'tag';
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'กรุณาใส่ชื่อหมวด');
      return;
    }
    final store = AppScope.read(context);
    final dup = store.categories.any((c) => c.id != widget.initial?.id && c.name.trim().toLowerCase() == name.toLowerCase());
    if (dup) {
      setState(() => _error = 'มีหมวดชื่อ "$name" อยู่แล้ว');
      return;
    }
    Navigator.of(context).pop((name, _icon));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NvField(
          label: 'ชื่อหมวด *',
          controller: _name,
          autofocus: true,
          hint: 'เช่น เครื่องดื่ม · อาหารจานเดียว · ของหวาน',
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('ไอคอน', style: Nv.ui(12.5, color: Nv.ink2, weight: FontWeight.w600)),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in kCategoryIcons.entries)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _icon = e.key),
                child: AnimatedContainer(
                  duration: Nv.fast,
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: _icon == e.key ? Nv.btnNavy : null,
                    color: _icon == e.key ? null : Nv.paper,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _icon == e.key ? Nv.gold500 : Nv.line, width: _icon == e.key ? 1.6 : 1),
                  ),
                  child: Icon(e.value, size: 17, color: _icon == e.key ? Nv.gold300 : Nv.ink2),
                ),
              ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: Nv.ui(13, color: Nv.lacquer, weight: FontWeight.w600)),
        ],
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 10,
          runSpacing: 10,
          children: [
            NvButton.soft('ยกเลิก', onPressed: () => Navigator.of(context).pop()),
            NvButton.gold('บันทึก', icon: NvIcons.check, onPressed: _submit),
          ],
        ),
      ],
    );
  }
}

// ═════════════════════════════ products ═════════════════════════════

class _ProductsArea extends StatelessWidget {
  final PosStore store;
  final List<Product> list;
  final bool wideRows;
  final TextEditingController search;
  final _Avail avail;
  final bool filtered;
  final ValueChanged<String> onQuery;
  final ValueChanged<_Avail> onAvail;
  final ValueChanged<Product> onOpen;
  final void Function(Product p, bool on) onToggle;
  final VoidCallback onAdd;

  const _ProductsArea({
    required this.store,
    required this.list,
    required this.wideRows,
    required this.search,
    required this.avail,
    required this.filtered,
    required this.onQuery,
    required this.onAvail,
    required this.onOpen,
    required this.onToggle,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final seg = NvSegmented<_Avail>(
      options: const [(_Avail.all, 'ทั้งหมด'), (_Avail.on, 'เปิดขาย'), (_Avail.off, 'ปิดขาย')],
      value: avail,
      onChanged: onAvail,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(builder: (context, c) {
          final field = NvSearchField(hint: 'ค้นหาชื่อเมนู รหัส หรือบาร์โค้ด', controller: search, onChanged: onQuery);
          if (c.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [field, const SizedBox(height: 8), Align(alignment: Alignment.centerLeft, child: seg)],
            );
          }
          return Row(children: [Expanded(child: field), const SizedBox(width: 12), seg]);
        }),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            store.products.isEmpty ? 'ยังไม่มีเมนู' : 'แสดง ${list.length} จาก ${store.products.length} รายการ',
            style: Nv.ui(12.5, color: Nv.ink3),
          ),
        ),
        Expanded(
          child: store.products.isEmpty
              ? NvEmptyState(
                  mascot: 'present',
                  title: 'ยังไม่มีเมนูในร้าน',
                  message: 'เพิ่มเมนูแรกพร้อมราคา ต้นทุน รูป และตัวเลือกเสริม แล้วเมนูจะขึ้นที่หน้าขายทันที',
                  actionLabel: 'เพิ่มเมนูใหม่',
                  actionIcon: NvIcons.plus,
                  onAction: onAdd,
                )
              : list.isEmpty
                  ? NvEmptyState(
                      mascot: 'search',
                      title: 'ไม่พบเมนูตามตัวกรอง',
                      message: filtered ? 'ลองเปลี่ยนคำค้น หมวด หรือสถานะการขาย' : null,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final p = list[i];
                        final cat = store.categoryById(p.categoryId);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ProductRow(
                            p: p,
                            catName: cat?.name ?? 'ไม่มีหมวด',
                            catIcon: cat?.icon ?? NvIcons.tag,
                            wide: wideRows,
                            onTap: () => onOpen(p),
                            onToggle: (v) => onToggle(p, v),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  final Product p;
  final String catName;
  final IconData catIcon;
  final bool wide;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  const _ProductRow({
    required this.p,
    required this.catName,
    required this.catIcon,
    required this.wide,
    required this.onTap,
    required this.onToggle,
  });

  Widget _stock() {
    if (!p.trackStock) return Text('ไม่ติดตาม', style: Nv.ui(12.5, color: Nv.ink4, weight: FontWeight.w600));
    final c = p.stock <= 0 ? Nv.lacquer : (p.isLowStock ? nvTint(NvTint.amber).fg : Nv.ink);
    return Text(p.stock <= 0 ? 'หมด' : groupDigits(p.stock), style: Nv.money(16, color: c));
  }

  @override
  Widget build(BuildContext context) {
    final (mLabel, mColor) = _marginOf(p.price, p.cost);
    final toggle = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(value: p.available, onChanged: onToggle),
        if (wide)
          SizedBox(
            width: 52,
            child: Text(p.available ? 'เปิดขาย' : 'ปิดขาย',
                style: Nv.ui(12.5, color: p.available ? nvTint(NvTint.jade).fg : Nv.ink3, weight: FontWeight.w600)),
          ),
      ],
    );
    final title = Row(
      children: [
        Flexible(
          child: Text(p.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Nv.ui(15, weight: FontWeight.w700, color: p.available ? Nv.ink : Nv.ink3)),
        ),
        if (p.tag != null) ...[const SizedBox(width: 8), NvBadge(p.tag!, tint: NvTint.gold, dot: false)],
        if (!p.available) ...[const SizedBox(width: 8), const NvBadge('ปิดขาย', tint: NvTint.neutral)],
      ],
    );
    final meta = Text(
      [
        p.code,
        catName,
        if (p.barcode.isNotEmpty) 'บาร์โค้ด ${p.barcode}',
        if (p.hasOptions) 'ตัวเลือก ${p.options.length} กลุ่ม',
      ].join(' · '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Nv.ui(12.5, color: Nv.ink3),
    );

    return NvSheet(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      radius: Nv.rMd,
      onTap: onTap,
      child: wide
          ? Row(
              children: [
                _Thumb(p: p, icon: catIcon, size: 54),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [title, const SizedBox(height: 3), meta],
                  ),
                ),
                SizedBox(
                  width: 104,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(baht(p.price), style: Nv.money(17)),
                      Text('ราคาขาย', style: Nv.ui(11.5, color: Nv.ink4)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(p.cost > 0 ? 'ทุน ${baht(p.cost)}' : 'ทุน —', style: Nv.money(13, color: Nv.ink2, weight: FontWeight.w600)),
                      Text(mLabel, style: Nv.ui(11.5, color: mColor, weight: FontWeight.w600)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 92,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [_stock(), Text('สต็อก', style: Nv.ui(11.5, color: Nv.ink4))],
                  ),
                ),
                const SizedBox(width: 12),
                toggle,
                const Icon(NvIcons.angleRight, size: 13, color: Nv.ink4),
                const SizedBox(width: 4),
              ],
            )
          : Row(
              children: [
                _Thumb(p: p, icon: catIcon, size: 50),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      const SizedBox(height: 2),
                      meta,
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 10,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(baht(p.price), style: Nv.money(15)),
                          Text(mLabel, style: Nv.ui(12, color: mColor, weight: FontWeight.w600)),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Text('สต็อก ', style: Nv.ui(12, color: Nv.ink3)),
                            _stock(),
                          ]),
                        ],
                      ),
                    ],
                  ),
                ),
                toggle,
              ],
            ),
    );
  }
}

/// Product picture: food art → network image → navy tile with the category icon.
class _Thumb extends StatelessWidget {
  final Product p;
  final IconData icon;
  final double size;
  const _Thumb({required this.p, required this.icon, this.size = 54});

  @override
  Widget build(BuildContext context) => _picture(p.art, p.imageUrl, icon, size);
}

Widget _picture(String? art, String? imageUrl, IconData icon, double size) {
  final r = BorderRadius.circular(size * 0.24);
  Widget tile() => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(gradient: Nv.btnNavy, borderRadius: r, border: Border.all(color: Nv.lineNightStrong)),
        child: Icon(icon, size: size * 0.36, color: Nv.gold300),
      );
  if (art != null) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: Nv.ivoryDeep.withValues(alpha: 0.6), borderRadius: r),
      child: NvArt.food(art, size: size, fallbackIcon: icon),
    );
  }
  if (imageUrl != null && imageUrl.isNotEmpty) {
    return ClipRRect(
      borderRadius: r,
      child: Image.network(imageUrl, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, _, _) => tile()),
    );
  }
  return tile();
}

// ═════════════════════════════ product editor ═════════════════════════════

class _ChoiceDraft {
  final TextEditingController label;
  final TextEditingController price;
  _ChoiceDraft(String l, int delta)
      : label = TextEditingController(text: l),
        price = TextEditingController(text: delta == 0 ? '' : '$delta');
  void dispose() {
    label.dispose();
    price.dispose();
  }
}

class _GroupDraft {
  final TextEditingController name;
  bool required;
  bool multi;
  final List<_ChoiceDraft> choices;
  _GroupDraft(String n, {this.required = false, this.multi = false, List<_ChoiceDraft>? choices})
      : name = TextEditingController(text: n),
        choices = choices ?? <_ChoiceDraft>[];
}

const _tags = <(String?, String)>[(null, 'ไม่มี'), ('ขายดี', 'ขายดี'), ('ใหม่', 'ใหม่'), ('พรีเมียม', 'พรีเมียม')];

class _ProductEditor extends StatefulWidget {
  final Product? product; // null = new
  final String code;
  final String? defaultCategoryId;
  const _ProductEditor({required this.product, required this.code, this.defaultCategoryId});

  @override
  State<_ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends State<_ProductEditor> {
  late final Product? _p = widget.product;
  late final TextEditingController _name = TextEditingController(text: _p?.name ?? '');
  late final TextEditingController _price = TextEditingController(text: _p == null ? '' : '${_p.price}');
  late final TextEditingController _cost = TextEditingController(text: (_p?.cost ?? 0) > 0 ? '${_p!.cost}' : '');
  late final TextEditingController _barcode = TextEditingController(text: _p?.barcode ?? '');
  late final TextEditingController _desc = TextEditingController(text: _p?.description ?? '');
  final TextEditingController _stock = TextEditingController();

  late String _categoryId = _p?.categoryId ?? widget.defaultCategoryId ?? '';
  late String? _tag = _p?.tag;
  late String? _art = _p?.art;
  bool _clearImage = false;
  late bool _available = _p?.available ?? true;
  late bool _track = _p?.trackStock ?? true;

  final List<_GroupDraft> _groups = <_GroupDraft>[];
  final List<_GroupDraft> _trashGroups = <_GroupDraft>[];
  final List<_ChoiceDraft> _trashChoices = <_ChoiceDraft>[];

  String? _error;
  bool _dirty = false;
  bool _done = false; // saved / deleted — ignore further taps while the dialog closes

  bool get _isNew => _p == null;

  @override
  void initState() {
    super.initState();
    for (final g in _p?.options ?? const <OptionGroup>[]) {
      _groups.add(_GroupDraft(g.name,
          required: g.required, multi: g.multi, choices: [for (final c in g.choices) _ChoiceDraft(c.label, c.priceDelta)]));
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _price, _cost, _barcode, _desc, _stock]) {
      c.dispose();
    }
    for (final g in [..._groups, ..._trashGroups]) {
      g.name.dispose();
      for (final c in g.choices) {
        c.dispose();
      }
    }
    for (final c in _trashChoices) {
      c.dispose();
    }
    super.dispose();
  }

  void _touch([Object? _]) {
    if (!_dirty || _error != null) {
      setState(() {
        _dirty = true;
        _error = null;
      });
    }
  }

  void _fail(String msg) => setState(() => _error = msg);

  /// Price / cost edits always rebuild (live margin readout).
  void _touchMoney(String _) => setState(() {
        _dirty = true;
        _error = null;
      });

  Future<void> _close() async {
    if (_dirty) {
      final ok = await showNvConfirm(context,
          title: 'ทิ้งการแก้ไข?', message: 'ข้อมูลที่แก้ไว้ในหน้านี้จะไม่ถูกบันทึก', confirmLabel: 'ทิ้งการแก้ไข');
      if (!ok || !mounted) return;
    }
    Navigator.of(context).pop();
  }

  void _save() {
    if (_done) return;
    final store = AppScope.read(context);
    final name = _name.text.trim();
    if (name.isEmpty) return _fail('กรุณาใส่ชื่อเมนู');
    final price = int.tryParse(_price.text.trim());
    if (price == null) return _fail('กรุณาใส่ราคาขายเป็นตัวเลข (บาท)');
    final costText = _cost.text.trim();
    final cost = costText.isEmpty ? 0 : int.tryParse(costText);
    if (cost == null) return _fail('ต้นทุนต้องเป็นตัวเลข (บาท)');
    final barcode = _barcode.text.trim();
    if (barcode.isNotEmpty) {
      for (final o in store.products) {
        if (o.code == widget.code) continue;
        if (o.barcode == barcode || o.code == barcode) {
          return _fail('บาร์โค้ด "$barcode" ซ้ำกับ "${o.name}" (${o.code})');
        }
      }
    }

    final options = <OptionGroup>[];
    for (var i = 0; i < _groups.length; i++) {
      final g = _groups[i];
      final gName = g.name.text.trim();
      if (gName.isEmpty) return _fail('ตั้งชื่อกลุ่มตัวเลือกที่ ${i + 1} (เช่น ขนาด / ความหวาน)');
      if (g.choices.isEmpty) return _fail('กลุ่ม "$gName" ต้องมีตัวเลือกอย่างน้อย 1 รายการ');
      final choices = <OptionChoice>[];
      for (var j = 0; j < g.choices.length; j++) {
        final label = g.choices[j].label.text.trim();
        if (label.isEmpty) return _fail('กลุ่ม "$gName": ตัวเลือกที่ ${j + 1} ยังไม่มีชื่อ');
        final raw = g.choices[j].price.text.trim();
        final delta = (raw.isEmpty || raw == '-') ? 0 : int.tryParse(raw);
        if (delta == null) return _fail('กลุ่ม "$gName": ราคาเพิ่มของ "$label" ไม่ถูกต้อง');
        choices.add(OptionChoice(label, delta));
      }
      options.add(OptionGroup(name: gName, required: g.required, multi: g.multi, choices: choices));
    }

    final catId = (_categoryId.isEmpty || store.categoryById(_categoryId) == null) ? '' : _categoryId;

    if (_isNew) {
      final initial = _track ? (int.tryParse(_stock.text.trim()) ?? 0) : 0;
      final code = store.productByCode(widget.code) == null ? widget.code : store.nextProductCode();
      final p = Product(
        id: code,
        code: code,
        name: name,
        price: price,
        categoryId: catId,
        hue: stableHue(name),
        tag: _tag,
        barcode: barcode,
        cost: cost,
        art: _art,
        description: _desc.text.trim(),
        available: _available,
        trackStock: _track,
        options: options,
        stock: 0,
      );
      store.upsertProduct(p);
      // opening stock goes through the ledger so the movement is traceable
      if (_track && initial > 0) store.adjustStock(p, initial, type: StockMoveType.receive, reason: 'สต็อกตั้งต้น');
      _done = true;
      Navigator.of(context).pop('เพิ่มเมนู "$name" ($code) แล้ว');
    } else {
      final fresh = store.productByCode(widget.code);
      if (fresh == null) return _fail('เมนูนี้ถูกลบไปแล้ว');
      final base = _clearImage ? fresh.copyWith(imageUrl: null) : fresh;
      store.upsertProduct(base.copyWith(
        name: name,
        price: price,
        categoryId: catId,
        tag: _tag,
        barcode: barcode,
        cost: cost,
        art: _art,
        description: _desc.text.trim(),
        available: _available,
        trackStock: _track,
        options: options,
      ));
      _done = true;
      Navigator.of(context).pop('บันทึก "$name" แล้ว');
    }
  }

  Future<void> _delete() async {
    if (_done) return;
    final p = _p!;
    final mgr = await showManagerPin(context, reason: 'ลบเมนู "${p.name}"');
    if (mgr == null || !mounted) return;
    final ok = await showNvConfirm(
      context,
      title: 'ลบเมนูนี้?',
      message: '"${p.name}" (${p.code}) จะถูกลบออกจากเมนูและตะกร้าที่ค้างอยู่\nบิลเก่ายังเก็บชื่อและราคาไว้ตามเดิม',
      confirmLabel: 'ลบเมนู',
    );
    if (!ok || !mounted) return;
    final store = AppScope.read(context);
    final fresh = store.productByCode(p.code);
    if (fresh != null) {
      if (mgr.id != store.currentStaff?.id) store.log('approve', 'ลบเมนู ${p.name} · อนุมัติโดย ${mgr.name}');
      store.deleteProduct(fresh);
    }
    _done = true;
    Navigator.of(context).pop('ลบเมนู "${p.name}" แล้ว');
  }

  // ── options editing ──

  void _addGroup() => setState(() {
        _groups.add(_GroupDraft('', choices: [_ChoiceDraft('', 0)]));
        _dirty = true;
      });

  void _removeGroup(int i) => setState(() {
        _trashGroups.add(_groups.removeAt(i));
        _dirty = true;
      });

  void _moveGroup(int i, int d) {
    final j = i + d;
    if (j < 0 || j >= _groups.length) return;
    setState(() {
      final g = _groups.removeAt(i);
      _groups.insert(j, g);
      _dirty = true;
    });
  }

  void _addChoice(_GroupDraft g) => setState(() {
        g.choices.add(_ChoiceDraft('', 0));
        _dirty = true;
      });

  void _removeChoice(_GroupDraft g, int i) => setState(() {
        _trashChoices.add(g.choices.removeAt(i));
        _dirty = true;
      });

  void _moveChoice(_GroupDraft g, int i, int d) {
    final j = i + d;
    if (j < 0 || j >= g.choices.length) return;
    setState(() {
      final c = g.choices.removeAt(i);
      g.choices.insert(j, c);
      _dirty = true;
    });
  }

  // ── build ──

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final size = MediaQuery.sizeOf(context);
    final narrow = size.width < 720;
    final cat = store.categoryById(_categoryId);
    final previewIcon = cat?.icon ?? NvIcons.tag;
    final hasImage = (_p?.imageUrl ?? '').isNotEmpty && !_clearImage;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Dialog(
        insetPadding: narrow ? const EdgeInsets.all(10) : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: SizedBox(
          width: 880,
          height: size.height - (narrow ? 20 : 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 14, 12),
                child: Row(
                  children: [
                    _picture(_art, hasImage ? _p?.imageUrl : null, previewIcon, 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_isNew ? 'เพิ่มเมนูใหม่' : 'แก้ไขเมนู', style: Nv.display(21)),
                          Text(
                            _isNew ? 'รหัสสินค้า ${widget.code} (สร้างอัตโนมัติ)' : '${_p!.name} · ${_p.code}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Nv.ui(13, color: Nv.ink3),
                          ),
                        ],
                      ),
                    ),
                    NvIconButton(NvIcons.xmark, tooltip: 'ปิด', onPressed: _close),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(narrow ? 14 : 22, 16, narrow ? 14 : 22, 20),
                  child: _form(store, narrow, hasImage),
                ),
              ),
              const Divider(),
              // ── footer ──
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (_error != null)
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: narrow ? size.width - 60 : 420),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(NvIcons.warning, size: 14, color: Nv.lacquer),
                            const SizedBox(width: 8),
                            Flexible(child: Text(_error!, style: Nv.ui(13, color: Nv.lacquer, weight: FontWeight.w600))),
                          ],
                        ),
                      ),
                    if (!_isNew) NvButton.ghost('ลบเมนู', icon: NvIcons.trash, onPressed: _delete),
                    NvButton.soft('ยกเลิก', onPressed: _close),
                    NvButton.gold(_isNew ? 'เพิ่มเมนู' : 'บันทึก', icon: NvIcons.check, onPressed: _save),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pair(bool narrow, Widget a, Widget b) => narrow
      ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [a, const SizedBox(height: 12), b])
      : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: a), const SizedBox(width: 14), Expanded(child: b)]);

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(t, style: Nv.ui(12.5, color: Nv.ink2, weight: FontWeight.w600)),
      );

  Widget _section(String t, IconData icon, {Widget? action}) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 4),
        child: NvSectionTitle(t, icon: icon, action: action),
      );

  Widget _form(PosStore store, bool narrow, bool hasImage) {
    final price = int.tryParse(_price.text.trim()) ?? 0;
    final cost = int.tryParse(_cost.text.trim()) ?? 0;
    final (mLabel, mColor) = _marginOf(price, cost);
    final cats = store.sortedCategories;
    final catValid = _categoryId.isEmpty || store.categoryById(_categoryId) != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NvSectionTitle('ข้อมูลหลัก', icon: NvIcons.edit),
        NvField(label: 'ชื่อเมนู *', controller: _name, autofocus: _isNew, hint: 'เช่น ชาไทยเย็น', onChanged: _touch),
        const SizedBox(height: 12),
        _pair(
          narrow,
          NvField(
            label: 'ราคาขาย (บาท) *',
            controller: _price,
            keyboard: TextInputType.number,
            formatters: NvField.digits,
            icon: NvIcons.tag,
            onChanged: _touchMoney,
          ),
          NvField(
            label: 'ต้นทุนต่อหน่วย (บาท)',
            controller: _cost,
            keyboard: TextInputType.number,
            formatters: NvField.digits,
            icon: NvIcons.coins,
            hint: 'ใช้คำนวณกำไร',
            onChanged: _touchMoney,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 6),
          child: Text(
            cost > 0 ? 'กำไรต่อชิ้น ${baht(price - cost)} · $mLabel' : 'ใส่ต้นทุนเพื่อดูกำไรต่อชิ้นและรายงานต้นทุนขาย',
            style: Nv.ui(12.5, color: cost > 0 ? mColor : Nv.ink3, weight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        _pair(
          narrow,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label('หมวดหมู่'),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Nv.paper,
                  borderRadius: BorderRadius.circular(Nv.rSm),
                  border: Border.all(color: Nv.line),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: catValid ? _categoryId : _kNoCat,
                    isExpanded: true,
                    icon: const Icon(NvIcons.chevronDown, size: 12, color: Nv.ink3),
                    style: Nv.ui(14.5),
                    dropdownColor: Nv.ivory2,
                    borderRadius: BorderRadius.circular(Nv.rMd),
                    items: [
                      DropdownMenuItem(value: _kNoCat, child: Text('ไม่มีหมวด', style: Nv.ui(14.5, color: Nv.ink3))),
                      for (final c in cats)
                        DropdownMenuItem(
                          value: c.id,
                          child: Row(children: [
                            Icon(c.icon, size: 14, color: Nv.goldInk),
                            const SizedBox(width: 10),
                            Flexible(child: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ]),
                        ),
                    ],
                    onChanged: (v) => setState(() {
                      _categoryId = v ?? _kNoCat;
                      _dirty = true;
                    }),
                  ),
                ),
              ),
              if (!catValid)
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 6),
                  child: Text('หมวดเดิม ($_categoryId) ไม่มีในระบบแล้ว — จะบันทึกเป็น "ไม่มีหมวด"',
                      style: Nv.ui(12, color: nvTint(NvTint.amber).fg, weight: FontWeight.w600)),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label('ป้ายบนการ์ดเมนู'),
              Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: NvSegmented<String?>(
                    options: _tags,
                    value: _tag,
                    onChanged: (v) => setState(() {
                      _tag = v;
                      _dirty = true;
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _pair(
          narrow,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label(_isNew ? 'รหัสสินค้า (อัตโนมัติ)' : 'รหัสสินค้า (แก้ไขไม่ได้)'),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Nv.ivoryDeep.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(Nv.rSm),
                  border: Border.all(color: Nv.line),
                ),
                child: Row(children: [
                  const Icon(NvIcons.lock, size: 13, color: Nv.ink4),
                  const SizedBox(width: 10),
                  Text(widget.code, style: Nv.money(15, color: Nv.ink2)),
                ]),
              ),
            ],
          ),
          NvField(
            label: 'บาร์โค้ด',
            controller: _barcode,
            icon: NvIcons.barcode,
            hint: 'สแกนหรือพิมพ์ (ว่าง = ใช้รหัสสินค้า)',
            formatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
            onChanged: _touch,
          ),
        ),
        const SizedBox(height: 12),
        NvField(label: 'รายละเอียด', controller: _desc, maxLines: 3, hint: 'แสดงในหน้าสั่งเองของลูกค้า', onChanged: _touch),

        // ── picture ──
        _section('รูปเมนู', NvIcons.image),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _picTile(
              label: 'ไม่มีรูป',
              selected: _art == null && !hasImage,
              onTap: () => setState(() {
                _art = null;
                _clearImage = true;
                _dirty = true;
              }),
              child: Icon(store.categoryById(_categoryId)?.icon ?? NvIcons.tag, size: 22, color: Nv.gold300),
              navy: true,
            ),
            if ((_p?.imageUrl ?? '').isNotEmpty)
              _picTile(
                label: 'รูปจากร้านออนไลน์',
                selected: _art == null && hasImage,
                onTap: () => setState(() {
                  _art = null;
                  _clearImage = false;
                  _dirty = true;
                }),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(_p!.imageUrl!, width: 64, height: 64, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(NvIcons.image, size: 22, color: Nv.ink4)),
                ),
              ),
            for (final k in kFoodArt)
              _picTile(
                label: _artLabel(k),
                selected: _art == k,
                onTap: () => setState(() {
                  _art = k;
                  _dirty = true;
                }),
                child: NvArt.food(k, size: 64),
              ),
          ],
        ),

        // ── sale & stock ──
        _section('การขายและสต็อก', NvIcons.inventory),
        _switchRow(
          'เปิดขาย',
          _available ? 'แสดงที่หน้าขายและหน้าสั่งเอง' : 'ซ่อนจากหน้าขายชั่วคราว (ของหมด / ปิดเมนู)',
          _available,
          (v) => setState(() {
            _available = v;
            _dirty = true;
          }),
        ),
        const SizedBox(height: 8),
        _switchRow(
          'ติดตามสต็อก',
          _track ? 'ตัดสต็อกเมื่อขาย · ขายไม่ได้เมื่อหมด' : 'ไม่นับจำนวน (เช่น เครื่องดื่มชงสด)',
          _track,
          (v) => setState(() {
            _track = v;
            _dirty = true;
          }),
        ),
        if (_track) ...[
          const SizedBox(height: 10),
          if (_isNew)
            SizedBox(
              width: narrow ? double.infinity : 280,
              child: NvField(
                label: 'สต็อกตั้งต้น (ชิ้น)',
                controller: _stock,
                keyboard: TextInputType.number,
                formatters: NvField.digits,
                hint: '0',
                icon: NvIcons.boxOpen,
                onChanged: _touch,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'คงเหลือตอนนี้ ${groupDigits(store.productByCode(widget.code)?.stock ?? _p!.stock)} ชิ้น · รับเข้า / ปรับยอด / ตรวจนับ ที่หน้า "คลังสินค้า" เพื่อให้มีประวัติ',
                style: Nv.ui(12.5, color: Nv.ink3, height: 1.4),
              ),
            ),
        ],

        // ── options ──
        _section(
          'ตัวเลือกเสริม',
          NvIcons.listCheck,
          action: NvButton.soft('เพิ่มกลุ่ม', icon: NvIcons.plus, size: NvButtonSize.sm, onPressed: _addGroup),
        ),
        if (_groups.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text('ยังไม่มีตัวเลือก — เช่น ขนาด (เล็ก/ใหญ่ +฿10), ความหวาน, ท็อปปิ้ง',
                style: Nv.ui(12.5, color: Nv.ink3)),
          ),
        for (var gi = 0; gi < _groups.length; gi++) _groupCard(gi, narrow),
      ],
    );
  }

  static String _artLabel(String k) => switch (k) {
        'thai_tea' => 'ชาไทย',
        'coffee' => 'กาแฟ',
        'rice' => 'ข้าว',
        'noodle' => 'เส้น',
        'dessert' => 'ของหวาน',
        'snack' => 'ของทานเล่น',
        'bakery' => 'เบเกอรี่',
        'juice' => 'น้ำผลไม้',
        'grocery' => 'ของชำ',
        _ => k,
      };

  Widget _picTile({required String label, required bool selected, required VoidCallback onTap, required Widget child, bool navy = false}) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: Nv.fast,
        width: 86,
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
        decoration: BoxDecoration(
          color: selected ? Nv.gold100 : Nv.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? Nv.gold500 : Nv.line, width: selected ? 1.8 : 1),
          boxShadow: selected ? Nv.goldGlow(0.4) : null,
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: navy ? BoxDecoration(gradient: Nv.btnNavy, borderRadius: BorderRadius.circular(12)) : null,
              child: child,
            ),
            const SizedBox(height: 4),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Nv.ui(11.5, color: selected ? Nv.goldInk : Nv.ink2, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _switchRow(String title, String sub, bool v, ValueChanged<bool> f) => NvSheet(
        padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
        radius: Nv.rMd,
        color: Nv.paper,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Nv.ui(14.5, weight: FontWeight.w600)),
                  Text(sub, style: Nv.ui(12.5, color: Nv.ink3)),
                ],
              ),
            ),
            Switch(value: v, onChanged: f),
          ],
        ),
      );

  Widget _check(String label, bool v, ValueChanged<bool> f) => InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => f(!v),
        child: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(value: v, onChanged: (x) => f(x ?? false)),
              Text(label, style: Nv.ui(13.5, color: Nv.ink2)),
            ],
          ),
        ),
      );

  Widget _groupCard(int gi, bool narrow) {
    final g = _groups[gi];
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: NvSheet(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        radius: Nv.rMd,
        color: Nv.paper,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(gradient: Nv.btnGold, shape: BoxShape.circle),
                  child: Text('${gi + 1}', style: Nv.money(12, color: const Color(0xFF1A1405))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: g.name,
                    onChanged: _touch,
                    style: Nv.ui(14.5, weight: FontWeight.w600),
                    decoration: const InputDecoration(hintText: 'ชื่อกลุ่ม เช่น ขนาด / ความหวาน / ท็อปปิ้ง'),
                  ),
                ),
                const SizedBox(width: 6),
                NvIconButton(NvIcons.arrowUp, size: 34, tooltip: 'เลื่อนขึ้น', onPressed: gi > 0 ? () => _moveGroup(gi, -1) : null),
                const SizedBox(width: 4),
                NvIconButton(NvIcons.arrowDown,
                    size: 34, tooltip: 'เลื่อนลง', onPressed: gi < _groups.length - 1 ? () => _moveGroup(gi, 1) : null),
                const SizedBox(width: 4),
                NvIconButton(NvIcons.trash, size: 34, tooltip: 'ลบกลุ่ม', color: Nv.lacquer, onPressed: () => _removeGroup(gi)),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              children: [
                _check('ลูกค้าต้องเลือก', g.required, (v) => setState(() {
                      g.required = v;
                      _dirty = true;
                    })),
                _check('เลือกได้หลายอย่าง', g.multi, (v) => setState(() {
                      g.multi = v;
                      _dirty = true;
                    })),
              ],
            ),
            for (var ci = 0; ci < g.choices.length; ci++)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Row(
                  children: [
                    const Icon(NvIcons.angleRight, size: 11, color: Nv.ink4),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: g.choices[ci].label,
                        onChanged: _touch,
                        style: Nv.ui(14),
                        decoration: const InputDecoration(hintText: 'ตัวเลือก เช่น ใหญ่'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: narrow ? 92 : 120,
                      child: TextField(
                        controller: g.choices[ci].price,
                        onChanged: _touch,
                        keyboardType: const TextInputType.numberWithOptions(signed: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d{0,6}'))],
                        style: Nv.money(14, weight: FontWeight.w600),
                        decoration: const InputDecoration(hintText: '0', prefixText: '+฿ '),
                      ),
                    ),
                    const SizedBox(width: 4),
                    NvIconButton(NvIcons.arrowUp,
                        size: 30, tooltip: 'เลื่อนขึ้น', onPressed: ci > 0 ? () => _moveChoice(g, ci, -1) : null),
                    const SizedBox(width: 4),
                    NvIconButton(NvIcons.xmark, size: 30, tooltip: 'ลบตัวเลือก', color: Nv.lacquer, onPressed: () => _removeChoice(g, ci)),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, left: 2),
                child: NvButton.ghost('เพิ่มตัวเลือก', icon: NvIcons.plus, size: NvButtonSize.sm, onPressed: () => _addChoice(g)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
