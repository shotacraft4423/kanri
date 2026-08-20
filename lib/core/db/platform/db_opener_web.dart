import 'dart:async';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Web(ブラウザ)向けの確認・検証用実装。
/// ブラウザのsqlite3(wasm)+IndexedDBにデータを保存するため、
/// タブを閉じても同じブラウザ・同じ端末なら再訪時にデータが残る。
/// ただしSQLCipherのようなファイル暗号化には対応していないため、
/// このビルドは「動作確認用」であり、実際の顧客データの本番運用には使用しないこと
/// （docs/DESIGN.mdの実行環境に関する制約事項を参照）。
Future<Database> openAppDatabase({
  required String path,
  required String? password,
  required int version,
  required FutureOr<void> Function(Database db) onCreate,
  required FutureOr<void> Function(Database db, int oldVersion, int newVersion) onUpgrade,
}) {
  return databaseFactoryFfiWeb.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: version,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, v) => onCreate(db),
      onUpgrade: (db, oldV, newV) => onUpgrade(db, oldV, newV),
    ),
  );
}

Future<void> deleteAppDatabase(String path) => databaseFactoryFfiWeb.deleteDatabase(path);

Future<String> resolveAppDatabasePath(String fileName) async => fileName;

const bool isDatabaseEncryptionSupported = false;
