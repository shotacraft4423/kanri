# セットアップ手順

この環境にはFlutter SDKが無いため、`lib/`以下のソースコードと`pubspec.yaml`のみを用意しています。
実機/エミュレータで動かすには、Flutter SDKがインストールされた環境で以下を行ってください。

## 1. プラットフォームプロジェクトの生成

このリポジトリのルートで、`lib/` と `pubspec.yaml` を残したまま:

```bash
flutter create --org com.yourcompany --project-name kanri .
flutter pub get
```

`android/` `ios/` が生成されます（既存の `lib/main.dart` 等は上書きしないよう、
生成後に不要な `lib/main.dart` の重複のみ確認してください）。

## 2. Android 設定

`android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
```

`android/app/src/main/kotlin/.../MainActivity.kt` の `onCreate` で
スクリーンショット/画面録画防止（アプリ切替サムネイル対策）:

```kotlin
override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    window.setFlags(
        WindowManager.LayoutParams.FLAG_SECURE,
        WindowManager.LayoutParams.FLAG_SECURE
    )
}
```

（`screen_protector` パッケージを使う場合はDart側からも制御可能。上記はネイティブ側の保険。）

`minSdkVersion` は生体認証(BiometricPrompt)のため 23 以上を指定してください。

## 3. iOS 設定

`ios/Runner/Info.plist` に Face ID 用途説明を追加:

```xml
<key>NSFaceIDUsageDescription</key>
<string>アプリのロック解除に生体認証を使用します</string>
```

iOSはOS仕様上スクリーンショット自体は禁止できません。バックグラウンド遷移時に
プライバシースクリーン（ぼかしオーバーレイ）を表示する処理は
`lib/core/security/screen_protection.dart` 側のライフサイクルフックで行っています。

## 4. ビルド確認

```bash
flutter analyze
flutter test
flutter run
```

## 5. 依存パッケージについて

`sqflite_sqlcipher` はネイティブのSQLCipherライブラリを内包しビルドします。
Android/iOSともに追加のライブラリインストールは不要ですが、iOSは初回 `pod install` に時間がかかります。
