import 'package:flutter/foundation.dart';
import 'package:screen_protector/screen_protector.dart';

/// アプリ切替画面(タスクスイッチャー)のサムネイルやスクリーンショットへの
/// 機密情報露出を軽減する。iOSはOS仕様上スクリーンショット自体は禁止できないため、
/// 「バックグラウンド遷移時にプライバシースクリーンを重ねる」対応に留まる（docs/DESIGN.md参照）。
class ScreenProtectionService {
  ScreenProtectionService._();
  static final ScreenProtectionService instance = ScreenProtectionService._();

  bool _enabled = false;

  Future<void> enable() async {
    if (_enabled) return;
    // Web版（動作確認用ビルド）はブラウザの仕様上、アプリ切替画面保護に相当する機能がないため何もしない。
    if (kIsWeb) return;
    try {
      await ScreenProtector.preventScreenshotOn();
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await ScreenProtector.protectDataLeakageWithBlur();
      }
      _enabled = true;
    } catch (_) {
      // 一部端末/OSバージョンで非対応の場合は無視し、アプリロックによる保護を主とする。
    }
  }

  Future<void> disableScreenshotBlockOnly() async {
    try {
      await ScreenProtector.preventScreenshotOff();
    } catch (_) {}
  }
}
