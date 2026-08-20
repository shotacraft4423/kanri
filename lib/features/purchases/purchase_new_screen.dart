import 'package:flutter/material.dart';

import '../../core/pricing/cost_calculator.dart';
import '../../core/util/formatters.dart';
import '../../models/product.dart';
import '../../models/supplier.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/purchase_repository.dart';
import '../../repositories/supplier_repository.dart';

class _ItemForm {
  Product? product;
  final quantity = TextEditingController(text: '1');
  final itemCost = TextEditingController();
  final shippingCost = TextEditingController(text: '1000');
  final fee = TextEditingController(text: '0');
  final adjustment = TextEditingController(text: '0');
  final actualPaid = TextEditingController();

  void autoFillActualPaid() {
    final i = int.tryParse(itemCost.text) ?? 0;
    final s = int.tryParse(shippingCost.text) ?? 0;
    final f = int.tryParse(fee.text) ?? 0;
    final a = int.tryParse(adjustment.text) ?? 0;
    actualPaid.text = (i + s + f + a).toString();
  }

  int get referenceCost {
    final i = int.tryParse(itemCost.text) ?? 0;
    final s = int.tryParse(shippingCost.text) ?? 0;
    return CostCalculator.estimatedPurchaseCost(itemCost: i, shippingCost: s);
  }
}

class PurchaseNewScreen extends StatefulWidget {
  const PurchaseNewScreen({super.key});

  @override
  State<PurchaseNewScreen> createState() => _PurchaseNewScreenState();
}

class _PurchaseNewScreenState extends State<PurchaseNewScreen> {
  List<Product> _products = [];
  Supplier? _supplier;
  DateTime _purchaseDate = DateTime.now();
  final _memo = TextEditingController();
  final List<_ItemForm> _items = [_ItemForm()];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final products = await ProductRepository.instance.listAll(includeInactive: false);
    final supplier = await SupplierRepository.instance.ensureDefault();
    setState(() {
      _products = products;
      _supplier = supplier;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_supplier == null) return;
    final validItems = _items.where((i) => i.product != null).toList();
    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('商品を1つ以上選択してください')));
      return;
    }
    setState(() => _saving = true);
    try {
      final inputs = validItems
          .map((i) => PurchaseItemInput(
                productId: i.product!.id,
                quantity: double.tryParse(i.quantity.text) ?? 0,
                itemCost: int.tryParse(i.itemCost.text) ?? 0,
                shippingCost: int.tryParse(i.shippingCost.text) ?? 0,
                fee: int.tryParse(i.fee.text) ?? 0,
                adjustment: int.tryParse(i.adjustment.text) ?? 0,
                actualPaid: int.tryParse(i.actualPaid.text) ??
                    ((int.tryParse(i.itemCost.text) ?? 0) + (int.tryParse(i.shippingCost.text) ?? 0)),
              ))
          .toList();
      await PurchaseRepository.instance.create(
        supplierId: _supplier!.id,
        purchaseDate: _purchaseDate,
        items: inputs,
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
      appBar: AppBar(title: const Text('仕入れ登録')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('仕入れ日'),
            subtitle: Text(Formatters.date(_purchaseDate)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _purchaseDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _purchaseDate = picked);
            },
          ),
          Text('仕入先: ${_supplier?.name ?? ''}'),
          const Divider(),
          for (int idx = 0; idx < _items.length; idx++) _buildItemCard(idx),
          TextButton.icon(
            onPressed: () => setState(() => _items.add(_ItemForm())),
            icon: const Icon(Icons.add),
            label: const Text('商品を追加'),
          ),
          TextFormField(controller: _memo, decoration: const InputDecoration(labelText: 'メモ')),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '保存中...' : '仕入れを登録'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(int idx) {
    final item = _items[idx];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Product>(
                    value: item.product,
                    decoration: const InputDecoration(labelText: '商品'),
                    items: _products
                        .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                        .toList(),
                    onChanged: (v) => setState(() => item.product = v),
                  ),
                ),
                if (_items.length > 1)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _items.removeAt(idx)),
                  ),
              ],
            ),
            TextFormField(
              controller: item.quantity,
              decoration: const InputDecoration(labelText: '数量'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: item.itemCost,
                  decoration: const InputDecoration(labelText: '商品代'),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: item.shippingCost,
                  decoration: const InputDecoration(labelText: '送料'),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ]),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: item.fee,
                  decoration: const InputDecoration(labelText: '手数料'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: item.adjustment,
                  decoration: const InputDecoration(labelText: '調整額'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ]),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: item.actualPaid,
                  decoration: const InputDecoration(labelText: '実際の支払額'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => setState(() => item.autoFillActualPaid()),
                child: const Text('自動計算'),
              ),
            ]),
            Text('原価計算目安（税・送料込み100円切上げ）: ${Formatters.yen(item.referenceCost)}',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
