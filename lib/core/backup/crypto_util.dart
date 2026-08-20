import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// パスワードベースの共通鍵暗号ユーティリティ。
/// PBKDF2(HMAC-SHA256)で鍵を導出し、AES-256-GCMで暗号化する。
/// 開発者側が復号できる仕組みは存在しない（パスワードはユーザーのみが知る）。
class CryptoUtil {
  const CryptoUtil._();

  static const _pbkdf2Iterations = 150000;
  static const _keyBits = 256;

  static List<int> randomBytes(int length) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }

  static Future<SecretKey> _deriveKey(String password, List<int> salt) async {
    final algorithm = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _pbkdf2Iterations,
      bits: _keyBits,
    );
    return algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
  }

  /// 平文JSON文字列を暗号化し、単一ファイルに書き出せる形式（Base64テキスト）で返す。
  static Future<String> encryptToPortableString(String plainText, String password) async {
    final salt = randomBytes(16);
    final nonce = randomBytes(12);
    final secretKey = await _deriveKey(password, salt);
    final algorithm = AesGcm.with256bits();

    final secretBox = await algorithm.encrypt(
      utf8.encode(plainText),
      secretKey: secretKey,
      nonce: nonce,
    );

    final envelope = {
      'format': 'kanri-backup-v1',
      'salt': base64Encode(salt),
      'nonce': base64Encode(nonce),
      'cipherText': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    };
    return jsonEncode(envelope);
  }

  static Future<String> decryptFromPortableString(String envelopeJson, String password) async {
    final envelope = jsonDecode(envelopeJson) as Map<String, dynamic>;
    if (envelope['format'] != 'kanri-backup-v1') {
      throw const FormatException('未対応のバックアップ形式です');
    }
    final salt = base64Decode(envelope['salt'] as String);
    final nonce = base64Decode(envelope['nonce'] as String);
    final cipherText = base64Decode(envelope['cipherText'] as String);
    final mac = base64Decode(envelope['mac'] as String);

    final secretKey = await _deriveKey(password, salt);
    final algorithm = AesGcm.with256bits();
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(mac));

    try {
      final plainBytes = await algorithm.decrypt(secretBox, secretKey: secretKey);
      return utf8.decode(plainBytes);
    } on SecretBoxAuthenticationError {
      throw const FormatException('パスワードが違うか、ファイルが破損しています');
    }
  }
}
