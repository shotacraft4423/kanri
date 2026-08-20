import 'package:flutter/material.dart';

import '../../models/app_settings.dart';
import '../../repositories/settings_repository.dart';
import 'backup_screen.dart';
import 'data_reset_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, String> _settings = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all = await SettingsRepository.instance.getAll();
    setState(() {
      _settings = all;
      _loading = false;
    });
  }

  Future<void> _setBool(String key, bool value) async {
    await SettingsRepository.instance.setBool(key, value);
    _load();
  }

  Future<void> _setInt(String key, int value) async {
    await SettingsRepository.instance.setInt(key, value);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final lockOnLaunch = _settings[AppSettingsKeys.lockOnLaunch] == 'true';
    final lockOnBackground = _settings[AppSettingsKeys.lockOnBackground] == 'true';
    final autoLockSeconds = int.tryParse(_settings[AppSettingsKeys.autoLockSeconds] ?? '30') ?? 30;
    final notificationsEnabled = _settings[AppSettingsKeys.notificationsEnabled] == 'true';

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          const _SectionHeader('セキュリティ'),
          SwitchListTile(
            title: const Text('起動時に認証を要求'),
            value: lockOnLaunch,
            onChanged: (v) => _setBool(AppSettingsKeys.lockOnLaunch, v),
          ),
          SwitchListTile(
            title: const Text('バックグラウンド復帰時に再認証'),
            subtitle: const Text('OFFの場合は無操作タイムアウトのみでロックします'),
            value: lockOnBackground,
            onChanged: (v) => _setBool(AppSettingsKeys.lockOnBackground, v),
          ),
          ListTile(
            title: const Text('自動ロックまでの時間（無操作）'),
            subtitle: Text('$autoLockSeconds秒'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final selected = await showDialog<int>(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text('自動ロック時間を選択'),
                  children: [15, 30, 60, 180, 300]
                      .map((s) => SimpleDialogOption(
                            onPressed: () => Navigator.pop(context, s),
                            child: Text('$s秒'),
                          ))
                      .toList(),
                ),
              );
              if (selected != null) _setInt(AppSettingsKeys.autoLockSeconds, selected);
            },
          ),
          const _SectionHeader('通知'),
          SwitchListTile(
            title: const Text('通知・アラートを有効にする'),
            value: notificationsEnabled,
            onChanged: (v) => _setBool(AppSettingsKeys.notificationsEnabled, v),
          ),
          const _SectionHeader('データ管理'),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('バックアップ / エクスポート / インポート'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BackupScreen()),
            ),
          ),
          const _SectionHeader('危険な操作'),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('アプリデータの初期化', style: TextStyle(color: Colors.red)),
            subtitle: const Text('全データを消去します。事前にバックアップを推奨します'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DataResetScreen()),
            ),
          ),
        ],
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
