import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// PINをPBKDF2(HMAC-SHA256)でハッシュ化する。平文PINは一切保存しない。
class PinHasher {
  static const _iterations = 120000;
  static const _bits = 256;

  static Future<String> hash(String pin, String saltBase64) async {
    final algorithm = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _iterations,
      bits: _bits,
    );
    final salt = base64Url.decode(saltBase64);
    final secretKey = await algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: salt,
    );
    final bytes = await secretKey.extractBytes();
    return base64Url.encode(bytes);
  }

  static Future<bool> verify(String pin, String saltBase64, String expectedHash) async {
    final actual = await hash(pin, saltBase64);
    return _constantTimeEquals(actual, expectedHash);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
