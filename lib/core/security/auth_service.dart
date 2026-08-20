import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

import 'pin_hasher.dart';
import 'secure_storage_service.dart';

enum AuthMethod { biometric, pin, none }

enum PinSetResult { ok, tooShort, mismatch }

enum PinVerifyResult { ok, wrong, lockedOut }

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final LocalAuthentication _localAuth = LocalAuthentication();

  static const int _minPinLength = 4;
  static const int _maxFailedAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 5);

  Future<bool> isBiometricAvailable() async {
    // Web版（動作確認用ビルド）は生体認証プラットフォーム実装が無いため、
    // 常にPINでのロック解除にフォールバックする。
    if (kIsWeb) return false;
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!supported || !canCheck) return false;
      final available = await _localAuth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'アプリのロックを解除します',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasPinConfigured() => SecureStorageService.instance.hasPin();

  Future<PinSetResult> setPin(String pin, String confirmPin) async {
    if (pin.length < _minPinLength) return PinSetResult.tooShort;
    if (pin != confirmPin) return PinSetResult.mismatch;
    final salt = await SecureStorageService.instance.savePinSalt();
    final hash = await PinHasher.hash(pin, salt);
    await SecureStorageService.instance.savePinHash(hash);
    await SecureStorageService.instance.saveFailedAttempts(0);
    await SecureStorageService.instance.saveLockoutUntil(null);
    return PinSetResult.ok;
  }

  Future<Duration?> currentLockoutRemaining() async {
    final until = await SecureStorageService.instance.readLockoutUntil();
    if (until == null) return null;
    final remaining = until.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  Future<PinVerifyResult> verifyPin(String pin) async {
    final lockout = await currentLockoutRemaining();
    if (lockout != null) return PinVerifyResult.lockedOut;

    final salt = await SecureStorageService.instance.readPinSalt();
    final hash = await SecureStorageService.instance.readPinHash();
    if (salt == null || hash == null) return PinVerifyResult.wrong;

    final ok = await PinHasher.verify(pin, salt, hash);
    if (ok) {
      await SecureStorageService.instance.saveFailedAttempts(0);
      await SecureStorageService.instance.saveLockoutUntil(null);
      return PinVerifyResult.ok;
    }

    final attempts = await SecureStorageService.instance.readFailedAttempts() + 1;
    await SecureStorageService.instance.saveFailedAttempts(attempts);
    if (attempts >= _maxFailedAttempts) {
      await SecureStorageService.instance
          .saveLockoutUntil(DateTime.now().add(_lockoutDuration));
      await SecureStorageService.instance.saveFailedAttempts(0);
      return PinVerifyResult.lockedOut;
    }
    return PinVerifyResult.wrong;
  }

  /// 「PINを忘れた場合の簡易再発行」は意図的に実装しない。
  /// 復旧経路は、ユーザー自身が保管する暗号化バックアップからの
  /// アプリ再インストール＋復元のみとする（要件51-11, 41）。
}
