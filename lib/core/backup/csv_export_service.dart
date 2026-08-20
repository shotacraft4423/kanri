import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

import '../db/app_database.dart';

/// 汎用CSV出力。既定では顧客の氏名・住所・電話番号列を含めない
/// （含める場合は includeCustomerPii=true を明示的に指定し、呼び出し側UIで確認ダイアログを出す）。
class CsvExportService {
  CsvExportService._();
  static final CsvExportService instance = CsvExportService._();

  Future<File> _writeCsv(String name, List<List<Object?>> rows) async {
    final dir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${dir.path}/exports');
    if (!await exportDir.exists()) await exportDir.create(recursive: true);
    final file = File('${exportDir.path}/${name}_${DateTime.now().millisecondsSinceEpoch}.csv');
    final csv = const ListToCsvConverter().convert(rows);
    await file.writeAsString(csv);
    return file;
  }

  Future<File> exportProducts() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('products', orderBy: 'name ASC');
    final data = [
      ['商品ID', '商品名', '略称', '仕入単位', '最小販売単位', '×1価格', '×3価格', '×5価格', '販売状態', '在庫アラート数'],
      ...rows.map((r) => [
            r['id'],
            r['name'],
            r['short_name'],
            r['purchase_unit'],
            r['min_sale_unit'],
            r['price_x1'],
            r['price_x3'],
            r['price_x5'],
            (r['is_active'] as int) == 1 ? '販売中' : '販売停止',
            r['low_stock_threshold'],
          ]),
    ];
    return _writeCsv('products', data);
  }

  Future<File> exportPurchases() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT pu.id, pu.purchase_date, pu.status, pu.tracking_number, pu.arrival_date,
             pi.product_id, p.name as product_name, pi.quantity, pi.item_cost,
             pi.shipping_cost, pi.fee, pi.adjustment, pi.actual_paid, pi.received_quantity
      FROM purchases pu
      JOIN purchase_items pi ON pi.purchase_id = pu.id
      JOIN products p ON p.id = pi.product_id
      ORDER BY pu.purchase_date DESC
    ''');
    final data = [
      ['仕入れID', '仕入れ日', 'ステータス', '追跡番号', '到着日', '商品名', '数量', '商品代', '送料', '手数料', '調整額', '実支払額', '入荷済数量'],
      ...rows.map((r) => [
            r['id'],
            r['purchase_date'],
            r['status'],
            r['tracking_number'],
            r['arrival_date'],
            r['product_name'],
            r['quantity'],
            r['item_cost'],
            r['shipping_cost'],
            r['fee'],
            r['adjustment'],
            r['actual_paid'],
            r['received_quantity'],
          ]),
    ];
    return _writeCsv('purchases', data);
  }

  /// 販売履歴CSV。既定では顧客氏名の代わりに顧客IDのみを出力し、個人情報漏洩を避ける。
  Future<File> exportSales({bool includeCustomerName = false}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT o.id, o.order_number, o.order_date, o.customer_id, c.name as customer_name,
             oi.product_id, p.name as product_name, oi.quantity, oi.unit_price,
             oi.price_tier, oi.line_total, oi.profit
      FROM orders o
      JOIN order_items oi ON oi.order_id = o.id
      JOIN products p ON p.id = oi.product_id
      JOIN customers c ON c.id = o.customer_id
      WHERE o.is_cancelled = 0
      ORDER BY o.order_date DESC
    ''');
    final header = [
      '注文番号',
      '販売日',
      if (includeCustomerName) '顧客名' else '顧客ID',
      '商品名',
      '数量',
      '価格帯',
      '販売価格',
      '利益',
    ];
    final data = [
      header,
      ...rows.map((r) => [
            r['order_number'],
            r['order_date'],
            includeCustomerName ? r['customer_name'] : r['customer_id'],
            r['product_name'],
            r['quantity'],
            r['price_tier'],
            r['line_total'],
            r['profit'],
          ]),
    ];
    return _writeCsv('sales', data);
  }

  Future<File> exportInventory() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT p.id, p.name, inv.quantity, inv.reserved_quantity, p.low_stock_threshold
      FROM products p
      LEFT JOIN inventory inv ON inv.product_id = p.id
      ORDER BY p.name ASC
    ''');
    final data = [
      ['商品ID', '商品名', '現在庫', '予約数', '最低在庫数'],
      ...rows.map((r) => [
            r['id'],
            r['name'],
            r['quantity'] ?? 0,
            r['reserved_quantity'] ?? 0,
            r['low_stock_threshold'],
          ]),
    ];
    return _writeCsv('inventory', data);
  }

  Future<File> exportShipments() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT o.order_number, o.order_date, s.status, s.carrier, s.tracking_number,
             s.shipped_at, s.arrived_at
      FROM shipments s
      JOIN orders o ON o.id = s.order_id
      ORDER BY o.order_date DESC
    ''');
    final data = [
      ['注文番号', '販売日', '発送ステータス', '配送方法', '追跡番号', '発送日', '到着日'],
      ...rows.map((r) => [
            r['order_number'],
            r['order_date'],
            r['status'],
            r['carrier'],
            r['tracking_number'],
            r['shipped_at'],
            r['arrived_at'],
          ]),
    ];
    return _writeCsv('shipments', data);
  }
}
