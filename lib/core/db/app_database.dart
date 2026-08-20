import 'package:sqflite_sqlcipher/sqflite.dart';

import '../security/secure_storage_service.dart';
import 'platform/db_opener.dart';

/// モバイル(Android/iOS)ではSQLCipherで全面暗号化されたローカルDBへの唯一の接続窓口。
/// 暗号化パスフレーズはOSセキュアストレージにのみ存在し、DBファイル本体はどのアプリ内コードにも
/// 平文で書き出さない。
/// Web版（動作確認用ビルド）ではブラウザ内(IndexedDB)に保存し、暗号化は行わない
/// （isDatabaseEncryptionSupportedがfalseになる。docs/DESIGN.mdの制約事項を参照）。
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const int schemaVersion = 1;
  static const String _fileName = 'kanri_secure.db';

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await resolveAppDatabasePath(_fileName);
    final passphrase = isDatabaseEncryptionSupported
        ? await SecureStorageService.instance.getOrCreateDbPassphrase()
        : null;

    return openAppDatabase(
      path: dbPath,
      password: passphrase,
      version: schemaVersion,
      onCreate: (db) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // 将来のスキーマ変更はここにマイグレーションステップを追記する。
      },
    );
  }

  Future<void> _createSchema(Database db) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE suppliers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        contact TEXT,
        memo TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        short_name TEXT,
        purchase_unit TEXT NOT NULL,
        purchase_qty REAL NOT NULL,
        purchase_price INTEGER NOT NULL,
        min_sale_unit REAL NOT NULL,
        unit_label TEXT NOT NULL,
        price_x1 INTEGER NOT NULL,
        price_x3 INTEGER NOT NULL,
        price_x5 INTEGER NOT NULL,
        shipping_note TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        low_stock_threshold REAL NOT NULL DEFAULT 0,
        memo TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE purchases (
        id TEXT PRIMARY KEY,
        supplier_id TEXT NOT NULL REFERENCES suppliers(id),
        purchase_date TEXT NOT NULL,
        status TEXT NOT NULL,
        tracking_number TEXT,
        arrival_date TEXT,
        memo TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE purchase_items (
        id TEXT PRIMARY KEY,
        purchase_id TEXT NOT NULL REFERENCES purchases(id),
        product_id TEXT NOT NULL REFERENCES products(id),
        quantity REAL NOT NULL,
        item_cost INTEGER NOT NULL,
        shipping_cost INTEGER NOT NULL,
        fee INTEGER NOT NULL,
        adjustment INTEGER NOT NULL,
        actual_paid INTEGER NOT NULL,
        received_quantity REAL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE product_cost (
        product_id TEXT PRIMARY KEY REFERENCES products(id),
        avg_unit_cost INTEGER NOT NULL,
        total_received_quantity REAL NOT NULL,
        total_received_cost INTEGER NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE inventory (
        product_id TEXT PRIMARY KEY REFERENCES products(id),
        quantity REAL NOT NULL DEFAULT 0,
        reserved_quantity REAL NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE inventory_adjustments (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL REFERENCES products(id),
        quantity_delta REAL NOT NULL,
        reason TEXT NOT NULL,
        memo TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        postal_code TEXT,
        address TEXT,
        phone TEXT,
        memo TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        order_number TEXT NOT NULL,
        order_date TEXT NOT NULL,
        customer_id TEXT NOT NULL REFERENCES customers(id),
        memo TEXT,
        is_cancelled INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE order_items (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL REFERENCES orders(id),
        product_id TEXT NOT NULL REFERENCES products(id),
        quantity REAL NOT NULL,
        unit_price INTEGER NOT NULL,
        price_tier TEXT NOT NULL,
        line_total INTEGER NOT NULL,
        unit_cost INTEGER NOT NULL,
        profit INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE shipments (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL UNIQUE REFERENCES orders(id),
        status TEXT NOT NULL,
        carrier TEXT NOT NULL,
        tracking_number TEXT,
        shipped_at TEXT,
        arrived_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE price_history (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL REFERENCES products(id),
        price_x1 INTEGER NOT NULL,
        price_x3 INTEGER NOT NULL,
        price_x5 INTEGER NOT NULL,
        changed_at TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE audit_logs (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        action TEXT NOT NULL,
        before_json TEXT,
        after_json TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    batch.execute('CREATE INDEX idx_purchase_items_purchase ON purchase_items(purchase_id)');
    batch.execute('CREATE INDEX idx_purchase_items_product ON purchase_items(product_id)');
    batch.execute('CREATE INDEX idx_order_items_order ON order_items(order_id)');
    batch.execute('CREATE INDEX idx_order_items_product ON order_items(product_id)');
    batch.execute('CREATE INDEX idx_orders_customer ON orders(customer_id)');
    batch.execute('CREATE INDEX idx_shipments_status ON shipments(status)');
    batch.execute('CREATE INDEX idx_purchases_status ON purchases(status)');
    batch.execute('CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id)');

    await batch.commit(noResult: true);
  }

  /// アプリデータ完全初期化（設定画面の専用確認フローからのみ呼び出すこと）。
  Future<void> deleteDatabaseFile() async {
    final dbPath = await resolveAppDatabasePath(_fileName);
    await _db?.close();
    _db = null;
    await deleteAppDatabase(dbPath);
  }
}
