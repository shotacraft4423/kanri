import 'package:flutter/material.dart';

import '../../core/db/app_database.dart';
import '../../core/util/formatters.dart';
import '../../models/audit_log.dart';
import '../../models/customer.dart';
import '../../models/order.dart';
import '../../models/order_item.dart';
import '../../models/product.dart';
import '../../models/purchase.dart';
import '../../models/purchase_item.dart';
import '../../repositories/customer_repository.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/purchase_repository.dart';
import '../../repositories/sales_repository.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('履歴'),
        bottom: TabBar(controller: _tabController, tabs: const [
          Tab(text: '販売履歴'),
          Tab(text: '仕入れ履歴'),
          Tab(text: '監査ログ'),
        ]),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_SalesHistoryTab(), _PurchaseHistoryTab(), _AuditLogTab()],
      ),
    );
  }
}

class _SalesHistoryTab extends StatelessWidget {
  const _SalesHistoryTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Order>>(
      future: SalesRepository.instance.listAll(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final orders = snapshot.data!;
        if (orders.isEmpty) return const Center(child: Text('販売履歴はありません'));
        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final o = orders[index];
            return FutureBuilder<List<OrderItem>>(
              future: SalesRepository.instance.itemsFor(o.id),
              builder: (context, itemSnapshot) {
                final items = itemSnapshot.data ?? [];
                final total = items.fold(0, (a, b) => a + b.lineTotal);
                final profit = items.fold(0, (a, b) => a + b.profit);
                return FutureBuilder<Customer?>(
                  future: CustomerRepository.instance.findById(o.customerId),
                  builder: (context, custSnapshot) => ListTile(
                    title: Text('${o.orderNumber} ${o.isCancelled ? "(キャンセル)" : ""}'),
                    subtitle: Text(
                        '${Formatters.date(o.orderDate)} ・ ${custSnapshot.data?.maskedName ?? ""}'),
                    trailing: Text('${Formatters.yen(total)}\n利益 ${Formatters.yen(profit)}',
                        textAlign: TextAlign.right),
                    isThreeLine: false,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _PurchaseHistoryTab extends StatelessWidget {
  const _PurchaseHistoryTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Purchase>>(
      future: PurchaseRepository.instance.listAll(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final purchases = snapshot.data!;
        if (purchases.isEmpty) return const Center(child: Text('仕入れ履歴はありません'));
        return ListView.builder(
          itemCount: purchases.length,
          itemBuilder: (context, index) {
            final p = purchases[index];
            return FutureBuilder<List<PurchaseItem>>(
              future: PurchaseRepository.instance.itemsFor(p.id),
              builder: (context, itemSnapshot) {
                final items = itemSnapshot.data ?? [];
                final total = items.fold(0, (a, b) => a + b.actualPaid);
                return ExpansionTile(
                  title: Text('${Formatters.date(p.purchaseDate)} ・ ${p.status.label}'),
                  subtitle: Text('合計 ${Formatters.yen(total)} ・ 追跡番号: ${p.trackingNumber ?? "-"}'),
                  children: [
                    for (final item in items)
                      FutureBuilder<Product?>(
                        future: ProductRepository.instance.findById(item.productId),
                        builder: (context, prodSnapshot) => ListTile(
                          dense: true,
                          title: Text(prodSnapshot.data?.name ?? item.productId),
                          subtitle: Text(
                              '数量 ${Formatters.quantity(item.quantity)} ・ 商品代 ${Formatters.yen(item.itemCost)} ・ '
                              '送料 ${Formatters.yen(item.shippingCost)} ・ 手数料 ${Formatters.yen(item.fee)}\n'
                              '実支払額 ${Formatters.yen(item.actualPaid)} ・ 入荷: ${item.isReceived ? Formatters.date(p.arrivalDate) : "未入荷"}'),
                          isThreeLine: true,
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _AuditLogTab extends StatelessWidget {
  const _AuditLogTab();

  Future<List<AuditLog>> _load() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('audit_logs', orderBy: 'created_at DESC', limit: 200);
    return rows.map(AuditLog.fromMap).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AuditLog>>(
      future: _load(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final logs = snapshot.data!;
        if (logs.isEmpty) return const Center(child: Text('監査ログはありません'));
        return ListView.builder(
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final l = logs[index];
            return ListTile(
              dense: true,
              title: Text('${l.entityType} / ${l.action}'),
              subtitle: Text(Formatters.dateTime(l.createdAt)),
            );
          },
        );
      },
    );
  }
}
