import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// モバイル(Android/iOS)実装。SQLCipherでDBファイル全体を暗号化する。
Future<Database> openAppDatabase({
  required String path,
  required String? password,
  required int version,
  required FutureOr<void> Function(Database db) onCreate,
  required FutureOr<void> Function(Database db, int oldVersion, int newVersion) onUpgrade,
}) {
  return openDatabase(
    path,
    password: password,
    version: version,
    onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    },
    onCreate: (db, v) => onCreate(db),
    onUpgrade: (db, oldV, newV) => onUpgrade(db, oldV, newV),
  );
}

Future<void> deleteAppDatabase(String path) => deleteDatabase(path);

/// アプリ専用ディレクトリ配下の実ファイルパスを返す（他アプリからアクセス不可）。
Future<String> resolveAppDatabasePath(String fileName) async {
  final dir = await getApplicationDocumentsDirectory();
  return p.join(dir.path, fileName);
}

/// DB暗号化に対応しているか（モバイルではSQLCipherにより常にtrue）。
const bool isDatabaseEncryptionSupported = true;
