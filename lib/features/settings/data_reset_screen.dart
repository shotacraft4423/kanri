import 'package:flutter/material.dart';

import '../../core/db/app_database.dart';
import '../../core/security/secure_storage_service.dart';

/// データ完全初期化。誤操作防止のため、確認文言の入力を要求してから実行する（要件40）。
class DataResetScreen extends StatefulWidget {
  const DataResetScreen({super.key});

  @override
  State<DataResetScreen> createState() => _DataResetScreenState();
}

class _DataResetScreenState extends State<DataResetScreen> {
  static const _confirmPhrase = '初期化する';
  final _controller = TextEditingController();
  bool _resetting = false;

  Future<void> _reset() async {
    setState(() => _resetting = true);
    try {
      await AppDatabase.instance.deleteDatabaseFile();
      await SecureStorageService.instance.wipeAll();
    } finally {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canReset = _controller.text == _confirmPhrase;
    return Scaffold(
      appBar: AppBar(title: const Text('アプリデータの初期化')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '商品・仕入れ・在庫・販売・顧客・発送などすべてのデータと、'
              'アプリ専用PIN・暗号化鍵を完全に削除します。この操作は取り消せません。\n\n'
              '事前に「設定 > バックアップ」から暗号化バックアップを書き出すことを強く推奨します。',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 24),
            Text('続行するには「$_confirmPhrase」と入力してください'),
            TextField(controller: _controller, onChanged: (_) => setState(() {})),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: (canReset && !_resetting) ? _reset : null,
              child: Text(_resetting ? '初期化中...' : 'すべてのデータを削除する'),
            ),
          ],
        ),
      ),
    );
  }
}
