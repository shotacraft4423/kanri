class Inventory {
  final String productId;
  final double quantity;
  final double reservedQuantity;
  final DateTime updatedAt;

  const Inventory({
    required this.productId,
    required this.quantity,
    this.reservedQuantity = 0,
    required this.updatedAt,
  });

  double get availableQuantity => quantity - reservedQuantity;

  Map<String, Object?> toMap() => {
        'product_id': productId,
        'quantity': quantity,
        'reserved_quantity': reservedQuantity,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Inventory.fromMap(Map<String, Object?> m) => Inventory(
        productId: m['product_id'] as String,
        quantity: (m['quantity'] as num).toDouble(),
        reservedQuantity: (m['reserved_quantity'] as num).toDouble(),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );
}
