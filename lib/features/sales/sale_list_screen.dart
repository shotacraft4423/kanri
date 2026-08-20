import 'package:flutter/material.dart';

import '../../core/util/formatters.dart';
import '../../models/customer.dart';
import '../../models/order.dart';
import '../../models/order_item.dart';
import '../../models/product.dart';
import '../../repositories/customer_repository.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/sales_repository.dart';
import 'sale_new_screen.dart';

class SaleListScreen extends StatefulWidget {
  const SaleListScreen({super.key});

  @override
  State<SaleListScreen> createState() => _SaleListScreenState();
}

class _SaleListScreenState extends State<SaleListScreen> {
  List<Order> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final orders = await SalesRepository.instance.listAll();
    setState(() {
      _orders = orders;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('販売')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SaleNewScreen()));
          _load();
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final o = _orders[index];
                return ListTile(
                  title: Text(o.orderNumber),
                  subtitle: Text(Formatters.date(o.orderDate)),
                  trailing: o.isCancelled ? const Chip(label: Text('キャンセル')) : null,
                  onTap: () => _showOrderDetail(o),
                );
              },
            ),
    );
  }

  Future<void> _showOrderDetail(Order order) async {
    final items = await SalesRepository.instance.itemsFor(order.id);
    final customer = await CustomerRepository.instance.findById(order.customerId);
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _OrderDetailSheet(order: order, items: items, customer: customer, onChanged: _load),
    );
  }
}

class _OrderDetailSheet extends StatelessWidget {
  final Order order;
  final List<OrderItem> items;
  final Customer? customer;
  final VoidCallback onChanged;

  const _OrderDetailSheet({
    required this.order,
    required this.items,
    required this.customer,
    required this.onChanged,
  });

  Future<void> _cancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('販売キャンセルの確認'),
        content: const Text('この販売をキャンセルします。在庫は元に戻ります。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('戻る')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('キャンセルする')),
        ],
      ),
    );
    if (confirmed == true) {
      await SalesRepository.instance.cancelOrder(order.id);
      onChanged();
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalProfit = items.fold(0, (a, b) => a + b.profit);
    final totalAmount = items.fold(0, (a, b) => a + b.lineTotal);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(order.orderNumber, style: Theme.of(context).textTheme.titleLarge),
          Text('顧客: ${customer?.maskedName ?? '-'}'),
          Text('販売日: ${Formatters.date(order.orderDate)}'),
          const Divider(),
          for (final item in items)
            FutureBuilder<Product?>(
              future: ProductRepository.instance.findById(item.productId),
              builder: (context, snapshot) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(snapshot.data?.name ?? item.productId),
                subtitle: Text('数量 ${Formatters.quantity(item.quantity)}'),
                trailing: Text(Formatters.yen(item.lineTotal)),
              ),
            ),
          const Divider(),
          Text('合計金額: ${Formatters.yen(totalAmount)}'),
          Text('利益: ${Formatters.yen(totalProfit)}'),
          const SizedBox(height: 12),
          if (!order.isCancelled)
            OutlinedButton(onPressed: () => _cancel(context), child: const Text('この販売をキャンセル')),
        ],
      ),
    );
  }
}
