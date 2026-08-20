class PriceHistory {
  final String id;
  final String productId;
  final int priceX1;
  final int priceX3;
  final int priceX5;
  final DateTime changedAt;

  const PriceHistory({
    required this.id,
    required this.productId,
    required this.priceX1,
    required this.priceX3,
    required this.priceX5,
    required this.changedAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'product_id': productId,
        'price_x1': priceX1,
        'price_x3': priceX3,
        'price_x5': priceX5,
        'changed_at': changedAt.toIso8601String(),
      };

  factory PriceHistory.fromMap(Map<String, Object?> m) => PriceHistory(
        id: m['id'] as String,
        productId: m['product_id'] as String,
        priceX1: m['price_x1'] as int,
        priceX3: m['price_x3'] as int,
        priceX5: m['price_x5'] as int,
        changedAt: DateTime.parse(m['changed_at'] as String),
      );
}
