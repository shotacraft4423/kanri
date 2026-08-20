/// アプリ切替画面(タスクスイッチャー)のサムネイルやスクリーンショットへの
/// 機密情報露出を軽減する処理は、プラットフォームのネイティブコード側で
/// 常時有効な形で実装している（Dart側での実行時トグルは不要）。
///
/// - Android: android/app/src/main/kotlin/.../MainActivity.kt の onCreate で
///   FLAG_SECURE を設定し、スクリーンショット・画面録画・タスクスイッチャーの
///   サムネイル表示をOS側で完全にブロックする。
/// - iOS: ios/Runner/AppDelegate.swift でバックグラウンド遷移時に
///   プライバシースクリーン（ぼかしオーバーレイ）を重ねる。
///   iOSはOS仕様上スクリーンショット自体は禁止できないため、
///   タスクスイッチャーでの一瞬の見え方を軽減する対応に留まる（docs/DESIGN.md参照）。
///
/// 以前はサードパーティの `screen_protector` パッケージを使っていたが、
/// 現行のAndroid Gradle Plugin/Kotlinツールチェーンと非互換でビルドが
/// 失敗するようになったため、ネイティブコードへの直接実装に切り替えた。
class ScreenProtectionService {
  ScreenProtectionService._();
  static final ScreenProtectionService instance = ScreenProtectionService._();

  Future<void> enable() async {
    // ネイティブ側で常時有効なため、Dart側では何もしない。
  }
}
