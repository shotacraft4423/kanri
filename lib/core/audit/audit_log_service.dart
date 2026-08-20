import 'dart:convert';

import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../models/audit_log.dart';

/// 主要な変更操作を記録する。顧客氏名・住所・電話番号等の機密値そのものは
/// before/after JSON に含めず、変更の存在とエンティティIDのみを残す方針とし、
/// ログからの機密情報漏洩を防ぐ（要件13-14）。
class AuditLogService {
  const AuditLogService._();
  static const instance = AuditLogService._();

  static const _uuid = Uuid();

  Future<void> log(
    Transaction txn, {
    required String entityType,
    required String entityId,
    required String action,
    Map<String, Object?>? before,
    Map<String, Object?>? after,
  }) async {
    final entry = AuditLog(
      id: _uuid.v4(),
      entityType: entityType,
      entityId: entityId,
      action: action,
      beforeJson: before != null ? jsonEncode(_redact(entityType, before)) : null,
      afterJson: after != null ? jsonEncode(_redact(entityType, after)) : null,
      createdAt: DateTime.now(),
    );
    await txn.insert('audit_logs', entry.toMap());
  }

  static const _sensitiveFields = {'name', 'address', 'postal_code', 'phone'};

  Map<String, Object?> _redact(String entityType, Map<String, Object?> data) {
    if (entityType != 'customer') return data;
    final copy = Map<String, Object?>.from(data);
    for (final key in _sensitiveFields) {
      if (copy.containsKey(key) && copy[key] != null) {
        copy[key] = '(変更あり)';
      }
    }
    return copy;
  }
}
