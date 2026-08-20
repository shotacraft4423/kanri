import 'package:flutter/material.dart';

import '../../models/customer.dart';
import '../../repositories/customer_repository.dart';
import 'customer_detail_screen.dart';
import 'customer_edit_screen.dart';

/// 顧客一覧。氏名はマスキング表示とし、住所・電話番号は表示しない（要件12, 42）。
/// 詳細を見る場合のみ customer_detail_screen で全項目を表示する。
class CustomerListScreen extends StatefulWidget {
  final bool selectMode;
  const CustomerListScreen({super.key, this.selectMode = false});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  List<Customer> _customers = [];
  bool _loading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final customers = _searchController.text.trim().isEmpty
        ? await CustomerRepository.instance.listAll()
        : await CustomerRepository.instance.search(_searchController.text.trim());
    setState(() {
      _customers = customers;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.selectMode ? '顧客を選択' : '顧客')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.of(context)
              .push<Customer>(MaterialPageRoute(builder: (_) => const CustomerEditScreen()));
          if (created != null && widget.selectMode && mounted) {
            Navigator.of(context).pop(created);
            return;
          }
          _load();
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: '顧客名で検索',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _load(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _customers.length,
                    itemBuilder: (context, index) {
                      final c = _customers[index];
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(c.maskedName),
                        onTap: () async {
                          if (widget.selectMode) {
                            Navigator.of(context).pop(c);
                            return;
                          }
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => CustomerDetailScreen(customerId: c.id)),
                          );
                          _load();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
