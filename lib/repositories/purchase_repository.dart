import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../core/audit/audit_log_service.dart';
import '../core/db/app_database.dart';
import '../core/pricing/cost_strategy.dart';
import '../models/enums.dart';
import '../models/purchase.dart';
import '../models/purchase_item.dart';
import 'inventory_repository.dart';

class PurchaseItemInput {
  final String productId;
  final double quantity;
  final int itemCost;
  final int shippingCost;
  final int fee;
  final int adjustment;
  final int actualPaid;

  const PurchaseItemInput({
    required this.productId,
    required this.quantity,
    required this.itemCost,
    required this.shippingCost,
    required this.fee,
    required this.adjustment,
    required this.actualPaid,
  });
}

class PurchaseWithItems {
  final Purchase purchase;
  final List<PurchaseItem> items;
  const PurchaseWithItems({required this.purchase, required this.items});
}

class PurchaseRepository {
  PurchaseRepository._();
  static final PurchaseRepository instance = PurchaseRepository._();

  static const _uuid = Uuid();
  final _costStrategy = MovingAverageCostStrategy();

  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<Purchase>> listAll() async {
    final db = await _db;
    final rows = await db.query('purchases', orderBy: 'purchase_date DESC');
    return rows.map(Purchase.fromMap).toList();
  }

  Future<List<PurchaseItem>> itemsFor(String purchaseId) async {
    final db = await _db;
    final rows =
        await db.query('purchase_items', where: 'purchase_id = ?', whereArgs: [purchaseId]);
    return rows.map(PurchaseItem.fromMap).toList();
  }

  Future<Purchase?> findById(String id) async {
    final db = await _db;
    final rows = await db.query('purchases', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Purchase.fromMap(rows.first);
  }

  Future<PurchaseWithItems> create({
    required String supplierId,
    required DateTime purchaseDate,
    required List<PurchaseItemInput> items,
    String? memo,
  }) async {
    final db = await _db;
    final now = DateTime.now();
    final purchase = Purchase(
      id: _uuid.v4(),
      supplierId: supplierId,
      purchaseDate: purchaseDate,
      status: PurchaseStatus.beforeOrder,
      memo: memo,
      createdAt: now,
      updatedAt: now,
    );

    final purchaseItems = items
        .map((i) => PurchaseItem(
              id: _uuid.v4(),
              purchaseId: purchase.id,
              productId: i.productId,
              quantity: i.quantity,
              itemCost: i.itemCost,
              shippingCost: i.shippingCost,
              fee: i.fee,
              adjustment: i.adjustment,
              actualPaid: i.actualPaid,
              receivedQuantity: null,
              createdAt: now,
              updatedAt: now,
            ))
        .toList();

    await db.transaction((txn) async {
      await txn.insert('purchases', purchase.toMap());
      for (final item in purchaseItems) {
        await txn.insert('purchase_items', item.toMap());
      }
      await AuditLogService.instance.log(
        txn,
        entityType: 'purchase',
        entityId: purchase.id,
        action: 'create',
        after: purchase.toMap(),
      );
    });

    return PurchaseWithItems(purchase: purchase, items: purchaseItems);
  }

  Future<void> updateStatus(String purchaseId, PurchaseStatus status) async {
    final db = await _db;
    final existing = await findById(purchaseId);
    if (existing == null) return;
    final updated = existing.copyWith(status: status);
    await db.transaction((txn) async {
      await txn.update('purchases', updated.toMap(), where: 'id = ?', whereArgs: [purchaseId]);
      await AuditLogService.instance.log(
        txn,
        entityType: 'purchase',
        entityId: purchaseId,
        action: 'status_change',
        before: existing.toMap(),
        after: updated.toMap(),
      );
    });
  }

  Future<void> registerTracking(String purchaseId, String trackingNumber) async {
    final db = await _db;
    final existing = await findById(purchaseId);
    if (existing == null) return;
    final updated = existing.copyWith(trackingNumber: trackingNumber);
    await db.transaction((txn) async {
      await txn.update('purchases', updated.toMap(), where: 'id = ?', whereArgs: [purchaseId]);
      await AuditLogService.instance.log(
        txn,
        entityType: 'purchase',
        entityId: purchaseId,
        action: 'tracking_registered',
        before: existing.toMap(),
        after: updated.toMap(),
      );
    });
  }

  Future<void> registerArrival(String purchaseId, DateTime arrivalDate) async {
    final db = await _db;
    final existing = await findById(purchaseId);
    if (existing == null) return;
    final updated = existing.copyWith(
      arrivalDate: arrivalDate,
      status: existing.status == PurchaseStatus.beforeOrder ||
              existing.status == PurchaseStatus.ordered
          ? existing.status
          : PurchaseStatus.arrived,
    );
    await db.transaction((txn) async {
      await txn.update('purchases', updated.toMap(), where: 'id = ?', whereArgs: [purchaseId]);
    });
  }

  /// 入荷処理。同一明細を複数回実行しても、指定した入荷数量と既存の入荷済み数量の
  /// 「差分」だけが在庫・原価に反映されるため、二重加算は発生しない（要件8）。
  /// 入荷数量を後から修正したい場合も同じ関数を使い、newReceivedQuantityに新しい値を渡す。
  Future<void> receiveItem({
    required String purchaseItemId,
    required double newReceivedQuantity,
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      final rows = await txn
          .query('purchase_items', where: 'id = ?', whereArgs: [purchaseItemId]);
      if (rows.isEmpty) return;
      final item = PurchaseItem.fromMap(rows.first);

      final previousQty = item.receivedQuantity ?? 0;
      final delta = newReceivedQuantity - previousQty;
      if (delta == 0) return;

      final unitActualPaid = item.quantity > 0 ? item.actualPaid / item.quantity : 0;
      final costDelta = (unitActualPaid * delta).round();

      await InventoryRepository.instance.applyDelta(txn, item.productId, delta);
      await _costStrategy.applyReceiving(
        txn: txn,
        productId: item.productId,
        receivedQuantityDelta: delta,
        costDelta: costDelta,
      );

      final updatedItem = item.copyWith(receivedQuantity: newReceivedQuantity);
      await txn.update(
        'purchase_items',
        updatedItem.toMap(),
        where: 'id = ?',
        whereArgs: [purchaseItemId],
      );

      await AuditLogService.instance.log(
        txn,
        entityType: 'purchase_item',
        entityId: purchaseItemId,
        action: 'receive',
        before: {'received_quantity': previousQty},
        after: {'received_quantity': newReceivedQuantity},
      );

      // 全明細が入荷済みなら仕入れステータスを自動的に「入荷処理済み」にする。
      final siblingRows = await txn
          .query('purchase_items', where: 'purchase_id = ?', whereArgs: [item.purchaseId]);
      final allReceived = siblingRows.every((r) {
        final receivedQ = r['received_quantity'];
        final qty = (r['quantity'] as num).toDouble();
        return receivedQ != null && (receivedQ as num).toDouble() >= qty;
      });
      if (allReceived) {
        final purchaseRows =
            await txn.query('purchases', where: 'id = ?', whereArgs: [item.purchaseId]);
        if (purchaseRows.isNotEmpty) {
          final purchase = Purchase.fromMap(purchaseRows.first);
          if (purchase.status != PurchaseStatus.received) {
            final updated = purchase.copyWith(status: PurchaseStatus.received);
            await txn.update('purchases', updated.toMap(),
                where: 'id = ?', whereArgs: [purchase.id]);
          }
        }
      }
    });
  }

  Future<void> cancel(String purchaseId) => updateStatus(purchaseId, PurchaseStatus.cancelled);
}
