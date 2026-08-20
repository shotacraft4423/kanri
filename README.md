# kanri

個人事業・小規模販売向けの商品・仕入れ・在庫・売上・発送・顧客管理アプリ。
Android / iOS で動くスタンドアロン（サーバー不要）アプリを Flutter で実装しています。

詳しい設計・セキュリティ方針は [`docs/DESIGN.md`](docs/DESIGN.md)、
ビルド手順は [`docs/SETUP.md`](docs/SETUP.md) を参照してください。

## Web版（動作確認用）について

ブラウザで開ける動作確認用ビルドを用意しています。詳細は配布時の案内を参照してください。
Web版はブラウザの制約上、以下がAndroid/iOSアプリ本体と異なります。

- データはブラウザ内（IndexedDB）にのみ保存され、他の端末・PCとは同期されません
- SQLCipherによるDB暗号化は行われません（Web標準にファイル暗号化の仕組みがないため）
- 生体認証は利用できず、PINロックのみ利用できます
- アプリ切替時の画面保護（スクリーンショット防止等）は動作しません

**実際の顧客情報など機密データの入力は避け、動作確認・操作感の確認用としてご利用ください。**

## 開発

```bash
flutter pub get
flutter run                # モバイル実機/エミュレータ
flutter run -d chrome       # ブラウザでの動作確認
flutter build web --release --no-wasm-dry-run
flutter build apk --debug   # Android実機用APK
```
