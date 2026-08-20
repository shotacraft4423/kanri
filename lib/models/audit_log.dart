class AuditLog {
  final String id;
  final String entityType;
  final String entityId;
  final String action;
  final String? beforeJson;
  final String? afterJson;
  final DateTime createdAt;

  const AuditLog({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    this.beforeJson,
    this.afterJson,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'entity_type': entityType,
        'entity_id': entityId,
        'action': action,
        'before_json': beforeJson,
        'after_json': afterJson,
        'created_at': createdAt.toIso8601String(),
      };

  factory AuditLog.fromMap(Map<String, Object?> m) => AuditLog(
        id: m['id'] as String,
        entityType: m['entity_type'] as String,
        entityId: m['entity_id'] as String,
        action: m['action'] as String,
        beforeJson: m['before_json'] as String?,
        afterJson: m['after_json'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}
