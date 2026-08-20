import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../core/audit/audit_log_service.dart';
import '../core/db/app_database.dart';
import '../models/price_history.dart';
import '../models/product.dart';

class ProductRepository {
  ProductRepository._();
  static final ProductRepository instance = ProductRepository._();

  static const _uuid = Uuid();

  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<Product>> listAll({bool includeInactive = true}) async {
    final db = await _db;
    final rows = await db.query(
      'products',
      where: includeInactive ? null : 'is_active = 1',
      orderBy: 'name ASC',
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<Product?> findById(String id) async {
    final db = await _db;
    final rows = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  Future<Product> create({
    required String name,
    String? shortName,
    required String purchaseUnit,
    required double purchaseQty,
    required int purchasePrice,
    required double minSaleUnit,
    required String unitLabel,
    required int priceX1,
    required int priceX3,
    required int priceX5,
    String? shippingNote,
    double lowStockThreshold = 0,
    String? memo,
  }) async {
    final db = await _db;
    final now = DateTime.now();
    final product = Product(
      id: _uuid.v4(),
      name: name,
      shortName: shortName,
      purchaseUnit: purchaseUnit,
      purchaseQty: purchaseQty,
      purchasePrice: purchasePrice,
      minSaleUnit: minSaleUnit,
      unitLabel: unitLabel,
      priceX1: priceX1,
      priceX3: priceX3,
      priceX5: priceX5,
      shippingNote: shippingNote,
      isActive: true,
      lowStockThreshold: lowStockThreshold,
      memo: memo,
      createdAt: now,
      updatedAt: now,
    );

    await db.transaction((txn) async {
      await txn.insert('products', product.toMap());
      await txn.insert('inventory', {
        'product_id': product.id,
        'quantity': 0.0,
        'reserved_quantity': 0.0,
        'updated_at': now.toIso8601String(),
      });
      await txn.insert(
        'price_history',
        PriceHistory(
          id: _uuid.v4(),
          productId: product.id,
          priceX1: priceX1,
          priceX3: priceX3,
          priceX5: priceX5,
          changedAt: now,
        ).toMap(),
      );
      await AuditLogService.instance.log(
        txn,
        entityType: 'product',
        entityId: product.id,
        action: 'create',
        after: product.toMap(),
      );
    });

    return product;
  }

  /// 商品情報を更新する。価格(×1/×3/×5)が変わった場合のみ price_history に追記し、
  /// 過去の販売記録(order_items)には一切影響しない（要件28, 38）。
  Future<Product> update(Product updated) async {
    final db = await _db;
    final existing = await findById(updated.id);
    if (existing == null) {
      throw StateError('product not found: ${updated.id}');
    }

    await db.transaction((txn) async {
      await txn.update(
        'products',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [updated.id],
      );

      final priceChanged = existing.priceX1 != updated.priceX1 ||
          existing.priceX3 != updated.priceX3 ||
          existing.priceX5 != updated.priceX5;
      if (priceChanged) {
        await txn.insert(
          'price_history',
          PriceHistory(
            id: _uuid.v4(),
            productId: updated.id,
            priceX1: updated.priceX1,
            priceX3: updated.priceX3,
            priceX5: updated.priceX5,
            changedAt: DateTime.now(),
          ).toMap(),
        );
      }

      await AuditLogService.instance.log(
        txn,
        entityType: 'product',
        entityId: updated.id,
        action: 'update',
        before: existing.toMap(),
        after: updated.toMap(),
      );
    });

    return updated;
  }

  /// 商品は物理削除せず「販売停止」として管理する（要件3, 35）。
  Future<void> setActive(String productId, bool isActive) async {
    final product = await findById(productId);
    if (product == null) return;
    await update(product.copyWith(isActive: isActive));
  }

  Future<List<PriceHistory>> priceHistoryFor(String productId) async {
    final db = await _db;
    final rows = await db.query(
      'price_history',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'changed_at DESC',
    );
    return rows.map(PriceHistory.fromMap).toList();
  }
}
