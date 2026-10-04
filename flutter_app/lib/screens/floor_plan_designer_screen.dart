// Thaiprompt POS — ออกแบบผังร้าน (/floor-designer, managers only).
//
// The same 4:3 floor as the waiter screen (shared FloorGeometry), one zone at
// a time. Drag a table to move it — it snaps to the grid when "จัดตามตาราง"
// is on and is saved to the store on release. Tap a table to edit its number
// (unique), seats, shape and zone, then save. Add tables from the preset
// palette (placed on the first free spot of the current zone with the next
// table number), delete with confirmation. Zones can be added and renamed
// (renaming moves every table in it).
//
// by xman studio

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/extra_models.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';
import 'tablet_waiter_screen.dart' show FloorGeometry, FloorSurface, floorShapeLabel;

class _Preset {
  final String label;
  final TableShape shape;
  final int seats;
  const _Preset(this.label, this.shape, this.seats);
}

const _presets = <_Preset>[
  _Preset('กลม 2 ที่', TableShape.round, 2),
  _Preset('กลม 4 ที่', TableShape.round, 4),
  _Preset('สี่เหลี่ยม 4 ที่', TableShape.square, 4),
  _Preset('โต๊ะยาว 6 ที่', TableShape.rect, 6),
];

const _kDefaultZone = 'ในร้าน';
const _kNewZone = '\u0000new-zone';

Color _busyColor(TableStatus s) => switch (s) {
      TableStatus.free => Nv.ink4,
      TableStatus.seated => Nv.gold500,
      TableStatus.billing => Nv.lacquer,
      TableStatus.reserved => Nv.sapphire,
    };

class FloorPlanDesignerScreen extends StatefulWidget {
  const FloorPlanDesignerScreen({super.key});

  @override
  State<FloorPlanDesignerScreen> createState() => _FloorPlanDesignerScreenState();
}

class _FloorPlanDesignerScreenState extends State<FloorPlanDesignerScreen> {
  String? _zone;
  final List<String> _extraZones = <String>[]; // zones created here that have no table yet
  int? _selected;
  bool _snap = true;

  // drag
  int? _dragging;
  Offset _dragTopLeft = Offset.zero;
  Size _canvas = const Size(840, 630); // last laid-out canvas (for drag / free-spot maths)

  // property draft (pre-filled from the selected table)
  final TextEditingController _number = TextEditingController();
  final TextEditingController _newZone = TextEditingController();
  int _seats = 4;
  TableShape _shape = TableShape.square;
  String _draftZone = _kDefaultZone;
  bool _creatingZone = false;

  @override
  void dispose() {
    _number.dispose();
    _newZone.dispose();
    super.dispose();
  }

  // ── helpers ──

  List<String> _zonesOf(PosStore s) {
    final out = <String>[];
    for (final t in s.tables) {
      if (!out.contains(t.zone)) out.add(t.zone);
    }
    for (final z in _extraZones) {
      if (!out.contains(z)) out.add(z);
    }
    if (out.isEmpty) out.add(_kDefaultZone);
    return out;
  }

  TableInfo? _selectedTable(PosStore s) => _selected == null ? null : s.tableByNumber(_selected!);

  void _loadDraft(TableInfo t) {
    _number.text = '${t.number}';
    _seats = t.seats;
    _shape = t.shape;
    _draftZone = t.zone;
    _creatingZone = false;
    _newZone.clear();
  }

  bool _isDirty(TableInfo? t) {
    if (t == null) return false;
    final zoneChanged = _creatingZone
        ? (_newZone.text.trim().isNotEmpty && _newZone.text.trim() != t.zone)
        : _draftZone != t.zone;
    return _number.text.trim() != '${t.number}' || _seats != t.seats || _shape != t.shape || zoneChanged;
  }

  Future<bool> _confirmDiscard() async {
    final t = _selectedTable(AppScope.read(context));
    if (t == null || !_isDirty(t)) return true;
    return showNvConfirm(
      context,
      title: 'ทิ้งการแก้ไขโต๊ะ ${t.number}?',
      message: 'การแก้ไขที่ยังไม่ได้บันทึกจะหายไป',
      confirmLabel: 'ทิ้งการแก้ไข',
    );
  }

  Future<void> _select(int? number) async {
    if (number == _selected) return;
    final ok = await _confirmDiscard();
    if (!ok || !mounted) return;
    final t = number == null ? null : AppScope.read(context).tableByNumber(number);
    setState(() {
      _selected = t?.number;
      if (t != null) _loadDraft(t);
    });
  }

  // ── zones ──

  Future<void> _switchZone(String z) async {
    if (z == _zone) return;
    final ok = await _confirmDiscard();
    if (!ok || !mounted) return;
    setState(() {
      _zone = z;
      _selected = null;
    });
  }

  Future<void> _addZone() async {
    final ok = await _confirmDiscard();
    if (!ok || !mounted) return;
    final name = await showNvTextDialog(
      context,
      title: 'เพิ่มโซนใหม่',
      subtitle: 'เช่น ระเบียง · ห้อง VIP · ชั้น 2',
      hint: 'ชื่อโซน',
      confirmLabel: 'เพิ่มโซน',
      art: 'table',
    );
    if (name == null || !mounted) return;
    if (name.isEmpty) {
      nvToast(context, 'กรุณาใส่ชื่อโซน', kind: NvToastKind.warning);
      return;
    }
    final zones = _zonesOf(AppScope.read(context));
    setState(() {
      if (!zones.contains(name)) _extraZones.add(name);
      _zone = name;
      _selected = null;
    });
  }

  Future<void> _renameZone(String zone) async {
    final ok = await _confirmDiscard();
    if (!ok || !mounted) return;
    final name = await showNvTextDialog(
      context,
      title: 'เปลี่ยนชื่อโซน',
      subtitle: 'โต๊ะทุกตัวในโซน "$zone" จะย้ายไปอยู่ในชื่อใหม่',
      initial: zone,
      hint: 'ชื่อโซน',
      confirmLabel: 'บันทึก',
      art: 'table',
    );
    if (name == null || !mounted) return;
    if (name.isEmpty || name == zone) return;
    final store = AppScope.read(context);
    final moving = store.tables.where((t) => t.zone == zone).toList();
    for (final t in moving) {
      store.updateTable(t, zone: name);
    }
    setState(() {
      final i = _extraZones.indexOf(zone);
      if (i >= 0) {
        _extraZones[i] = name;
      } else if (moving.isEmpty) {
        _extraZones.add(name);
      }
      _zone = name;
      if (_draftZone == zone) _draftZone = name;
    });
    nvToast(context, 'เปลี่ยนชื่อโซนเป็น "$name" แล้ว', kind: NvToastKind.success);
  }

  // ── add / save / delete ──

  /// First spot (scanning row by row) where [probe] does not overlap another
  /// table of [zone].
  Offset _freeSpot(PosStore store, TableInfo probe, String zone) {
    final canvas = _canvas;
    final gap = FloorGeometry.unit(canvas) * 0.3;
    final others = store.tables.where((t) => t.zone == zone).map((t) => FloorGeometry.rectOf(t, canvas).inflate(gap)).toList();
    const cols = 9;
    const rows = 7;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final x = 0.03 + c * (0.94 / (cols - 1));
        final y = 0.04 + r * (0.92 / (rows - 1));
        final rect = FloorGeometry.rectOf(probe, canvas, x: x, y: y);
        if (!others.any((o) => o.overlaps(rect))) return Offset(x, y);
      }
    }
    return const Offset(0.5, 0.5);
  }

  Future<void> _addPreset(_Preset p, String zone) async {
    final ok = await _confirmDiscard();
    if (!ok || !mounted) return;
    final store = AppScope.read(context);
    final n = store.nextTableNumber;
    final probe = TableInfo(number: n, seats: p.seats, shape: p.shape, zone: zone);
    final spot = _freeSpot(store, probe, zone);
    try {
      final t = store.addTable(number: n, seats: p.seats, shape: p.shape, zone: zone, x: spot.dx, y: spot.dy);
      setState(() {
        _zone = zone;
        _selected = t.number;
        _loadDraft(t);
      });
      nvToast(context, 'เพิ่มโต๊ะ ${t.number} (${p.label}) ในโซน $zone แล้ว', kind: NvToastKind.success);
    } on StateError catch (e) {
      nvToast(context, e.message, kind: NvToastKind.error);
    }
  }

  void _save(TableInfo t) {
    final store = AppScope.read(context);
    final n = int.tryParse(_number.text.trim());
    if (n == null || n <= 0) {
      nvToast(context, 'หมายเลขโต๊ะต้องเป็นตัวเลขมากกว่า 0', kind: NvToastKind.error);
      return;
    }
    final zone = _creatingZone ? _newZone.text.trim() : _draftZone;
    if (zone.isEmpty) {
      nvToast(context, 'กรุณาตั้งชื่อโซนใหม่', kind: NvToastKind.error);
      return;
    }
    final old = t.number;
    // Tickets keep their table number, so renumbering would orphan them.
    if (n != old && store.openTicketsForTable(old).isNotEmpty) {
      nvToast(context, 'โต๊ะ $old ยังมีออเดอร์ค้าง — เปลี่ยนหมายเลขได้หลังเช็คบิล', kind: NvToastKind.error);
      return;
    }
    try {
      store.updateTable(t, number: n, seats: _seats, shape: _shape, zone: zone);
    } on StateError catch (e) {
      nvToast(context, e.message, kind: NvToastKind.error);
      return;
    }
    if (n != old && store.tableNumber == old) store.setTable(n);
    setState(() {
      _selected = t.number;
      _zone = t.zone;
      _loadDraft(t);
    });
    nvToast(context, 'บันทึกโต๊ะ ${t.number} แล้ว', kind: NvToastKind.success);
  }

  Future<void> _delete(TableInfo t) async {
    final store = AppScope.read(context);
    final ok = await showNvConfirm(
      context,
      title: 'ลบโต๊ะ ${t.number}?',
      message: t.status == TableStatus.free
          ? 'โต๊ะจะถูกลบออกจากผังร้าน (บิลย้อนหลังยังอยู่ครบ)'
          : 'โต๊ะนี้ยังมีสถานะ "${t.status.label}" — ลบออกจากผังร้านใช่หรือไม่?',
      confirmLabel: 'ลบโต๊ะ',
    );
    if (!ok || !mounted) return;
    final n = t.number;
    try {
      store.removeTable(t);
    } on StateError catch (e) {
      nvToast(context, e.message, kind: NvToastKind.error);
      return;
    }
    // an idle counter cart must not keep pointing at a table that is gone
    if (store.tableNumber == n && store.cart.isEmpty) store.setTable(null);
    setState(() => _selected = null);
    nvToast(context, 'ลบโต๊ะ $n แล้ว', kind: NvToastKind.success);
  }

  // ── drag ──

  Size _sizeOf(TableInfo t) => FloorGeometry.tableSize(t, FloorGeometry.unit(_canvas));

  Offset _placed(Offset raw, Size table) {
    var tl = FloorGeometry.clampTopLeft(raw, table, _canvas);
    if (_snap) {
      final step = FloorGeometry.unit(_canvas) / 2;
      if (step > 0) {
        tl = Offset((tl.dx / step).roundToDouble() * step, (tl.dy / step).roundToDouble() * step);
        tl = FloorGeometry.clampTopLeft(tl, table, _canvas);
      }
    }
    return tl;
  }

  void _dragStart(TableInfo t, Rect rect) {
    final store = AppScope.read(context);
    setState(() {
      _dragging = t.number;
      _dragTopLeft = rect.topLeft;
      // follow the dragged table unless there are unsaved edits on another one
      if (_selected != t.number && !_isDirty(_selectedTable(store))) {
        _selected = t.number;
        _loadDraft(t);
      }
    });
  }

  void _dragUpdate(TableInfo t, DragUpdateDetails d) {
    setState(() => _dragTopLeft = FloorGeometry.clampTopLeft(_dragTopLeft + d.delta, _sizeOf(t), _canvas));
  }

  void _dragEnd(TableInfo t) {
    if (_dragging != t.number) return;
    final size = _sizeOf(t);
    final norm = FloorGeometry.normalize(_placed(_dragTopLeft, size), size, _canvas);
    AppScope.read(context).updateTable(t, x: norm.dx, y: norm.dy);
    setState(() => _dragging = null);
  }

  // ── build ──

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final zones = _zonesOf(store);
    final zone = (_zone != null && zones.contains(_zone)) ? _zone! : zones.first;
    final inZone = store.tables.where((t) => t.zone == zone).toList();
    final sel = _selectedTable(store);

    return NvScaffold(
      title: 'ออกแบบผังร้าน',
      art: 'table',
      subtitle: 'ลากเพื่อย้ายโต๊ะ · แตะเพื่อแก้ไข · ทั้งร้าน ${store.tables.length} โต๊ะ',
      actions: [
        NvButton.soft('ดูผังโต๊ะ', icon: NvIcons.chair, size: NvButtonSize.sm, onPressed: () => context.go('/tablet/floor')),
      ],
      body: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 900;
        final canvasArea = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _zoneBar(store, zones, zone),
            const SizedBox(height: 10),
            Expanded(child: _canvasView(inZone, sel)),
          ],
        );
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: canvasArea),
              const SizedBox(width: 16),
              SizedBox(
                width: c.maxWidth >= 1300 ? 340 : 300,
                child: ListView(
                  children: [
                    _palette(zone, horizontal: false),
                    const SizedBox(height: 14),
                    if (sel != null) _properties(store, sel, zones) else _hint(inZone.length),
                  ],
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: canvasArea),
            const SizedBox(height: 10),
            if (sel != null)
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: c.maxHeight * 0.46),
                child: SingleChildScrollView(child: _properties(store, sel, zones)),
              )
            else
              _palette(zone, horizontal: true),
          ],
        );
      }),
    );
  }

  Widget _zoneBar(PosStore store, List<String> zones, String zone) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final z in zones)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: NvChip(
                      z,
                      selected: z == zone,
                      icon: NvIcons.mapPin,
                      count: store.tables.where((t) => t.zone == z).length,
                      onTap: () => _switchZone(z),
                    ),
                  ),
                NvChip('เพิ่มโซน', icon: NvIcons.plus, onTap: _addZone),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        NvIconButton(NvIcons.pen, size: 38, tooltip: 'เปลี่ยนชื่อโซน "$zone"', onPressed: () => _renameZone(zone)),
        const SizedBox(width: 8),
        NvChip('จัดตามตาราง', icon: NvIcons.grid, selected: _snap, onTap: () => setState(() => _snap = !_snap)),
      ],
    );
  }

  Widget _canvasView(List<TableInfo> tables, TableInfo? sel) {
    return LayoutBuilder(builder: (context, c) {
      final size = FloorGeometry.fit(c.biggest);
      _canvas = size; // cache only — drag / free-spot maths read it, no rebuild needed
      final u = FloorGeometry.unit(size);
      return Center(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _select(null),
                  child: FloorSurface(step: u / 2),
                ),
              ),
              if (tables.isEmpty)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            NvArt.mascot('present', height: math.max(80.0, math.min(150.0, size.height * 0.4))),
                            const SizedBox(height: 8),
                            Text('โซนนี้ยังไม่มีโต๊ะ', style: Nv.display(18)),
                            const SizedBox(height: 4),
                            Text('แตะแบบโต๊ะในแผง "เพิ่มโต๊ะ" เพื่อวางโต๊ะแรก', style: Nv.ui(13, color: Nv.ink3)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              for (final t in tables) _positioned(t, size, sel),
            ],
          ),
        ),
      );
    });
  }

  Widget _positioned(TableInfo t, Size canvas, TableInfo? sel) {
    final sz = FloorGeometry.tableSize(t, FloorGeometry.unit(canvas));
    final dragging = _dragging == t.number;
    final rect = dragging ? (_placed(_dragTopLeft, sz) & sz) : FloorGeometry.rectOf(t, canvas);
    return Positioned.fromRect(
      rect: rect,
      child: GestureDetector(
        onTap: () => _select(t.number),
        onPanStart: (_) => _dragStart(t, rect),
        onPanUpdate: (d) => _dragUpdate(t, d),
        onPanEnd: (_) => _dragEnd(t),
        onPanCancel: () => setState(() => _dragging = null),
        child: MouseRegion(
          cursor: dragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
          child: _DesignTile(table: t, selected: sel?.number == t.number, dragging: dragging),
        ),
      ),
    );
  }

  Widget _palette(String zone, {required bool horizontal}) {
    final tiles = [for (final p in _presets) _PresetTile(preset: p, onTap: () => _addPreset(p, zone))];
    return NvSheet(
      padding: EdgeInsets.all(horizontal ? 12 : 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NvSectionTitle('เพิ่มโต๊ะ', trailing: 'วางในโซน $zone', icon: NvIcons.plusCircle),
          if (horizontal)
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tiles.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) => SizedBox(width: 118, child: tiles[i]),
              ),
            )
          else
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.25,
              children: tiles,
            ),
        ],
      ),
    );
  }

  Widget _hint(int tablesInZone) {
    return NvSheet(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NvSectionTitle('วิธีใช้', icon: NvIcons.handPointer),
          for (final line in const [
            'แตะแบบโต๊ะด้านบนเพื่อเพิ่มโต๊ะในโซนนี้',
            'ลากโต๊ะเพื่อย้ายตำแหน่ง — บันทึกอัตโนมัติเมื่อปล่อย',
            'แตะโต๊ะเพื่อแก้ไขหมายเลข ที่นั่ง รูปทรง และโซน',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(padding: EdgeInsets.only(top: 3), child: Icon(NvIcons.check, size: 12, color: Nv.goldInk)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(line, style: Nv.ui(13, color: Nv.ink2, height: 1.4))),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Text('โซนนี้มี $tablesInZone โต๊ะ', style: Nv.ui(12.5, color: Nv.ink3)),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(text, style: Nv.ui(12.5, color: Nv.ink2, weight: FontWeight.w600)),
      );

  Widget _properties(PosStore store, TableInfo t, List<String> zones) {
    final dirty = _isDirty(t);
    final hasTickets = store.openTicketsForTable(t.number).isNotEmpty;
    final zoneItems = [...zones, if (!zones.contains(_draftZone)) _draftZone];
    return NvSheet(
      padding: const EdgeInsets.all(16),
      goldEdge: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NvSectionTitle(
            'โต๊ะ ${t.number}',
            icon: NvIcons.sliders,
            action: dirty ? const NvBadge('ยังไม่บันทึก', tint: NvTint.amber) : null,
          ),
          if (t.status != TableStatus.free)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'สถานะ "${t.status.label}"${hasTickets ? ' · มีออเดอร์ค้าง เปลี่ยนหมายเลขหรือลบไม่ได้' : ''}',
                style: Nv.ui(12.5, color: const Color(0xFF8A5A00), weight: FontWeight.w600),
              ),
            ),
          NvField(
            label: 'หมายเลขโต๊ะ',
            controller: _number,
            icon: NvIcons.tag,
            keyboard: TextInputType.number,
            formatters: NvField.digits,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _label('จำนวนที่นั่ง'),
          Row(
            children: [
              NvStepper(
                value: _seats,
                onMinus: _seats > 1 ? () => setState(() => _seats--) : null,
                onPlus: _seats < 40 ? () => setState(() => _seats++) : null,
              ),
              const SizedBox(width: 10),
              Text('ที่นั่ง', style: Nv.ui(13, color: Nv.ink3)),
            ],
          ),
          const SizedBox(height: 12),
          _label('รูปทรง · ${floorShapeLabel(_shape)}'),
          Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: NvSegmented<TableShape>(
                options: const [(TableShape.round, 'กลม'), (TableShape.square, 'สี่เหลี่ยม'), (TableShape.rect, 'ยาว')],
                value: _shape,
                onChanged: (v) => setState(() => _shape = v),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _label('โซน'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Nv.paper,
              borderRadius: BorderRadius.circular(Nv.rSm),
              border: Border.all(color: Nv.line),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _creatingZone ? _kNewZone : _draftZone,
                isExpanded: true,
                icon: const Icon(NvIcons.chevronDown, size: 12, color: Nv.ink3),
                style: Nv.ui(14.5),
                dropdownColor: Nv.ivory2,
                borderRadius: BorderRadius.circular(Nv.rMd),
                items: [
                  for (final z in zoneItems) DropdownMenuItem<String>(value: z, child: Text(z)),
                  DropdownMenuItem<String>(
                    value: _kNewZone,
                    child: Row(
                      children: [
                        const Icon(NvIcons.plus, size: 12, color: Nv.goldInk),
                        const SizedBox(width: 8),
                        Text('โซนใหม่…', style: Nv.ui(14.5, color: Nv.goldInk, weight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    if (v == _kNewZone) {
                      _creatingZone = true;
                    } else {
                      _creatingZone = false;
                      _draftZone = v;
                    }
                  });
                },
              ),
            ),
          ),
          if (_creatingZone) ...[
            const SizedBox(height: 10),
            NvField(
              label: 'ชื่อโซนใหม่',
              controller: _newZone,
              hint: 'เช่น ระเบียง',
              icon: NvIcons.mapPin,
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              NvButton.danger('ลบ', icon: NvIcons.trash, onPressed: () => _delete(t)),
              const SizedBox(width: 10),
              Expanded(
                child: NvButton.gold('บันทึก', icon: NvIcons.floppy, expand: true, onPressed: dirty ? () => _save(t) : null),
              ),
            ],
          ),
          if (dirty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _loadDraft(t)),
                child: Text('ยกเลิกการแก้ไข', style: Nv.ui(13, color: Nv.ink3, weight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }
}

class _DesignTile extends StatelessWidget {
  final TableInfo table;
  final bool selected;
  final bool dragging;
  const _DesignTile({required this.table, required this.selected, required this.dragging});

  @override
  Widget build(BuildContext context) {
    final t = table;
    return LayoutBuilder(builder: (context, c) {
      final short = math.min(c.maxWidth, c.maxHeight);
      final round = t.shape == TableShape.round;
      return AnimatedScale(
        scale: dragging ? 1.08 : 1,
        duration: Nv.fast,
        curve: Nv.ease,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: Nv.fast,
              width: c.maxWidth,
              height: c.maxHeight,
              padding: EdgeInsets.all(short * (round ? 0.16 : 0.08)),
              decoration: BoxDecoration(
                color: selected ? Nv.gold100 : Nv.ivory2,
                borderRadius: BorderRadius.circular(round ? short / 2 : short * 0.18),
                border: Border.all(
                  color: selected ? Nv.navy800 : Nv.gold500.withValues(alpha: 0.8),
                  width: selected ? 2.6 : 1.4,
                ),
                boxShadow: dragging ? Nv.shadowLift : (selected ? [...Nv.shadowSheet, ...Nv.goldGlow(0.6)] : Nv.shadowSheet),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${t.number}', style: Nv.display(20, weight: FontWeight.w700)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(NvIcons.users, size: 10, color: Nv.ink3),
                        const SizedBox(width: 4),
                        Text('${t.seats} ที่', style: Nv.money(11.5, color: Nv.ink3, weight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (t.status != TableStatus.free)
              Positioned(
                top: -4,
                left: -4,
                child: Tooltip(
                  message: 'สถานะ: ${t.status.label}',
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _busyColor(t.status),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _PresetTile extends StatelessWidget {
  final _Preset preset;
  final VoidCallback onTap;
  const _PresetTile({required this.preset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (w, h, round) = switch (preset.shape) {
      TableShape.round => (34.0, 34.0, true),
      TableShape.square => (32.0, 32.0, false),
      TableShape.rect => (52.0, 28.0, false),
    };
    return NvSheet(
      padding: const EdgeInsets.all(10),
      radius: Nv.rMd,
      color: Nv.paper,
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                width: w,
                height: h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Nv.gold100,
                  borderRadius: BorderRadius.circular(round ? h / 2 : 6),
                  border: Border.all(color: Nv.gold500, width: 1.4),
                ),
                child: Text('${preset.seats}', style: Nv.money(12, color: Nv.goldInk)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(NvIcons.plus, size: 10, color: Nv.goldInk),
              const SizedBox(width: 5),
              Flexible(
                child: Text(preset.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(12.5, weight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
