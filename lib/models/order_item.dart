import 'enums.dart';

class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final double quantity; // 最小販売単位の倍数
  final int unitPrice; // 販売時点の単価（凍結）
  final PriceTier priceTier;
  final int lineTotal;
  final int unitCost; // 販売時点の原価スナップショット（数量合計に対する原価）
  final int profit;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.priceTier,
    required this.lineTotal,
    required this.unitCost,
    required this.profit,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'order_id': orderId,
        'product_id': productId,
        'quantity': quantity,
        'unit_price': unitPrice,
        'price_tier': priceTier.name,
        'line_total': lineTotal,
        'unit_cost': unitCost,
        'profit': profit,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory OrderItem.fromMap(Map<String, Object?> m) => OrderItem(
        id: m['id'] as String,
        orderId: m['order_id'] as String,
        productId: m['product_id'] as String,
        quantity: (m['quantity'] as num).toDouble(),
        unitPrice: m['unit_price'] as int,
        priceTier: PriceTier.fromName(m['price_tier'] as String),
        lineTotal: m['line_total'] as int,
        unitCost: m['unit_cost'] as int,
        profit: m['profit'] as int,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );
}
