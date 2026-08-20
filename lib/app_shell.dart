import 'package:flutter/material.dart';

import 'features/home/home_screen.dart';
import 'features/inventory/inventory_list_screen.dart';
import 'features/purchases/purchase_list_screen.dart';
import 'features/sales/sale_list_screen.dart';
import 'features/shipping/shipment_list_screen.dart';

/// 片手操作を意識し、頻繁に使う「仕入れ」「発送」をボトムナビに配置する（要件32）。
/// それ以外の商品/顧客/履歴/集計/物流センター/設定はホーム画面右上の全メニューから開く。
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _tabs = [
    HomeScreen(),
    PurchaseListScreen(),
    ShipmentListScreen(),
    InventoryListScreen(),
    SaleListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'ホーム'),
          NavigationDestination(icon: Icon(Icons.local_shipping), label: '仕入れ'),
          NavigationDestination(icon: Icon(Icons.outbox), label: '発送'),
          NavigationDestination(icon: Icon(Icons.warehouse), label: '在庫'),
          NavigationDestination(icon: Icon(Icons.point_of_sale), label: '販売'),
        ],
      ),
    );
  }
}
