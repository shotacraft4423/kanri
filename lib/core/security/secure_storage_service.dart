import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// OSのセキュアストレージ (iOS Keychain / Android Keystore裏付けの
/// EncryptedSharedPreferences) にのみ保管する秘匿値のラッパー。
/// DBファイルには一切書き込まない。
class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  // flutter_secure_storage 10+ はAndroidで常にEncryptedSharedPreferencesを使うため
  // 明示的なオプション指定は不要になった。
  static const _androidOptions = AndroidOptions();
  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );

  static const _keyDbPassphrase = 'db_passphrase_v1';
  static const _keyPinHash = 'pin_hash_v1';
  static const _keyPinSalt = 'pin_salt_v1';
  static const _keyFailedAttempts = 'pin_failed_attempts_v1';
  static const _keyLockoutUntil = 'pin_lockout_until_v1';

  String _randomBase64(int bytes) {
    final rnd = Random.secure();
    final list = List<int>.generate(bytes, (_) => rnd.nextInt(256));
    return base64UrlEncode(list);
  }

  /// DB暗号化用パスフレーズ。初回アクセス時に生成し、以後は同じ値を返す。
  Future<String> getOrCreateDbPassphrase() async {
    final existing = await _storage.read(key: _keyDbPassphrase);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = _randomBase64(32);
    await _storage.write(key: _keyDbPassphrase, value: generated);
    return generated;
  }

  Future<bool> hasPin() async {
    final v = await _storage.read(key: _keyPinHash);
    return v != null && v.isNotEmpty;
  }

  Future<String> savePinSalt() async {
    final salt = _randomBase64(16);
    await _storage.write(key: _keyPinSalt, value: salt);
    return salt;
  }

  Future<String?> readPinSalt() => _storage.read(key: _keyPinSalt);

  Future<void> savePinHash(String hash) =>
      _storage.write(key: _keyPinHash, value: hash);

  Future<String?> readPinHash() => _storage.read(key: _keyPinHash);

  Future<void> clearPin() async {
    await _storage.delete(key: _keyPinHash);
    await _storage.delete(key: _keyPinSalt);
  }

  Future<int> readFailedAttempts() async {
    final v = await _storage.read(key: _keyFailedAttempts);
    return int.tryParse(v ?? '0') ?? 0;
  }

  Future<void> saveFailedAttempts(int count) =>
      _storage.write(key: _keyFailedAttempts, value: count.toString());

  Future<DateTime?> readLockoutUntil() async {
    final v = await _storage.read(key: _keyLockoutUntil);
    if (v == null) return null;
    return DateTime.tryParse(v);
  }

  Future<void> saveLockoutUntil(DateTime? until) async {
    if (until == null) {
      await _storage.delete(key: _keyLockoutUntil);
    } else {
      await _storage.write(key: _keyLockoutUntil, value: until.toIso8601String());
    }
  }

  /// 完全初期化（データ初期化操作専用）。DB暗号化鍵も破棄するため、
  /// 呼び出し前にDBファイル自体の削除もセットで行うこと。
  Future<void> wipeAll() => _storage.deleteAll();
}
