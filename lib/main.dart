import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'core/db/app_database.dart';
import 'core/security/lock_gate.dart';
import 'core/seed/initial_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 暗号化DBを開いた上で、初回起動時のみサンプル商品を投入する。
  await AppDatabase.instance.database;
  await InitialDataSeeder.seedIfEmpty();
  runApp(const KanriApp());
}

class KanriApp extends StatelessWidget {
  const KanriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LockGate(
      child: MaterialApp(
        title: 'kanri',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
        ),
        home: const AppShell(),
      ),
    );
  }
}
