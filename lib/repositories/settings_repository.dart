import 'package:sqflite_sqlcipher/sqflite.dart';

import '../core/db/app_database.dart';
import '../models/app_settings.dart';

class SettingsRepository {
  SettingsRepository._();
  static final SettingsRepository instance = SettingsRepository._();

  Future<Database> get _db async => AppDatabase.instance.database;

  static const Map<String, String> _defaults = {
    AppSettingsKeys.costStrategy: 'movingAverage',
    AppSettingsKeys.autoLockSeconds: '30',
    AppSettingsKeys.lockOnBackground: 'true',
    AppSettingsKeys.lockOnLaunch: 'true',
    AppSettingsKeys.notificationsEnabled: 'true',
    AppSettingsKeys.notifyUnshippedDays: '2',
    AppSettingsKeys.notifyPurchaseOverdueDays: '14',
    AppSettingsKeys.defaultShippingCarrier: 'レターパックライト',
    AppSettingsKeys.buyerShippingIncludedInPrice: 'true',
  };

  Future<String> getValue(String key) async {
    final db = await _db;
    final rows = await db.query('app_settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return _defaults[key] ?? '';
    return rows.first['value'] as String;
  }

  Future<bool> getBool(String key) async => (await getValue(key)) == 'true';

  Future<int> getInt(String key) async => int.tryParse(await getValue(key)) ?? 0;

  Future<void> setValue(String key, String value) async {
    final db = await _db;
    await db.insert(
      'app_settings',
      AppSetting(key: key, value: value).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setBool(String key, bool value) => setValue(key, value.toString());

  Future<void> setInt(String key, int value) => setValue(key, value.toString());

  Future<Map<String, String>> getAll() async {
    final db = await _db;
    final rows = await db.query('app_settings');
    final result = Map<String, String>.from(_defaults);
    for (final row in rows) {
      result[row['key'] as String] = row['value'] as String;
    }
    return result;
  }
}
