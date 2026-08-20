class Product {
  final String id;
  final String name;
  final String? shortName;
  final String purchaseUnit; // 仕入れ単位（例: 個, 枚, g）
  final double purchaseQty; // 標準仕入れ数量（原価計算の目安表示用）
  final int purchasePrice; // 標準仕入れ価格（目安表示用。実額は仕入れ記録に保持）
  final double minSaleUnit; // 最小販売単位（0.5個, 0.1g 等）
  final String unitLabel; // 表示単位（個/枚/g）
  final int priceX1;
  final int priceX3;
  final int priceX5;
  final String? shippingNote;
  final bool isActive; // true=販売中, false=販売停止
  final double lowStockThreshold;
  final String? memo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.name,
    this.shortName,
    required this.purchaseUnit,
    required this.purchaseQty,
    required this.purchasePrice,
    required this.minSaleUnit,
    required this.unitLabel,
    required this.priceX1,
    required this.priceX3,
    required this.priceX5,
    this.shippingNote,
    this.isActive = true,
    this.lowStockThreshold = 0,
    this.memo,
    required this.createdAt,
    required this.updatedAt,
  });

  Product copyWith({
    String? name,
    String? shortName,
    String? purchaseUnit,
    double? purchaseQty,
    int? purchasePrice,
    double? minSaleUnit,
    String? unitLabel,
    int? priceX1,
    int? priceX3,
    int? priceX5,
    String? shippingNote,
    bool? isActive,
    double? lowStockThreshold,
    String? memo,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      purchaseUnit: purchaseUnit ?? this.purchaseUnit,
      purchaseQty: purchaseQty ?? this.purchaseQty,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      minSaleUnit: minSaleUnit ?? this.minSaleUnit,
      unitLabel: unitLabel ?? this.unitLabel,
      priceX1: priceX1 ?? this.priceX1,
      priceX3: priceX3 ?? this.priceX3,
      priceX5: priceX5 ?? this.priceX5,
      shippingNote: shippingNote ?? this.shippingNote,
      isActive: isActive ?? this.isActive,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      memo: memo ?? this.memo,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'short_name': shortName,
        'purchase_unit': purchaseUnit,
        'purchase_qty': purchaseQty,
        'purchase_price': purchasePrice,
        'min_sale_unit': minSaleUnit,
        'unit_label': unitLabel,
        'price_x1': priceX1,
        'price_x3': priceX3,
        'price_x5': priceX5,
        'shipping_note': shippingNote,
        'is_active': isActive ? 1 : 0,
        'low_stock_threshold': lowStockThreshold,
        'memo': memo,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Product.fromMap(Map<String, Object?> m) => Product(
        id: m['id'] as String,
        name: m['name'] as String,
        shortName: m['short_name'] as String?,
        purchaseUnit: m['purchase_unit'] as String,
        purchaseQty: (m['purchase_qty'] as num).toDouble(),
        purchasePrice: m['purchase_price'] as int,
        minSaleUnit: (m['min_sale_unit'] as num).toDouble(),
        unitLabel: m['unit_label'] as String,
        priceX1: m['price_x1'] as int,
        priceX3: m['price_x3'] as int,
        priceX5: m['price_x5'] as int,
        shippingNote: m['shipping_note'] as String?,
        isActive: (m['is_active'] as int) == 1,
        lowStockThreshold: (m['low_stock_threshold'] as num).toDouble(),
        memo: m['memo'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );
}
