/// フルバックアップ／インポートで扱うテーブルと主キー列の定義。
class BackupTableDef {
  final String table;
  final String primaryKey;
  const BackupTableDef(this.table, this.primaryKey);
}

const List<BackupTableDef> backupTables = [
  BackupTableDef('suppliers', 'id'),
  BackupTableDef('products', 'id'),
  BackupTableDef('purchases', 'id'),
  BackupTableDef('purchase_items', 'id'),
  BackupTableDef('product_cost', 'product_id'),
  BackupTableDef('inventory', 'product_id'),
  BackupTableDef('inventory_adjustments', 'id'),
  BackupTableDef('customers', 'id'),
  BackupTableDef('orders', 'id'),
  BackupTableDef('order_items', 'id'),
  BackupTableDef('shipments', 'id'),
  BackupTableDef('price_history', 'id'),
  BackupTableDef('app_settings', 'key'),
];

const backupFormatVersion = 1;
