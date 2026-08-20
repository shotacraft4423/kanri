import 'package:flutter/material.dart';

import '../../core/util/formatters.dart';
import '../../models/enums.dart';
import '../../models/purchase.dart';
import '../../models/purchase_item.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/purchase_repository.dart';

class PurchaseDetailScreen extends StatefulWidget {
  final String purchaseId;
  const PurchaseDetailScreen({super.key, required this.purchaseId});

  @override
  State<PurchaseDetailScreen> createState() => _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends State<PurchaseDetailScreen> {
  Purchase? _purchase;
  List<PurchaseItem> _items = [];
  Map<String, String> _productNames = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final purchase = await PurchaseRepository.instance.findById(widget.purchaseId);
    final items = await PurchaseRepository.instance.itemsFor(widget.purchaseId);
    final names = <String, String>{};
    for (final item in items) {
      final product = await ProductRepository.instance.findById(item.productId);
      if (product != null) names[item.productId] = product.name;
    }
    setState(() {
      _purchase = purchase;
      _items = items;
      _productNames = names;
      _loading = false;
    });
  }

  Future<void> _changeStatus(PurchaseStatus status) async {
    await PurchaseRepository.instance.updateStatus(widget.purchaseId, status);
    _load();
  }

  Future<void> _registerTracking() async {
    final controller = TextEditingController(text: _purchase?.trackingNumber ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('追跡番号を登録'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: '追跡番号')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('保存')),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      await PurchaseRepository.instance.registerTracking(widget.purchaseId, result.trim());
      _load();
    }
  }

  Future<void> _receiveItem(PurchaseItem item) async {
    final controller =
        TextEditingController(text: (item.receivedQuantity ?? item.quantity).toString());
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('入荷処理'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: '入荷数量（発注数: ${Formatters.quantity(item.quantity)}）'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          FilledButton(
            onPressed: () => Navigator.pop(context, double.tryParse(controller.text)),
            child: const Text('反映'),
          ),
        ],
      ),
    );
    if (result != null) {
      await PurchaseRepository.instance.receiveItem(
        purchaseItemId: item.id,
        newReceivedQuantity: result,
      );
      _load();
    }
  }

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('仕入れキャンセルの確認'),
        content: const Text('この仕入れをキャンセルしますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('戻る')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('キャンセルする')),
        ],
      ),
    );
    if (confirmed == true) {
      await PurchaseRepository.instance.cancel(widget.purchaseId);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _purchase == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final p = _purchase!;
    return Scaffold(
      appBar: AppBar(
        title: Text('仕入れ詳細 ${Formatters.date(p.purchaseDate)}'),
        actions: [
          if (p.status != PurchaseStatus.cancelled && p.status != PurchaseStatus.received)
            IconButton(icon: const Icon(Icons.cancel), onPressed: _confirmCancel),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('ステータス', style: Theme.of(context).textTheme.titleSmall),
          Wrap(
            spacing: 8,
            children: PurchaseStatus.values
                .where((s) => s != PurchaseStatus.cancelled)
                .map((s) => ChoiceChip(
                      label: Text(s.label),
                      selected: p.status == s,
                      onSelected: (_) => _changeStatus(s),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('追跡番号'),
            subtitle: Text(p.trackingNumber ?? '未登録'),
            trailing: const Icon(Icons.edit),
            onTap: _registerTracking,
          ),
          if (p.arrivalDate != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('到着日'),
              subtitle: Text(Formatters.date(p.arrivalDate)),
            ),
          if (p.memo != null && p.memo!.isNotEmpty)
            ListTile(contentPadding: EdgeInsets.zero, title: const Text('メモ'), subtitle: Text(p.memo!)),
          const Divider(),
          Text('明細', style: Theme.of(context).textTheme.titleSmall),
          for (final item in _items) _buildItemTile(item),
        ],
      ),
    );
  }

  Widget _buildItemTile(PurchaseItem item) {
    final received = item.isReceived;
    return Card(
      child: ListTile(
        title: Text(_productNames[item.productId] ?? item.productId),
        subtitle: Text(
          '数量 ${Formatters.quantity(item.quantity)} ・ 実支払額 ${Formatters.yen(item.actualPaid)}\n'
          '入荷済み: ${received ? Formatters.quantity(item.receivedQuantity!) : '未入荷'}',
        ),
        isThreeLine: true,
        trailing: FilledButton(
          onPressed: () => _receiveItem(item),
          child: Text(received ? '入荷数量修正' : '入荷処理'),
        ),
      ),
    );
  }
}
