import 'package:flutter/material.dart';

import '../../core/util/formatters.dart';
import '../../models/product.dart';
import '../../repositories/inventory_repository.dart';
import '../../repositories/product_repository.dart';
import 'product_edit_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Product> _products = [];
  Map<String, double> _stock = {};
  bool _showInactive = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final products = await ProductRepository.instance.listAll();
    final inventory = await InventoryRepository.instance.listAll();
    setState(() {
      _products = products;
      _stock = {for (final i in inventory) i.productId: i.quantity};
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible =
        _showInactive ? _products : _products.where((p) => p.isActive).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('商品'),
        actions: [
          IconButton(
            icon: Icon(_showInactive ? Icons.visibility : Icons.visibility_off),
            tooltip: _showInactive ? '販売停止商品も表示中' : '販売中のみ表示中',
            onPressed: () => setState(() => _showInactive = !_showInactive),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const ProductEditScreen()));
          _load();
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final p = visible[index];
                final stock = _stock[p.id] ?? 0;
                return ListTile(
                  title: Text(p.name, style: TextStyle(
                    decoration: p.isActive ? null : TextDecoration.lineThrough,
                  )),
                  subtitle: Text('×1 ${Formatters.yen(p.priceX1)} ・ 在庫 ${Formatters.quantity(stock)}${p.unitLabel}'),
                  trailing: p.isActive
                      ? (stock <= 0
                          ? const Chip(label: Text('在庫切れ'), backgroundColor: Colors.redAccent)
                          : (stock <= p.lowStockThreshold
                              ? const Chip(label: Text('残りわずか'), backgroundColor: Colors.amber)
                              : null))
                      : const Chip(label: Text('販売停止')),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ProductEditScreen(product: p)),
                    );
                    _load();
                  },
                );
              },
            ),
    );
  }
}
