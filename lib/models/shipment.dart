import 'enums.dart';

class Shipment {
  final String id;
  final String orderId;
  final ShipmentStatus status;
  final String carrier;
  final String? trackingNumber;
  final DateTime? shippedAt;
  final DateTime? arrivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Shipment({
    required this.id,
    required this.orderId,
    required this.status,
    this.carrier = 'レターパックライト',
    this.trackingNumber,
    this.shippedAt,
    this.arrivedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Shipment copyWith({
    ShipmentStatus? status,
    String? carrier,
    String? trackingNumber,
    DateTime? shippedAt,
    DateTime? arrivedAt,
    DateTime? updatedAt,
  }) {
    return Shipment(
      id: id,
      orderId: orderId,
      status: status ?? this.status,
      carrier: carrier ?? this.carrier,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      shippedAt: shippedAt ?? this.shippedAt,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'order_id': orderId,
        'status': status.name,
        'carrier': carrier,
        'tracking_number': trackingNumber,
        'shipped_at': shippedAt?.toIso8601String(),
        'arrived_at': arrivedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Shipment.fromMap(Map<String, Object?> m) => Shipment(
        id: m['id'] as String,
        orderId: m['order_id'] as String,
        status: ShipmentStatus.fromName(m['status'] as String),
        carrier: m['carrier'] as String,
        trackingNumber: m['tracking_number'] as String?,
        shippedAt: m['shipped_at'] != null
            ? DateTime.parse(m['shipped_at'] as String)
            : null,
        arrivedAt: m['arrived_at'] != null
            ? DateTime.parse(m['arrived_at'] as String)
            : null,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );
}
