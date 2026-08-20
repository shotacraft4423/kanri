class ProductCost {
  final String productId;
  final int avgUnitCost; // 移動平均原価（円、整数丸め）
  final double totalReceivedQuantity;
  final int totalReceivedCost;
  final DateTime updatedAt;

  const ProductCost({
    required this.productId,
    required this.avgUnitCost,
    required this.totalReceivedQuantity,
    required this.totalReceivedCost,
    required this.updatedAt,
  });

  Map<String, Object?> toMap() => {
        'product_id': productId,
        'avg_unit_cost': avgUnitCost,
        'total_received_quantity': totalReceivedQuantity,
        'total_received_cost': totalReceivedCost,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory ProductCost.fromMap(Map<String, Object?> m) => ProductCost(
        productId: m['product_id'] as String,
        avgUnitCost: m['avg_unit_cost'] as int,
        totalReceivedQuantity: (m['total_received_quantity'] as num).toDouble(),
        totalReceivedCost: m['total_received_cost'] as int,
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );
}
