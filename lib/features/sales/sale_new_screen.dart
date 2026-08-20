import 'package:flutter/material.dart';

import '../../core/pricing/price_tier.dart';
import '../../core/util/formatters.dart';
import '../../models/customer.dart';
import '../../models/enums.dart';
import '../../models/inventory.dart';
import '../../models/product.dart';
import '../../repositories/inventory_repository.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/sales_repository.dart';
import '../customers/customer_list_screen.dart';

class _SaleLineForm {
  Product? product;
  PriceTier tier = PriceTier.x1;
  final customQty = TextEditingController();
  final customPrice = TextEditingController();

  double get quantity {
    if (product == null) return 0;
    if (tier == PriceTier.custom) return double.tryParse(customQty.text) ?? 0;
    return PriceTierCalculator.quantityFor(product!, tier);
  }

  int get price {
    if (product == null) return 0;
    if (tier == PriceTier.custom) return int.tryParse(customPrice.text) ?? 0;
    return PriceTierCalculator.priceFor(product!, tier);
  }
}

class SaleNewScreen extends StatefulWidget {
  const SaleNewScreen({super.key});

  @override
  State<SaleNewScreen> createState() => _SaleNewScreenState();
}

class _SaleNewScreenState extends State<SaleNewScreen> {
  List<Product> _products = [];
  Map<String, Inventory> _inventory = {};
  Customer? _customer;
  DateTime _orderDate = DateTime.now();
  final List<_SaleLineForm> _lines = [_SaleLineForm()];
  final _memo = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final products = await ProductRepository.instance.listAll(includeInactive: false);
    final inventory = await InventoryRepository.instance.listAll();
    setState(() {
      _products = products;
      _inventory = {for (final i in inventory) i.productId: i};
      _loading = false;
    });
  }

  int get _total => _lines.fold(0, (sum, l) => sum + l.price);

  Future<void> _pickCustomer() async {
    final result = await Navigator.of(context)
        .push<Customer>(MaterialPageRoute(builder: (_) => const CustomerListScreen(selectMode: true)));
    if (result != null) setState(() => _customer = result);
  }

  Future<void> _save() async {
    if (_customer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('顧客を選択してください')));
      return;
    }
    final validLines = _lines.where((l) => l.product != null && l.quantity > 0 && l.price > 0).toList();
    if (validLines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('商品・数量・価格を確認してください')));
      return;
    }

    setState(() => _saving = true);
    try {
      await SalesRepository.instance.createOrder(
        customerId: _customer!.id,
        orderDate: _orderDate,
        lines: validLines
            .map((l) => SaleLineInput(
                  product: l.product!,
                  quantity: l.quantity,
                  unitPrice: l.price,
                  priceTier: l.tier,
                ))
            .toList(),
        memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('販売登録')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('顧客'),
            subtitle: Text(_customer?.maskedName ?? '未選択'),
            trailing: const Icon(Icons.person_search),
            onTap: _pickCustomer,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('販売日'),
            subtitle: Text(Formatters.date(_orderDate)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _orderDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _orderDate = picked);
            },
          ),
          const Divider(),
          for (int idx = 0; idx < _lines.length; idx++) _buildLineCard(idx),
          TextButton.icon(
            onPressed: () => setState(() => _lines.add(_SaleLineForm())),
            icon: const Icon(Icons.add),
            label: const Text('商品を追加'),
          ),
          TextFormField(controller: _memo, decoration: const InputDecoration(labelText: 'メモ')),
          const SizedBox(height: 8),
          Text('合計金額: ${Formatters.yen(_total)}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '登録中...' : '販売登録（未発送として作成）'),
          ),
        ],
      ),
    );
  }

  Widget _buildLineCard(int idx) {
    final line = _lines[idx];
    final available = line.product != null ? (_inventory[line.product!.id]?.availableQuantity ?? 0) : 0;
    final overSelling = line.product != null && line.quantity > available;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<Product>(
                  value: line.product,
                  decoration: const InputDecoration(labelText: '商品'),
                  items:
                      _products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                  onChanged: (v) => setState(() => line.product = v),
                ),
              ),
              if (_lines.length > 1)
                IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _lines.removeAt(idx))),
            ]),
            if (line.product != null) ...[
              Text('在庫: ${Formatters.quantity(available)}${line.product!.unitLabel}',
                  style: Theme.of(context).textTheme.bodySmall),
              Wrap(
                spacing: 8,
                children: [
                  for (final tier in [PriceTier.x1, PriceTier.x3, PriceTier.x5, PriceTier.custom])
                    ChoiceChip(
                      label: Text(tier == PriceTier.custom
                          ? 'カスタム'
                          : '×${tier.multiplier} (${Formatters.yen(PriceTierCalculator.priceFor(line.product!, tier))})'),
                      selected: line.tier == tier,
                      onSelected: (_) => setState(() => line.tier = tier),
                    ),
                ],
              ),
              if (line.tier == PriceTier.custom)
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: line.customQty,
                      decoration: const InputDecoration(labelText: '数量'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: line.customPrice,
                      decoration: const InputDecoration(labelText: '販売価格'),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ])
              else
                Text('数量: ${Formatters.quantity(line.quantity)}${line.product!.unitLabel} / 金額: ${Formatters.yen(line.price)}'),
              if (overSelling)
                const Text('在庫数を超えています', style: TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
