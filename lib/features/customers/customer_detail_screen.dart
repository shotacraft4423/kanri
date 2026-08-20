import 'package:flutter/material.dart';

import '../../core/util/formatters.dart';
import '../../models/customer.dart';
import '../../models/order.dart';
import '../../repositories/customer_repository.dart';
import '../../repositories/sales_repository.dart';
import 'customer_edit_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  Customer? _customer;
  List<Order> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final customer = await CustomerRepository.instance.findById(widget.customerId);
    final allOrders = await SalesRepository.instance.listAll();
    setState(() {
      _customer = customer;
      _orders = allOrders.where((o) => o.customerId == widget.customerId).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _customer == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final c = _customer!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('顧客詳細'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => CustomerEditScreen(customer: c)));
              _load();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(contentPadding: EdgeInsets.zero, title: const Text('氏名'), subtitle: Text(c.name)),
          ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('郵便番号'),
              subtitle: Text(c.postalCode ?? '-')),
          ListTile(contentPadding: EdgeInsets.zero, title: const Text('住所'), subtitle: Text(c.address ?? '-')),
          ListTile(contentPadding: EdgeInsets.zero, title: const Text('電話番号'), subtitle: Text(c.phone ?? '-')),
          if (c.memo != null)
            ListTile(contentPadding: EdgeInsets.zero, title: const Text('メモ'), subtitle: Text(c.memo!)),
          const Divider(),
          Text('購入履歴', style: Theme.of(context).textTheme.titleSmall),
          for (final o in _orders)
            ListTile(
              title: Text(o.orderNumber),
              subtitle: Text(Formatters.date(o.orderDate)),
              trailing: o.isCancelled ? const Chip(label: Text('キャンセル')) : null,
            ),
          if (_orders.isEmpty) const Text('購入履歴はありません'),
        ],
      ),
    );
  }
}
