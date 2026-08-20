# セットアップ手順

`lib/`（アプリ本体）、`android/`、`web/` はこのリポジトリに含まれており、
生成・パッチ適用済みです。`ios/` もXcodeプロジェクトの雛形は含まれていますが、
実機用IPAのビルド・署名にはmacOS(Xcode)が必要です（後述）。

## CI（GitHub Actions）

`.github/workflows/build.yml` が push のたびに以下を自動実行します。

- **build-web**: Web版をビルドし `gh-pages` ブランチへ公開
  （`https://<owner>.github.io/<repo>/` で閲覧可能。要 Settings > Pages で
  Source を `gh-pages` ブランチに設定）
- **build-android**: デバッグ用APKをビルドし、Actionsのワークフロー実行結果に
  アーティファクトとして添付（Actions > 対象の実行 > Artifacts からダウンロード）
- **build-ios-verify**: macOSランナーで署名なしビルドが通ることだけを確認
  （実機にインストールできるIPAではありません。下記「iOS実機で使うには」参照）

手動実行する場合は GitHub の Actions タブから `workflow_dispatch` で起動できます。

## ローカルでビルドする場合

```bash
flutter pub get
flutter run                                          # 実機/エミュレータ
flutter run -d chrome                                 # ブラウザで確認
flutter build apk --debug                             # Android デバッグAPK
flutter build apk --release                           # Android リリースAPK（要署名設定）
flutter build web --release --no-wasm-dry-run \
  --base-href "/kanri/"                                # Web（GitHub Pagesのサブパスに合わせる）
```

Web版は `sqflite_common_ffi_web` を使うため、初回のみ以下を実行してWasmバイナリを
`web/` 配下に配置してください（このリポジトリには既に含まれています）。

```bash
dart run sqflite_common_ffi_web:setup
```

## Android 実機で使うには

CIが生成する `app-debug.apk`（署名は自動生成されるデバッグ鍵）をダウンロードし、
Android端末で「提供元不明のアプリ」を許可した上でインストールしてください。
ストアを経由しないため、この方法が最も手早く実機確認できます。

## iOS 実機で使うには

iOSは仕組み上、macOS + Xcode でのビルド・署名なしには実機にインストールできません
（このサンドボックス環境はLinuxのため、署名済みIPAはここでは作れません）。

1. Macで `git clone` し、Xcodeで `ios/Runner.xcworkspace` を開く
2. Xcode の Signing & Capabilities で自分のApple ID（無料でも可）をチームに設定
3. 実機を接続して Run、または `flutter build ipa` でIPAを書き出す

無料のApple ID（Personal Team）で署名した場合、アプリは **7日で期限切れ**になり、
再度Xcodeでの再署名が必要です。友人にも継続的に配布したい場合は、
Apple Developer Program（年額有料）に登録し、TestFlightで配布するのが実用的です。

それまでの間は、Web版（`https://<owner>.github.io/<repo>/`）であればiPhoneでも
インストール不要でそのまま試せます。

## セキュリティ機能の対応状況

| 機能 | Android/iOSネイティブ | Web版 |
|---|---|---|
| DB暗号化(SQLCipher) | ○ | × (ブラウザ内IndexedDBに平文保存) |
| 生体認証 | ○ | × (PINのみ) |
| アプリ切替時の画面保護 | ○ | × |
| PINロック | ○ | ○ |

Web版はあくまで動作確認・操作感の確認用です。詳細は `docs/DESIGN.md` を参照してください。
