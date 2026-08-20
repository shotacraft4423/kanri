import 'package:intl/intl.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../core/audit/audit_log_service.dart';
import '../core/db/app_database.dart';
import '../core/pricing/profit_calculator.dart';
import '../models/enums.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/product.dart';
import '../models/shipment.dart';
import 'inventory_repository.dart';

class SaleLineInput {
  final Product product;
  final double quantity;
  final int unitPrice; // このライン合計金額（帯価格 or 自由入力）
  final PriceTier priceTier;

  const SaleLineInput({
    required this.product,
    required this.quantity,
    required this.unitPrice,
    required this.priceTier,
  });
}

class OrderWithDetails {
  final Order order;
  final List<OrderItem> items;
  final Shipment shipment;
  const OrderWithDetails({required this.order, required this.items, required this.shipment});
}

class SalesRepository {
  SalesRepository._();
  static final SalesRepository instance = SalesRepository._();

  static const _uuid = Uuid();

  Future<Database> get _db async => AppDatabase.instance.database;

  Future<String> _nextOrderNumber(Transaction txn, DateTime date) async {
    final dateStr = DateFormat('yyyyMMdd').format(date);
    final result = await txn.rawQuery(
      "SELECT COUNT(*) as cnt FROM orders WHERE order_number LIKE ?",
      ['$dateStr-%'],
    );
    final count = Sqflite.firstIntValue(result) ?? 0;
    return '$dateStr-${(count + 1).toString().padLeft(3, '0')}';
  }

  /// 販売登録。在庫を即時減算し、発送レコード（未発送）を自動生成する。
  /// 各明細の原価は現在の移動平均原価をスナップショットして凍結する。
  Future<OrderWithDetails> createOrder({
    required String customerId,
    required DateTime orderDate,
    required List<SaleLineInput> lines,
    String? memo,
  }) async {
    final db = await _db;
    final now = DateTime.now();
    final orderId = _uuid.v4();

    late Order order;
    final items = <OrderItem>[];
    late Shipment shipment;

    await db.transaction((txn) async {
      final orderNumber = await _nextOrderNumber(txn, orderDate);
      order = Order(
        id: orderId,
        orderNumber: orderNumber,
        orderDate: orderDate,
        customerId: customerId,
        memo: memo,
        createdAt: now,
        updatedAt: now,
      );
      await txn.insert('orders', order.toMap());

      for (final line in lines) {
        final costRows = await txn.query(
          'product_cost',
          where: 'product_id = ?',
          whereArgs: [line.product.id],
        );
        final avgUnitCost = costRows.isNotEmpty ? costRows.first['avg_unit_cost'] as int : 0;
        final unitCostTotal = ProfitCalculator.costTotalForQuantity(
          avgUnitCost: avgUnitCost,
          quantity: line.quantity,
        );
        final profit = ProfitCalculator.calcProfit(
          lineTotal: line.unitPrice,
          unitCostTotal: unitCostTotal,
        );

        final item = OrderItem(
          id: _uuid.v4(),
          orderId: orderId,
          productId: line.product.id,
          quantity: line.quantity,
          unitPrice: line.unitPrice,
          priceTier: line.priceTier,
          lineTotal: line.unitPrice,
          unitCost: unitCostTotal,
          profit: profit,
          createdAt: now,
          updatedAt: now,
        );
        await txn.insert('order_items', item.toMap());
        items.add(item);

        await InventoryRepository.instance.applyDelta(txn, line.product.id, -line.quantity);
      }

      shipment = Shipment(
        id: _uuid.v4(),
        orderId: orderId,
        status: ShipmentStatus.notShipped,
        createdAt: now,
        updatedAt: now,
      );
      await txn.insert('shipments', shipment.toMap());

      await AuditLogService.instance.log(
        txn,
        entityType: 'order',
        entityId: orderId,
        action: 'create',
        after: order.toMap(),
      );
    });

    return OrderWithDetails(order: order, items: items, shipment: shipment);
  }

  Future<List<Order>> listAll() async {
    final db = await _db;
    final rows = await db.query('orders', orderBy: 'order_date DESC');
    return rows.map(Order.fromMap).toList();
  }

  Future<List<OrderItem>> itemsFor(String orderId) async {
    final db = await _db;
    final rows = await db.query('order_items', where: 'order_id = ?', whereArgs: [orderId]);
    return rows.map(OrderItem.fromMap).toList();
  }

  /// 販売キャンセル。在庫を戻し、発送もキャンセル扱いにする。
  Future<void> cancelOrder(String orderId) async {
    final db = await _db;
    await db.transaction((txn) async {
      final orderRows = await txn.query('orders', where: 'id = ?', whereArgs: [orderId]);
      if (orderRows.isEmpty) return;
      final order = Order.fromMap(orderRows.first);
      if (order.isCancelled) return;

      final itemRows = await txn.query('order_items', where: 'order_id = ?', whereArgs: [orderId]);
      for (final row in itemRows) {
        final item = OrderItem.fromMap(row);
        await InventoryRepository.instance.applyDelta(txn, item.productId, item.quantity);
      }

      final updatedOrder = order.copyWith(isCancelled: true);
      await txn.update('orders', updatedOrder.toMap(), where: 'id = ?', whereArgs: [orderId]);

      final shipmentRows =
          await txn.query('shipments', where: 'order_id = ?', whereArgs: [orderId]);
      if (shipmentRows.isNotEmpty) {
        final shipment = Shipment.fromMap(shipmentRows.first);
        final updatedShipment = shipment.copyWith(status: ShipmentStatus.cancelled);
        await txn.update('shipments', updatedShipment.toMap(),
            where: 'id = ?', whereArgs: [shipment.id]);
      }

      await AuditLogService.instance.log(
        txn,
        entityType: 'order',
        entityId: orderId,
        action: 'cancel',
        before: order.toMap(),
        after: updatedOrder.toMap(),
      );
    });
  }
}
