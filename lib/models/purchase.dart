import 'enums.dart';

class Purchase {
  final String id;
  final String supplierId;
  final DateTime purchaseDate;
  final PurchaseStatus status;
  final String? trackingNumber;
  final DateTime? arrivalDate;
  final String? memo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Purchase({
    required this.id,
    required this.supplierId,
    required this.purchaseDate,
    required this.status,
    this.trackingNumber,
    this.arrivalDate,
    this.memo,
    required this.createdAt,
    required this.updatedAt,
  });

  Purchase copyWith({
    PurchaseStatus? status,
    String? trackingNumber,
    DateTime? arrivalDate,
    String? memo,
    DateTime? updatedAt,
  }) {
    return Purchase(
      id: id,
      supplierId: supplierId,
      purchaseDate: purchaseDate,
      status: status ?? this.status,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      arrivalDate: arrivalDate ?? this.arrivalDate,
      memo: memo ?? this.memo,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'supplier_id': supplierId,
        'purchase_date': purchaseDate.toIso8601String(),
        'status': status.name,
        'tracking_number': trackingNumber,
        'arrival_date': arrivalDate?.toIso8601String(),
        'memo': memo,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Purchase.fromMap(Map<String, Object?> m) => Purchase(
        id: m['id'] as String,
        supplierId: m['supplier_id'] as String,
        purchaseDate: DateTime.parse(m['purchase_date'] as String),
        status: PurchaseStatus.fromName(m['status'] as String),
        trackingNumber: m['tracking_number'] as String?,
        arrivalDate: m['arrival_date'] != null
            ? DateTime.parse(m['arrival_date'] as String)
            : null,
        memo: m['memo'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );
}
