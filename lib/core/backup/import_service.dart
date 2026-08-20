import 'package:sqflite_sqlcipher/sqflite.dart';

import '../db/app_database.dart';
import 'backup_tables.dart';

/// テーブルごとの外部キー列 -> 参照先テーブル名。
/// インポート時に参照先IDが（ローカル・インポートデータのいずれにも）存在しない行は
/// 「競合」として取り込み対象から除外する。
const Map<String, Map<String, String>> _foreignKeys = {
  'purchases': {'supplier_id': 'suppliers'},
  'purchase_items': {'purchase_id': 'purchases', 'product_id': 'products'},
  'product_cost': {'product_id': 'products'},
  'inventory': {'product_id': 'products'},
  'inventory_adjustments': {'product_id': 'products'},
  'orders': {'customer_id': 'customers'},
  'order_items': {'order_id': 'orders', 'product_id': 'products'},
  'shipments': {'order_id': 'orders'},
  'price_history': {'product_id': 'products'},
};

class TableDiff {
  final String table;
  final int newCount;
  final int updateCount;
  final int conflictCount;
  final int unchangedCount;

  const TableDiff({
    required this.table,
    required this.newCount,
    required this.updateCount,
    required this.conflictCount,
    required this.unchangedCount,
  });
}

class ImportPreview {
  final List<TableDiff> perTable;
  final Map<String, dynamic> rawData;

  const ImportPreview({required this.perTable, required this.rawData});

  int get totalNew => perTable.fold(0, (a, b) => a + b.newCount);
  int get totalUpdate => perTable.fold(0, (a, b) => a + b.updateCount);
  int get totalConflict => perTable.fold(0, (a, b) => a + b.conflictCount);
}

class ImportService {
  ImportService._();
  static final ImportService instance = ImportService._();

  Future<Database> get _db async => AppDatabase.instance.database;

  Future<Set<String>> _localIds(DatabaseExecutor db, String table, String pk) async {
    final rows = await db.query(table, columns: [pk]);
    return rows.map((r) => r[pk].toString()).toSet();
  }

  bool _rowsEqual(Map<String, Object?> a, Map<String, Object?> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key].toString() != b[key].toString()) return false;
    }
    return true;
  }

  Future<ImportPreview> preview(Map<String, dynamic> importedData) async {
    final db = await _db;
    final diffs = <TableDiff>[];

    // 参照整合性チェック用に、テーブルごとのID集合（ローカル ∪ インポート）を先に構築する。
    final importedIdsByTable = <String, Set<String>>{};
    for (final def in backupTables) {
      final rows = (importedData[def.table] as List?)?.cast<Map<String, dynamic>>() ?? [];
      importedIdsByTable[def.table] =
          rows.map((r) => r[def.primaryKey].toString()).toSet();
    }
    final localIdsByTable = <String, Set<String>>{};
    for (final def in backupTables) {
      localIdsByTable[def.table] = await _localIds(db, def.table, def.primaryKey);
    }

    for (final def in backupTables) {
      final rows = (importedData[def.table] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final localIds = localIdsByTable[def.table]!;
      final fkDefs = _foreignKeys[def.table];

      int newCount = 0, updateCount = 0, conflictCount = 0, unchangedCount = 0;

      for (final row in rows) {
        bool hasConflict = false;
        if (fkDefs != null) {
          for (final entry in fkDefs.entries) {
            final refValue = row[entry.key]?.toString();
            if (refValue == null) continue;
            final refTableIds = {
              ...localIdsByTable[entry.value] ?? {},
              ...importedIdsByTable[entry.value] ?? {},
            };
            if (!refTableIds.contains(refValue)) {
              hasConflict = true;
              break;
            }
          }
        }
        if (hasConflict) {
          conflictCount++;
          continue;
        }

        final id = row[def.primaryKey].toString();
        if (!localIds.contains(id)) {
          newCount++;
        } else {
          final localRows =
              await db.query(def.table, where: '${def.primaryKey} = ?', whereArgs: [id]);
          final local = localRows.first;
          if (_rowsEqual(Map<String, Object?>.from(local), Map<String, Object?>.from(row))) {
            unchangedCount++;
          } else {
            updateCount++;
          }
        }
      }

      diffs.add(TableDiff(
        table: def.table,
        newCount: newCount,
        updateCount: updateCount,
        conflictCount: conflictCount,
        unchangedCount: unchangedCount,
      ));
    }

    return ImportPreview(perTable: diffs, rawData: importedData);
  }

  /// プレビュー確認後にユーザーが確定した場合のみ呼び出す。
  /// 競合行(参照整合性が取れない行)は取り込まずスキップする。
  Future<void> apply(ImportPreview preview) async {
    final db = await _db;
    final importedIdsByTable = <String, Set<String>>{};
    for (final def in backupTables) {
      final rows =
          (preview.rawData[def.table] as List?)?.cast<Map<String, dynamic>>() ?? [];
      importedIdsByTable[def.table] = rows.map((r) => r[def.primaryKey].toString()).toSet();
    }

    await db.transaction((txn) async {
      for (final def in backupTables) {
        final rows =
            (preview.rawData[def.table] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final fkDefs = _foreignKeys[def.table];
        final localIds = await _localIds(txn, def.table, def.primaryKey);

        for (final row in rows) {
          bool hasConflict = false;
          if (fkDefs != null) {
            for (final entry in fkDefs.entries) {
              final refValue = row[entry.key]?.toString();
              if (refValue == null) continue;
              final localRefIds =
                  (await txn.query(entry.value, columns: ['id']))
                      .map((r) => r['id'].toString())
                      .toSet();
              final refTableIds = {...localRefIds, ...importedIdsByTable[entry.value] ?? {}};
              if (!refTableIds.contains(refValue)) {
                hasConflict = true;
                break;
              }
            }
          }
          if (hasConflict) continue;

          await txn.insert(
            def.table,
            Map<String, Object?>.from(row),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          localIds.add(row[def.primaryKey].toString());
        }
      }
    });
  }
}
