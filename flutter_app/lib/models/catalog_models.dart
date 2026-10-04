// Thaiprompt POS — Catalog domain models (menu / products / categories).
//
// A single shared source of truth fed by the live terminal API
// (/api/pos/sync/products|categories) and by the in-app menu editor. Products
// and categories persist in the store snapshot, so a menu built offline
// survives restarts.
//
// by xman studio

import 'package:flutter/widgets.dart';

import '../theme/nv_icons.dart';

/// Category icon keys → Nova (Font Awesome) glyphs. Persisted by key so the
/// snapshot never stores raw code points.
const Map<String, IconData> kCategoryIcons = {
  'tag': NvIcons.tag,
  'coffee': NvIcons.mugHot,
  'drink': NvIcons.glassWater,
  'cocktail': NvIcons.martini,
  'rice': NvIcons.bowlRice,
  'food': NvIcons.bowlFood,
  'noodle': NvIcons.utensils,
  'burger': NvIcons.burger,
  'spicy': NvIcons.pepperHot,
  'dessert': NvIcons.iceCream,
  'cake': NvIcons.cake,
  'bakery': NvIcons.bread,
  'snack': NvIcons.cookie,
  'fruit': NvIcons.appleWhole,
  'veg': NvIcons.carrot,
  'leaf': NvIcons.leaf,
  'grocery': NvIcons.basket,
  'box': NvIcons.box,
  'gift': NvIcons.gift,
  'star': NvIcons.star,
};

/// Food art keys (`assets/nova/food/<key>.webp`) offered as product pictures.
const List<String> kFoodArt = [
  'thai_tea', 'coffee', 'rice', 'noodle', 'dessert', 'snack', 'bakery', 'juice', 'grocery',
];

/// A product category. Mutable so the menu editor can rename / re-icon it.
class Category {
  final String id;
  String name;
  String iconKey;
  int hue;
  int sortOrder;

  Category({
    required this.id,
    required this.name,
    this.iconKey = 'tag',
    required this.hue,
    this.sortOrder = 0,
  });

  IconData get icon => kCategoryIcons[iconKey] ?? NvIcons.tag;

  /// Server category shape `{id, name, icon, color, sort_order}`.
  factory Category.fromApi(Map<String, dynamic> j) {
    final name = (j['name'] as String?) ?? '';
    return Category(
      id: (j['id'] ?? name).toString(),
      name: name,
      iconKey: _guessIconKey(name),
      hue: stableHue(name),
      sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconKey': iconKey,
        'hue': hue,
        'sortOrder': sortOrder,
      };

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as String,
        name: j['name'] as String,
        iconKey: (j['iconKey'] as String?) ?? 'tag',
        hue: (j['hue'] as num?)?.toInt() ?? 40,
        sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
      );

  static String _guessIconKey(String name) {
    final n = name.toLowerCase();
    if (n.contains('กาแฟ') || n.contains('coffee')) return 'coffee';
    if (n.contains('ชา') || n.contains('น้ำ') || n.contains('drink') || n.contains('เครื่องดื่ม')) return 'drink';
    if (n.contains('ข้าว') || n.contains('rice')) return 'rice';
    if (n.contains('เส้น') || n.contains('ก๋วยเตี๋ยว') || n.contains('noodle')) return 'noodle';
    if (n.contains('หวาน') || n.contains('dessert')) return 'dessert';
    if (n.contains('เค้ก') || n.contains('เบเกอรี่') || n.contains('ขนมปัง')) return 'bakery';
    if (n.contains('ทานเล่น') || n.contains('snack')) return 'snack';
    if (n.contains('ผลไม้') || n.contains('fruit')) return 'fruit';
    return 'tag';
  }
}

/// Deterministic 0-359 hue from a string (FNV-1a) — `String.hashCode` is not
/// stable across platforms / SDK versions, so never use it for persisted UI.
int stableHue(String s) => fnv1a(s) % 360;

/// 32-bit FNV-1a over UTF-16 code units — stable everywhere.
int fnv1a(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}

/// One selectable choice inside an option group (e.g. "ใหญ่ +15").
class OptionChoice {
  final String label;
  final int priceDelta;
  const OptionChoice(this.label, [this.priceDelta = 0]);

  Map<String, dynamic> toJson() => {'label': label, 'priceDelta': priceDelta};
  factory OptionChoice.fromJson(Map<String, dynamic> j) =>
      OptionChoice(j['label'] as String, (j['priceDelta'] as num?)?.toInt() ?? 0);
}

/// A modifier group on a product: ขนาด / ความหวาน / ท็อปปิ้ง.
class OptionGroup {
  final String name;
  final bool required; // must pick exactly one when [multi] is false
  final bool multi; // allow several choices (toppings)
  final List<OptionChoice> choices;

  const OptionGroup({required this.name, this.required = false, this.multi = false, this.choices = const []});

  Map<String, dynamic> toJson() => {
        'name': name,
        'required': required,
        'multi': multi,
        'choices': choices.map((c) => c.toJson()).toList(),
      };

  factory OptionGroup.fromJson(Map<String, dynamic> j) => OptionGroup(
        name: j['name'] as String,
        required: (j['required'] as bool?) ?? false,
        multi: (j['multi'] as bool?) ?? false,
        choices: ((j['choices'] as List?) ?? const [])
            .map((e) => OptionChoice.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

/// A sellable product. Immutable except [stock]; edits go through
/// `PosStore.upsertProduct`, which swaps in a new instance (history keeps its
/// own [OrderLine] snapshot so price edits never rewrite past bills).
class Product {
  final String id; // stable key — equals [code]
  final String name;
  final String code; // SKU shown on the card / receipt
  final int price; // baht
  final String categoryId;
  final int hue; // fallback gradient hue when there is no art
  final String kind; // 'rect' | 'circle' — placeholder shape
  final String? tag; // 'ขายดี' | 'ใหม่' | 'พรีเมียม' | null
  final String barcode; // EAN-13 / Code128 payload ('' = use code)
  final int cost; // baht · for margin / COGS
  final String? art; // kFoodArt key → assets/nova/food/<art>.webp
  final String? imageUrl; // remote picture from the shop catalog
  final String description;
  final bool available; // false = hidden from sale (86'd)
  final bool trackStock;
  final List<OptionGroup> options;
  int stock;

  Product({
    required this.id,
    required this.name,
    required this.code,
    required this.price,
    required this.categoryId,
    required this.hue,
    this.kind = 'rect',
    this.tag,
    this.barcode = '',
    this.cost = 0,
    this.art,
    this.imageUrl,
    this.description = '',
    this.available = true,
    this.trackStock = true,
    this.options = const [],
    this.stock = 999,
  });

  bool get isLowStock => trackStock && stock <= 5;
  bool get isOutOfStock => trackStock && stock <= 0;
  bool get canSell => available && !isOutOfStock;
  String get scanCode => barcode.isNotEmpty ? barcode : code;
  int get margin => price - cost;
  bool get hasOptions => options.isNotEmpty;

  Product copyWith({
    String? name,
    int? price,
    String? categoryId,
    int? hue,
    String? kind,
    Object? tag = _keep,
    String? barcode,
    int? cost,
    Object? art = _keep,
    Object? imageUrl = _keep,
    String? description,
    bool? available,
    bool? trackStock,
    List<OptionGroup>? options,
    int? stock,
  }) =>
      Product(
        id: id,
        code: code,
        name: name ?? this.name,
        price: price ?? this.price,
        categoryId: categoryId ?? this.categoryId,
        hue: hue ?? this.hue,
        kind: kind ?? this.kind,
        tag: identical(tag, _keep) ? this.tag : tag as String?,
        barcode: barcode ?? this.barcode,
        cost: cost ?? this.cost,
        art: identical(art, _keep) ? this.art : art as String?,
        imageUrl: identical(imageUrl, _keep) ? this.imageUrl : imageUrl as String?,
        description: description ?? this.description,
        available: available ?? this.available,
        trackStock: trackStock ?? this.trackStock,
        options: options ?? this.options,
        stock: stock ?? this.stock,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'price': price,
        'categoryId': categoryId,
        'hue': hue,
        'kind': kind,
        'tag': tag,
        'barcode': barcode,
        'cost': cost,
        'art': art,
        'imageUrl': imageUrl,
        'description': description,
        'available': available,
        'trackStock': trackStock,
        'options': options.map((o) => o.toJson()).toList(),
        'stock': stock,
      };

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as String,
        name: j['name'] as String,
        code: j['code'] as String,
        price: (j['price'] as num).toInt(),
        categoryId: (j['categoryId'] as String?) ?? '',
        hue: (j['hue'] as num?)?.toInt() ?? 40,
        kind: (j['kind'] as String?) ?? 'rect',
        tag: j['tag'] as String?,
        barcode: (j['barcode'] as String?) ?? '',
        cost: (j['cost'] as num?)?.toInt() ?? 0,
        art: j['art'] as String?,
        imageUrl: j['imageUrl'] as String?,
        description: (j['description'] as String?) ?? '',
        available: (j['available'] as bool?) ?? true,
        trackStock: (j['trackStock'] as bool?) ?? true,
        options: ((j['options'] as List?) ?? const [])
            .map((e) => OptionGroup.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        stock: (j['stock'] as num?)?.toInt() ?? 999,
      );
}

const Object _keep = Object();
