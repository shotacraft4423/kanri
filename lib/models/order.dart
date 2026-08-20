class Order {
  final String id;
  final String orderNumber;
  final DateTime orderDate;
  final String customerId;
  final String? memo;
  final bool isCancelled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.orderDate,
    required this.customerId,
    this.memo,
    this.isCancelled = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Order copyWith({bool? isCancelled, String? memo, DateTime? updatedAt}) {
    return Order(
      id: id,
      orderNumber: orderNumber,
      orderDate: orderDate,
      customerId: customerId,
      memo: memo ?? this.memo,
      isCancelled: isCancelled ?? this.isCancelled,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'order_number': orderNumber,
        'order_date': orderDate.toIso8601String(),
        'customer_id': customerId,
        'memo': memo,
        'is_cancelled': isCancelled ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Order.fromMap(Map<String, Object?> m) => Order(
        id: m['id'] as String,
        orderNumber: m['order_number'] as String,
        orderDate: DateTime.parse(m['order_date'] as String),
        customerId: m['customer_id'] as String,
        memo: m['memo'] as String?,
        isCancelled: (m['is_cancelled'] as int) == 1,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );
}
