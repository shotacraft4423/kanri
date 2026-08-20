class PurchaseItem {
  final String id;
  final String purchaseId;
  final String productId;
  final double quantity;
  final int itemCost; // 商品代
  final int shippingCost; // 送料
  final int fee; // 手数料
  final int adjustment; // 調整額
  final int actualPaid; // 実際の支払額
  final double? receivedQuantity; // 入荷済み数量。null=未入荷
  final DateTime createdAt;
  final DateTime updatedAt;

  const PurchaseItem({
    required this.id,
    required this.purchaseId,
    required this.productId,
    required this.quantity,
    required this.itemCost,
    required this.shippingCost,
    required this.fee,
    required this.adjustment,
    required this.actualPaid,
    this.receivedQuantity,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isReceived => receivedQuantity != null;

  PurchaseItem copyWith({
    double? receivedQuantity,
    DateTime? updatedAt,
  }) {
    return PurchaseItem(
      id: id,
      purchaseId: purchaseId,
      productId: productId,
      quantity: quantity,
      itemCost: itemCost,
      shippingCost: shippingCost,
      fee: fee,
      adjustment: adjustment,
      actualPaid: actualPaid,
      receivedQuantity: receivedQuantity ?? this.receivedQuantity,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'purchase_id': purchaseId,
        'product_id': productId,
        'quantity': quantity,
        'item_cost': itemCost,
        'shipping_cost': shippingCost,
        'fee': fee,
        'adjustment': adjustment,
        'actual_paid': actualPaid,
        'received_quantity': receivedQuantity,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory PurchaseItem.fromMap(Map<String, Object?> m) => PurchaseItem(
        id: m['id'] as String,
        purchaseId: m['purchase_id'] as String,
        productId: m['product_id'] as String,
        quantity: (m['quantity'] as num).toDouble(),
        itemCost: m['item_cost'] as int,
        shippingCost: m['shipping_cost'] as int,
        fee: m['fee'] as int,
        adjustment: m['adjustment'] as int,
        actualPaid: m['actual_paid'] as int,
        receivedQuantity: m['received_quantity'] != null
            ? (m['received_quantity'] as num).toDouble()
            : null,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );
}
