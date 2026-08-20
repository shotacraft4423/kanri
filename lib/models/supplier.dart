class Supplier {
  final String id;
  final String name;
  final String? contact;
  final String? memo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Supplier({
    required this.id,
    required this.name,
    this.contact,
    this.memo,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'contact': contact,
        'memo': memo,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Supplier.fromMap(Map<String, Object?> m) => Supplier(
        id: m['id'] as String,
        name: m['name'] as String,
        contact: m['contact'] as String?,
        memo: m['memo'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );
}
