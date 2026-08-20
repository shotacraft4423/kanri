import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../core/audit/audit_log_service.dart';
import '../core/db/app_database.dart';
import '../models/enums.dart';
import '../models/inventory.dart';
import '../models/inventory_adjustment.dart';

class InventoryRepository {
  InventoryRepository._();
  static final InventoryRepository instance = InventoryRepository._();

  static const _uuid = Uuid();

  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<Inventory>> listAll() async {
    final db = await _db;
    final rows = await db.query('inventory');
    return rows.map(Inventory.fromMap).toList();
  }

  Future<Inventory?> findByProduct(String productId) async {
    final db = await _db;
    final rows = await db.query('inventory', where: 'product_id = ?', whereArgs: [productId]);
    if (rows.isEmpty) return null;
    return Inventory.fromMap(rows.first);
  }

  /// 在庫を差分適用する。増加・減少どちらも同一の経路を通す
  /// （入荷処理・販売登録・手動調整はすべてこの関数を経由し、二重加算/二重減算を防ぐ）。
  Future<void> applyDelta(Transaction txn, String productId, double delta) async {
    final rows = await txn.query('inventory', where: 'product_id = ?', whereArgs: [productId]);
    final now = DateTime.now();
    if (rows.isEmpty) {
      await txn.insert('inventory', {
        'product_id': productId,
        'quantity': delta,
        'reserved_quantity': 0.0,
        'updated_at': now.toIso8601String(),
      });
      return;
    }
    final current = (rows.first['quantity'] as num).toDouble();
    await txn.update(
      'inventory',
      {'quantity': current + delta, 'updated_at': now.toIso8601String()},
      where: 'product_id = ?',
      whereArgs: [productId],
    );
  }

  /// 手動在庫調整（理由必須）。
  Future<void> adjust({
    required String productId,
    required double quantityDelta,
    required InventoryAdjustmentReason reason,
    String? memo,
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      await applyDelta(txn, productId, quantityDelta);
      final entry = InventoryAdjustment(
        id: _uuid.v4(),
        productId: productId,
        quantityDelta: quantityDelta,
        reason: reason,
        memo: memo,
        createdAt: DateTime.now(),
      );
      await txn.insert('inventory_adjustments', entry.toMap());
      await AuditLogService.instance.log(
        txn,
        entityType: 'inventory',
        entityId: productId,
        action: 'adjust',
        after: entry.toMap(),
      );
    });
  }

  Future<List<InventoryAdjustment>> historyFor(String productId) async {
    final db = await _db;
    final rows = await db.query(
      'inventory_adjustments',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'created_at DESC',
    );
    return rows.map(InventoryAdjustment.fromMap).toList();
  }
}
