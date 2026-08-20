import 'package:sqflite_sqlcipher/sqflite.dart';

import '../core/audit/audit_log_service.dart';
import '../core/db/app_database.dart';
import '../models/enums.dart';
import '../models/shipment.dart';

class ShipmentRepository {
  ShipmentRepository._();
  static final ShipmentRepository instance = ShipmentRepository._();

  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<Shipment>> listByStatus(ShipmentStatus? status) async {
    final db = await _db;
    final rows = status == null
        ? await db.query('shipments', orderBy: 'created_at DESC')
        : await db.query('shipments',
            where: 'status = ?', whereArgs: [status.name], orderBy: 'created_at DESC');
    return rows.map(Shipment.fromMap).toList();
  }

  Future<Shipment?> findByOrderId(String orderId) async {
    final db = await _db;
    final rows = await db.query('shipments', where: 'order_id = ?', whereArgs: [orderId]);
    if (rows.isEmpty) return null;
    return Shipment.fromMap(rows.first);
  }

  /// 発送ステータスを変更する。「発送済み」に変更する際は発送日、
  /// 「配達完了」に変更する際は到着日を必須で記録する（要件33, 14）。
  Future<void> updateStatus({
    required String shipmentId,
    required ShipmentStatus status,
    DateTime? shippedAt,
    DateTime? arrivedAt,
  }) async {
    final db = await _db;
    final rows = await db.query('shipments', where: 'id = ?', whereArgs: [shipmentId]);
    if (rows.isEmpty) return;
    final existing = Shipment.fromMap(rows.first);

    DateTime? resolvedShippedAt = existing.shippedAt;
    DateTime? resolvedArrivedAt = existing.arrivedAt;
    if (status == ShipmentStatus.shipped && resolvedShippedAt == null) {
      resolvedShippedAt = shippedAt ?? DateTime.now();
    }
    if (status == ShipmentStatus.delivered && resolvedArrivedAt == null) {
      resolvedArrivedAt = arrivedAt ?? DateTime.now();
    }

    final updated = existing.copyWith(
      status: status,
      shippedAt: resolvedShippedAt,
      arrivedAt: resolvedArrivedAt,
    );

    await db.transaction((txn) async {
      await txn.update('shipments', updated.toMap(), where: 'id = ?', whereArgs: [shipmentId]);
      await AuditLogService.instance.log(
        txn,
        entityType: 'shipment',
        entityId: shipmentId,
        action: 'status_change',
        before: existing.toMap(),
        after: updated.toMap(),
      );
    });
  }

  Future<void> registerTracking(String shipmentId, String trackingNumber) async {
    final db = await _db;
    final rows = await db.query('shipments', where: 'id = ?', whereArgs: [shipmentId]);
    if (rows.isEmpty) return;
    final existing = Shipment.fromMap(rows.first);
    final updated = existing.copyWith(trackingNumber: trackingNumber);
    await db.update('shipments', updated.toMap(), where: 'id = ?', whereArgs: [shipmentId]);
  }
}
