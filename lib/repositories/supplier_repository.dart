import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../core/db/app_database.dart';
import '../models/supplier.dart';

class SupplierRepository {
  SupplierRepository._();
  static final SupplierRepository instance = SupplierRepository._();

  static const _uuid = Uuid();

  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<Supplier>> listAll() async {
    final db = await _db;
    final rows = await db.query('suppliers', orderBy: 'name ASC');
    return rows.map(Supplier.fromMap).toList();
  }

  Future<Supplier> create({required String name, String? contact, String? memo}) async {
    final db = await _db;
    final now = DateTime.now();
    final supplier = Supplier(
      id: _uuid.v4(),
      name: name,
      contact: contact,
      memo: memo,
      createdAt: now,
      updatedAt: now,
    );
    await db.insert('suppliers', supplier.toMap());
    return supplier;
  }

  /// 初回起動時、仕入先が1件も無ければ既定の仕入先を1件作成しておく
  /// （現状1社運用だが、将来複数対応できるデータ構造は維持）。
  Future<Supplier> ensureDefault() async {
    final all = await listAll();
    if (all.isNotEmpty) return all.first;
    return create(name: '既定の仕入先');
  }
}
