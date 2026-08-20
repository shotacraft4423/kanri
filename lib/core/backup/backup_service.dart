import 'dart:convert';

import 'package:cross_file/cross_file.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../db/app_database.dart';
import 'backup_tables.dart';
import 'crypto_util.dart';

/// 端末を移行できる完全バックアップの出力・復号。
/// 顧客情報を含む全データをユーザー指定パスワードでAES-256-GCM暗号化した
/// 単一ファイル(.kanribackup)として書き出す。パスワードはアプリ内のどこにも保存されない。
///
/// dart:io を使わずメモリ上で暗号化し、XFileとして返す（Web版含む全プラットフォーム共通）。
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

  /// 暗号化フルバックアップファイル(XFile)を作成する。
  Future<XFile> exportEncryptedBackup({required String password}) async {
    final data = await _collectAllData();
    final envelope = {
      'appName': 'kanri',
      'formatVersion': backupFormatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': data,
    };
    final plainJson = jsonEncode(envelope);
    final encrypted = await CryptoUtil.encryptToPortableString(plainJson, password);

    final fileName = 'kanri_backup_${DateTime.now().millisecondsSinceEpoch}.kanribackup';
    return XFile.fromData(utf8.encode(encrypted), name: fileName, mimeType: 'application/json');
  }

  Future<Map<String, dynamic>> decryptBackupData({
    required List<int> bytes,
    required String password,
  }) async {
    final content = utf8.decode(bytes);
    final decrypted = await CryptoUtil.decryptFromPortableString(content, password);
    final envelope = jsonDecode(decrypted) as Map<String, dynamic>;
    return envelope;
  }
}
