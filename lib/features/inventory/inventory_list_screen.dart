import 'package:flutter/material.dart';

import '../../core/util/formatters.dart';
import '../../models/enums.dart';
import '../../models/inventory.dart';
import '../../models/product.dart';
import '../../repositories/inventory_repository.dart';
import '../../repositories/product_repository.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  List<Product> _products = [];
  Map<String, Inventory> _inventory = {};
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
      _inventory = {for (final i in inventory) i.productId: i};
      _loading = false;
    });
  }

  Future<void> _showAdjustDialog(Product product) async {
    final qtyController = TextEditingController();
    final memoController = TextEditingController();
    InventoryAdjustmentReason reason = InventoryAdjustmentReason.stocktake;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('在庫調整: ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: qtyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: const InputDecoration(labelText: '増減数量（マイナス可）'),
              ),
              DropdownButtonFormField<InventoryAdjustmentReason>(
                value: reason,
                decoration: const InputDecoration(labelText: '理由'),
                items: InventoryAdjustmentReason.values
                    .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                    .toList(),
                onChanged: (v) => setDialogState(() => reason = v ?? reason),
              ),
              TextField(controller: memoController, decoration: const InputDecoration(labelText: 'メモ')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('調整を反映')),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final delta = double.tryParse(qtyController.text);
      if (delta == null || delta == 0) return;
      await InventoryRepository.instance.adjust(
        productId: product.id,
        quantityDelta: delta,
        reason: reason,
        memo: memoController.text.trim().isEmpty ? null : memoController.text.trim(),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('在庫')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final p = _products[index];
                final inv = _inventory[p.id];
                final qty = inv?.quantity ?? 0;
                final available = inv?.availableQuantity ?? 0;
                final statusLabel = qty <= 0
                    ? '在庫切れ'
                    : (qty <= p.lowStockThreshold ? '残りわずか' : '正常');
                final statusColor = qty <= 0
                    ? Colors.redAccent
                    : (qty <= p.lowStockThreshold ? Colors.amber : Colors.green);
                return ListTile(
                  title: Text(p.name),
                  subtitle: Text(
                    '現在庫 ${Formatters.quantity(qty)}${p.unitLabel} ・ 販売可能 ${Formatters.quantity(available)}${p.unitLabel}\n'
                    '最低在庫: ${Formatters.quantity(p.lowStockThreshold)}${p.unitLabel}',
                  ),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Chip(label: Text(statusLabel), backgroundColor: statusColor.withOpacity(0.2)),
                      TextButton(onPressed: () => _showAdjustDialog(p), child: const Text('調整')),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
