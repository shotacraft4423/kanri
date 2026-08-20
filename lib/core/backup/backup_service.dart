import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../db/app_database.dart';
import 'backup_tables.dart';
import 'crypto_util.dart';

/// 端末を移行できる完全バックアップの出力・復号。
/// 顧客情報を含む全データをユーザー指定パスワードでAES-256-GCM暗号化した
/// 単一ファイル(.kanribackup)として書き出す。パスワードはアプリ内のどこにも保存されない。
class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  Future<Database> get _db async => AppDatabase.instance.database;

  Future<Map<String, dynamic>> _collectAllData() async {
    final db = await _db;
    final data = <String, dynamic>{};
    for (final def in backupTables) {
      data[def.table] = await db.query(def.table);
    }
    return data;
  }

  /// 暗号化フルバックアップファイルを作成し、保存先パスを返す。
  Future<File> exportEncryptedBackup({required String password}) async {
    final data = await _collectAllData();
    final envelope = {
      'appName': 'kanri',
      'formatVersion': backupFormatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': data,
    };
    final plainJson = jsonEncode(envelope);
    final encrypted = await CryptoUtil.encryptToPortableString(plainJson, password);

    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${dir.path}/backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    final fileName =
        'kanri_backup_${DateTime.now().millisecondsSinceEpoch}.kanribackup';
    final file = File('${backupDir.path}/$fileName');
    await file.writeAsString(encrypted);
    return file;
  }

  Future<Map<String, dynamic>> decryptBackupFile({
    required File file,
    required String password,
  }) async {
    final content = await file.readAsString();
    final decrypted = await CryptoUtil.decryptFromPortableString(content, password);
    final envelope = jsonDecode(decrypted) as Map<String, dynamic>;
    return envelope;
  }
}
