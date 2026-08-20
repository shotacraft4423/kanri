import 'enums.dart';

class InventoryAdjustment {
  final String id;
  final String productId;
  final double quantityDelta;
  final InventoryAdjustmentReason reason;
  final String? memo;
  final DateTime createdAt;

  const InventoryAdjustment({
    required this.id,
    required this.productId,
    required this.quantityDelta,
    required this.reason,
    this.memo,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'product_id': productId,
        'quantity_delta': quantityDelta,
        'reason': reason.name,
        'memo': memo,
        'created_at': createdAt.toIso8601String(),
      };

  factory InventoryAdjustment.fromMap(Map<String, Object?> m) =>
      InventoryAdjustment(
        id: m['id'] as String,
        productId: m['product_id'] as String,
        quantityDelta: (m['quantity_delta'] as num).toDouble(),
        reason: InventoryAdjustmentReason.fromName(m['reason'] as String),
        memo: m['memo'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}
