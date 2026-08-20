class Customer {
  final String id;
  final String name;
  final String? postalCode;
  final String? address;
  final String? phone;
  final String? memo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Customer({
    required this.id,
    required this.name,
    this.postalCode,
    this.address,
    this.phone,
    this.memo,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 一覧表示用のマスキング済み氏名（例: "山田太郎" -> "山田**"）
  String get maskedName {
    if (name.length <= 1) return name;
    final visibleLen = (name.length / 2).ceil().clamp(1, name.length - 1);
    return name.substring(0, visibleLen) + '*' * (name.length - visibleLen);
  }

  Customer copyWith({
    String? name,
    String? postalCode,
    String? address,
    String? phone,
    String? memo,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      postalCode: postalCode ?? this.postalCode,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      memo: memo ?? this.memo,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'postal_code': postalCode,
        'address': address,
        'phone': phone,
        'memo': memo,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Customer.fromMap(Map<String, Object?> m) => Customer(
        id: m['id'] as String,
        name: m['name'] as String,
        postalCode: m['postal_code'] as String?,
        address: m['address'] as String?,
        phone: m['phone'] as String?,
        memo: m['memo'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );
}
