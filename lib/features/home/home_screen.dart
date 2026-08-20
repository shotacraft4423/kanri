import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/util/formatters.dart';
import '../../repositories/dashboard_repository.dart';
import '../../repositories/purchase_repository.dart';
import '../../repositories/sales_repository.dart';
import '../customers/customer_list_screen.dart';
import '../history/history_screen.dart';
import '../logistics/logistics_screen.dart';
import '../products/product_list_screen.dart';
import '../purchases/purchase_list_screen.dart';
import '../settings/settings_screen.dart';
import '../shipping/shipment_list_screen.dart';
import '../stats/stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<DashboardSummary> _future;

  @override
  void initState() {
    super.initState();
    _future = DashboardRepository.instance.load();
  }

  Future<void> _reload() async {
    setState(() {
      _future = DashboardRepository.instance.load();
    });
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            _menuTile(context, Icons.inventory_2, '商品', const ProductListScreen()),
            _menuTile(context, Icons.people, '顧客', const CustomerListScreen()),
            _menuTile(context, Icons.history, '履歴', const HistoryScreen()),
            _menuTile(context, Icons.bar_chart, '集計', const StatsScreen()),
            _menuTile(context, Icons.dashboard_customize, '物流センター', const LogisticsScreen()),
            _menuTile(context, Icons.settings, '設定', const SettingsScreen()),
          ],
        ),
      ),
    );
  }

  Widget _menuTile(BuildContext context, IconData icon, String label, Widget screen) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'すべてのメニュー',
            onPressed: () => _showMenu(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<DashboardSummary>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final s = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (kIsWeb) const _WebDemoNotice(),
                if (kIsWeb) const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _StatCard(label: '本日の売上', value: Formatters.yen(s.todaySalesTotal))),
                    const SizedBox(width: 8),
                    Expanded(child: _StatCard(label: '今月の売上', value: Formatters.yen(s.monthSalesTotal))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _StatCard(label: '今月の利益', value: Formatters.yen(s.monthProfitTotal))),
                    const SizedBox(width: 8),
                    Expanded(child: _StatCard(label: '今月の販売件数', value: '${s.monthOrderCount}件')),
                  ],
                ),
                const SizedBox(height: 16),
                Text('対応が必要な項目', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.local_shipping,
                  color: Colors.orange,
                  title: '発送待ち',
                  count: s.unshippedCount,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ShipmentListScreen(initialTab: 0)),
                  ),
                ),
                _ActionTile(
                  icon: Icons.inventory_2,
                  color: Colors.blue,
                  title: '仕入れ待ち（未到着）',
                  count: s.purchaseAwaitingArrivalCount,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PurchaseListScreen()),
                  ),
                ),
                _ActionTile(
                  icon: Icons.move_to_inbox,
                  color: Colors.teal,
                  title: '入荷処理待ち',
                  count: s.purchaseAwaitingReceivingCount,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PurchaseListScreen()),
                  ),
                ),
                _ActionTile(
                  icon: Icons.warning_amber,
                  color: Colors.red,
                  title: '在庫切れ',
                  count: s.outOfStockCount,
                  onTap: null,
                ),
                _ActionTile(
                  icon: Icons.production_quantity_limits,
                  color: Colors.amber,
                  title: '在庫少',
                  count: s.lowStockCount,
                  onTap: null,
                ),
                const SizedBox(height: 16),
                Text('現在の在庫評価額: ${Formatters.yen(s.inventoryValueTotal)}',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                Text('最近の状況', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _RecentPurchases(),
                const SizedBox(height: 8),
                _RecentSales(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WebDemoNotice extends StatelessWidget {
  const _WebDemoNotice();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.amber.withOpacity(0.15),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: Colors.amber),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'これは動作確認用のWeb版です。データはこの端末のブラウザ内にのみ保存され、'
                'DB暗号化や生体認証などのセキュリティ機能は動作しません（PINロックのみ利用可）。'
                '実際の顧客情報の登録は避けてください。',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final int count;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: count > 0 ? color.withOpacity(0.08) : null,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: Text('$count件', style: Theme.of(context).textTheme.titleMedium),
        onTap: onTap,
      ),
    );
  }
}

class _RecentPurchases extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: PurchaseRepository.instance.listAll(),
      builder: (context, snapshot) {
        final items = (snapshot.data ?? []).take(3).toList();
        if (items.isEmpty) return const SizedBox.shrink();
        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text('最近の仕入れ', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              for (final p in items)
                ListTile(
                  dense: true,
                  title: Text(Formatters.date(p.purchaseDate)),
                  trailing: Text(p.status.label),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RecentSales extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: SalesRepository.instance.listAll(),
      builder: (context, snapshot) {
        final items = (snapshot.data ?? []).take(3).toList();
        if (items.isEmpty) return const SizedBox.shrink();
        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text('最近の販売', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              for (final o in items)
                ListTile(
                  dense: true,
                  title: Text(o.orderNumber),
                  subtitle: Text(Formatters.date(o.orderDate)),
                  trailing: o.isCancelled ? const Text('キャンセル') : null,
                ),
            ],
          ),
        );
      },
    );
  }
}
