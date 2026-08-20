import 'package:sqflite_sqlcipher/sqflite.dart';

import '../core/db/app_database.dart';

class DashboardSummary {
  final int unshippedCount;
  final int preparingCount;
  final int shippedCount;
  final int inTransitCount;
  final int deliveredCount;
  final int purchaseAwaitingArrivalCount;
  final int purchaseAwaitingReceivingCount;
  final int outOfStockCount;
  final int lowStockCount;
  final int monthSalesTotal;
  final int monthProfitTotal;
  final int monthOrderCount;
  final int inventoryValueTotal;
  final int todaySalesTotal;

  const DashboardSummary({
    required this.unshippedCount,
    required this.preparingCount,
    required this.shippedCount,
    required this.inTransitCount,
    required this.deliveredCount,
    required this.purchaseAwaitingArrivalCount,
    required this.purchaseAwaitingReceivingCount,
    required this.outOfStockCount,
    required this.lowStockCount,
    required this.monthSalesTotal,
    required this.monthProfitTotal,
    required this.monthOrderCount,
    required this.inventoryValueTotal,
    required this.todaySalesTotal,
  });
}

class DashboardRepository {
  DashboardRepository._();
  static final DashboardRepository instance = DashboardRepository._();

  Future<Database> get _db async => AppDatabase.instance.database;

  Future<int> _countWhere(Database db, String table, String where, List<Object?> args) async {
    final result =
        await db.rawQuery('SELECT COUNT(*) as cnt FROM $table WHERE $where', args);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<DashboardSummary> load() async {
    final db = await _db;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();

    final unshipped = await _countWhere(db, 'shipments', "status = ?", ['notShipped']);
    final preparing = await _countWhere(db, 'shipments', "status = ?", ['preparing']);
    final shipped = await _countWhere(db, 'shipments', "status = ?", ['shipped']);
    final inTransit = await _countWhere(db, 'shipments', "status = ?", ['inTransit']);
    final delivered = await _countWhere(db, 'shipments', "status = ?", ['delivered']);

    final purchaseAwaitingArrival = await _countWhere(
        db, 'purchases', "status IN ('ordered','shipped','inTransit')", []);
    final purchaseAwaitingReceiving =
        await _countWhere(db, 'purchases', "status = ?", ['arrived']);

    final outOfStock = await _countWhere(
        db,
        'inventory inv JOIN products p ON p.id = inv.product_id',
        'p.is_active = 1 AND inv.quantity <= 0',
        []);
    final lowStock = await _countWhere(
        db,
        'inventory inv JOIN products p ON p.id = inv.product_id',
        'p.is_active = 1 AND inv.quantity > 0 AND inv.quantity <= p.low_stock_threshold',
        []);

    final monthSalesRows = await db.rawQuery('''
      SELECT COALESCE(SUM(oi.line_total),0) as sales, COALESCE(SUM(oi.profit),0) as profit,
             COUNT(DISTINCT o.id) as cnt
      FROM order_items oi JOIN orders o ON o.id = oi.order_id
      WHERE o.is_cancelled = 0 AND o.order_date >= ?
    ''', [monthStart]);
    final monthSales = (monthSalesRows.first['sales'] as num).toInt();
    final monthProfit = (monthSalesRows.first['profit'] as num).toInt();
    final monthOrderCount = (monthSalesRows.first['cnt'] as num).toInt();

    final todaySalesRows = await db.rawQuery('''
      SELECT COALESCE(SUM(oi.line_total),0) as sales
      FROM order_items oi JOIN orders o ON o.id = oi.order_id
      WHERE o.is_cancelled = 0 AND o.order_date >= ?
    ''', [todayStart]);
    final todaySales = (todaySalesRows.first['sales'] as num).toInt();

    // inv.quantity と pc.avg_unit_cost は同じ基本単位系（個数やg数そのもの）で
    // 揃っているため、最小販売単位で割り戻さずそのまま乗じる。
    final inventoryValueRows = await db.rawQuery('''
      SELECT COALESCE(SUM(inv.quantity * COALESCE(pc.avg_unit_cost,0)),0) as value
      FROM inventory inv
      JOIN products p ON p.id = inv.product_id
      LEFT JOIN product_cost pc ON pc.product_id = inv.product_id
    ''');
    final inventoryValue = (inventoryValueRows.first['value'] as num).round();

    return DashboardSummary(
      unshippedCount: unshipped,
      preparingCount: preparing,
      shippedCount: shipped,
      inTransitCount: inTransit,
      deliveredCount: delivered,
      purchaseAwaitingArrivalCount: purchaseAwaitingArrival,
      purchaseAwaitingReceivingCount: purchaseAwaitingReceiving,
      outOfStockCount: outOfStock,
      lowStockCount: lowStock,
      monthSalesTotal: monthSales,
      monthProfitTotal: monthProfit,
      monthOrderCount: monthOrderCount,
      inventoryValueTotal: inventoryValue,
      todaySalesTotal: todaySales,
    );
  }
}
