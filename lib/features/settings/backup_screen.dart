import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/backup/backup_service.dart';
import '../../core/backup/csv_export_service.dart';
import '../../core/backup/import_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askPassword({required String title, bool confirm = false}) async {
    final controller = TextEditingController();
    final confirmController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'パスワード'),
            ),
            if (confirm)
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'パスワード（確認）'),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          FilledButton(
            onPressed: () {
              if (confirm && controller.text != confirmController.text) return;
              if (controller.text.length < 8) return;
              Navigator.pop(context, controller.text);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportEncryptedBackup() async {
    final password = await _askPassword(title: 'バックアップの暗号化パスワードを設定（8文字以上）', confirm: true);
    if (password == null) return;
    await _run(() async {
      final xfile = await BackupService.instance.exportEncryptedBackup(password: password);
      await SharePlus.instance.share(ShareParams(files: [xfile], text: 'kanri 暗号化バックアップ'));
    });
  }

  Future<void> _importBackup() async {
    final result = await FilePicker.pickFiles(type: FileType.any);
    if (result.isEmpty) return;
    final bytes = await result.first.readAsBytes();
    final password = await _askPassword(title: 'バックアップのパスワードを入力');
    if (password == null) return;

    await _run(() async {
      final envelope = await BackupService.instance.decryptBackupData(bytes: bytes, password: password);
      final data = (envelope['data'] as Map).cast<String, dynamic>();
      final preview = await ImportService.instance.preview(data);
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('インポート内容の確認'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('新規追加: ${preview.totalNew}件'),
                Text('更新: ${preview.totalUpdate}件'),
                Text('競合（スキップ）: ${preview.totalConflict}件'),
                const Divider(),
                for (final diff in preview.perTable)
                  if (diff.newCount + diff.updateCount + diff.conflictCount > 0)
                    Text('${diff.table}: 新規${diff.newCount} / 更新${diff.updateCount} / 競合${diff.conflictCount}'),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('インポートを実行')),
          ],
        ),
      );
      if (confirmed == true) {
        await ImportService.instance.apply(preview);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('インポートが完了しました')));
        }
      }
    });
  }

  Future<void> _exportCsv(Future<XFile> Function() exporter) async {
    await _run(() async {
      final xfile = await exporter();
      await SharePlus.instance.share(ShareParams(files: [xfile]));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('バックアップ / エクスポート / インポート')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          children: [
            const _SectionHeader('暗号化フルバックアップ'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('顧客情報を含む全データをパスワード暗号化した単一ファイルに書き出します。'
                  'パスワードを忘れた場合、復元できなくなります。'),
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('暗号化バックアップを書き出す'),
              onTap: _exportEncryptedBackup,
            ),
            ListTile(
              leading: const Icon(Icons.unarchive),
              title: const Text('バックアップから復元（インポート）'),
              onTap: _importBackup,
            ),
            const _SectionHeader('CSVエクスポート（汎用・個人情報は含みません）'),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('商品マスタ'),
              onTap: () => _exportCsv(CsvExportService.instance.exportProducts),
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping),
              title: const Text('仕入れ履歴'),
              onTap: () => _exportCsv(CsvExportService.instance.exportPurchases),
            ),
            ListTile(
              leading: const Icon(Icons.point_of_sale),
              title: const Text('売上履歴'),
              onTap: () => _exportCsv(CsvExportService.instance.exportSales),
            ),
            ListTile(
              leading: const Icon(Icons.warehouse),
              title: const Text('在庫情報'),
              onTap: () => _exportCsv(CsvExportService.instance.exportInventory),
            ),
            ListTile(
              leading: const Icon(Icons.outbox),
              title: const Text('発送履歴'),
              onTap: () => _exportCsv(CsvExportService.instance.exportShipments),
            ),
            if (_busy) const Padding(padding: EdgeInsets.all(24), child: LinearProgressIndicator()),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey)),
    );
  }
}
