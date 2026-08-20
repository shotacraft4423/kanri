import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../core/audit/audit_log_service.dart';
import '../core/db/app_database.dart';
import '../models/customer.dart';

class CustomerRepository {
  CustomerRepository._();
  static final CustomerRepository instance = CustomerRepository._();

  static const _uuid = Uuid();

  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<Customer>> listAll() async {
    final db = await _db;
    final rows = await db.query('customers', orderBy: 'name ASC');
    return rows.map(Customer.fromMap).toList();
  }

  Future<Customer?> findById(String id) async {
    final db = await _db;
    final rows = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Customer.fromMap(rows.first);
  }

  Future<List<Customer>> search(String query) async {
    final db = await _db;
    final rows = await db.query(
      'customers',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );
    return rows.map(Customer.fromMap).toList();
  }

  Future<Customer> create({
    required String name,
    String? postalCode,
    String? address,
    String? phone,
    String? memo,
  }) async {
    final db = await _db;
    final now = DateTime.now();
    final customer = Customer(
      id: _uuid.v4(),
      name: name,
      postalCode: postalCode,
      address: address,
      phone: phone,
      memo: memo,
      createdAt: now,
      updatedAt: now,
    );
    await db.transaction((txn) async {
      await txn.insert('customers', customer.toMap());
      await AuditLogService.instance.log(
        txn,
        entityType: 'customer',
        entityId: customer.id,
        action: 'create',
        after: customer.toMap(),
      );
    });
    return customer;
  }

  Future<Customer> update(Customer updated) async {
    final db = await _db;
    final existing = await findById(updated.id);
    await db.transaction((txn) async {
      await txn.update('customers', updated.toMap(), where: 'id = ?', whereArgs: [updated.id]);
      await AuditLogService.instance.log(
        txn,
        entityType: 'customer',
        entityId: updated.id,
        action: 'update',
        before: existing?.toMap(),
        after: updated.toMap(),
      );
    });
    return updated;
  }
}
