import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../repositories/product_repository.dart';

class ProductEditScreen extends StatefulWidget {
  final Product? product;
  const ProductEditScreen({super.key, this.product});

  @override
  State<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _shortName;
  late final TextEditingController _purchaseUnit;
  late final TextEditingController _purchaseQty;
  late final TextEditingController _purchasePrice;
  late final TextEditingController _minSaleUnit;
  late final TextEditingController _unitLabel;
  late final TextEditingController _priceX1;
  late final TextEditingController _priceX3;
  late final TextEditingController _priceX5;
  late final TextEditingController _shippingNote;
  late final TextEditingController _lowStock;
  late final TextEditingController _memo;
  bool _isActive = true;
  bool _saving = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _shortName = TextEditingController(text: p?.shortName ?? '');
    _purchaseUnit = TextEditingController(text: p?.purchaseUnit ?? '個');
    _purchaseQty = TextEditingController(text: p?.purchaseQty.toString() ?? '10');
    _purchasePrice = TextEditingController(text: p?.purchasePrice.toString() ?? '');
    _minSaleUnit = TextEditingController(text: p?.minSaleUnit.toString() ?? '1');
    _unitLabel = TextEditingController(text: p?.unitLabel ?? '個');
    _priceX1 = TextEditingController(text: p?.priceX1.toString() ?? '');
    _priceX3 = TextEditingController(text: p?.priceX3.toString() ?? '');
    _priceX5 = TextEditingController(text: p?.priceX5.toString() ?? '');
    _shippingNote = TextEditingController(text: p?.shippingNote ?? '');
    _lowStock = TextEditingController(text: p?.lowStockThreshold.toString() ?? '0');
    _memo = TextEditingController(text: p?.memo ?? '');
    _isActive = p?.isActive ?? true;
  }

  String? _requiredNumber(String? v) {
    if (v == null || v.trim().isEmpty) return '入力してください';
    if (double.tryParse(v) == null) return '数値を入力してください';
    return null;
  }

  String? _positivePrice(String? v) {
    final err = _requiredNumber(v);
    if (err != null) return err;
    if (double.parse(v!) <= 0) return '0より大きい値を入力してください';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (_isEdit) {
        final updated = widget.product!.copyWith(
          name: _name.text.trim(),
          shortName: _shortName.text.trim().isEmpty ? null : _shortName.text.trim(),
          purchaseUnit: _purchaseUnit.text.trim(),
          purchaseQty: double.parse(_purchaseQty.text),
          purchasePrice: int.parse(_purchasePrice.text),
          minSaleUnit: double.parse(_minSaleUnit.text),
          unitLabel: _unitLabel.text.trim(),
          priceX1: int.parse(_priceX1.text),
          priceX3: int.parse(_priceX3.text),
          priceX5: int.parse(_priceX5.text),
          shippingNote: _shippingNote.text.trim().isEmpty ? null : _shippingNote.text.trim(),
          isActive: _isActive,
          lowStockThreshold: double.parse(_lowStock.text),
          memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
        );
        await ProductRepository.instance.update(updated);
      } else {
        await ProductRepository.instance.create(
          name: _name.text.trim(),
          shortName: _shortName.text.trim().isEmpty ? null : _shortName.text.trim(),
          purchaseUnit: _purchaseUnit.text.trim(),
          purchaseQty: double.parse(_purchaseQty.text),
          purchasePrice: int.parse(_purchasePrice.text),
          minSaleUnit: double.parse(_minSaleUnit.text),
          unitLabel: _unitLabel.text.trim(),
          priceX1: int.parse(_priceX1.text),
          priceX3: int.parse(_priceX3.text),
          priceX5: int.parse(_priceX5.text),
          shippingNote: _shippingNote.text.trim().isEmpty ? null : _shippingNote.text.trim(),
          lowStockThreshold: double.parse(_lowStock.text),
          memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmStopSelling() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('販売停止の確認'),
        content: Text('「${widget.product!.name}」を販売停止にしますか？\n過去の履歴は保持されます。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('販売停止にする')),
        ],
      ),
    );
    if (confirmed == true) {
      await ProductRepository.instance.setActive(widget.product!.id, false);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '商品編集' : '商品追加'),
        actions: [
          if (_isEdit && widget.product!.isActive)
            IconButton(
              icon: const Icon(Icons.block),
              tooltip: '販売停止にする',
              onPressed: _confirmStopSelling,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: '商品名 *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? '入力してください' : null,
            ),
            TextFormField(controller: _shortName, decoration: const InputDecoration(labelText: '商品略称')),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _purchaseUnit,
                  decoration: const InputDecoration(labelText: '仕入れ単位（例: 個, g）'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _unitLabel,
                  decoration: const InputDecoration(labelText: '表示単位（例: 個, 枚, g）'),
                ),
              ),
            ]),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _purchaseQty,
                  decoration: const InputDecoration(labelText: '標準仕入れ数量'),
                  keyboardType: TextInputType.number,
                  validator: _requiredNumber,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _purchasePrice,
                  decoration: const InputDecoration(labelText: '標準仕入れ価格（目安）'),
                  keyboardType: TextInputType.number,
                  validator: _requiredNumber,
                ),
              ),
            ]),
            TextFormField(
              controller: _minSaleUnit,
              decoration: const InputDecoration(labelText: '最小販売単位 * （例: 1, 0.5, 0.1）'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: _positivePrice,
            ),
            const SizedBox(height: 12),
            Text('販売価格', style: Theme.of(context).textTheme.titleSmall),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _priceX1,
                  decoration: const InputDecoration(labelText: '×1価格 *'),
                  keyboardType: TextInputType.number,
                  validator: _positivePrice,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _priceX3,
                  decoration: const InputDecoration(labelText: '×3価格 *'),
                  keyboardType: TextInputType.number,
                  validator: _positivePrice,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _priceX5,
                  decoration: const InputDecoration(labelText: '×5価格 *'),
                  keyboardType: TextInputType.number,
                  validator: _positivePrice,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              controller: _shippingNote,
              decoration: const InputDecoration(labelText: '発送時の注意事項'),
            ),
            TextFormField(
              controller: _lowStock,
              decoration: const InputDecoration(labelText: '最低在庫アラート数量'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            TextFormField(
              controller: _memo,
              decoration: const InputDecoration(labelText: 'メモ'),
              maxLines: 3,
            ),
            if (_isEdit)
              SwitchListTile(
                title: const Text('販売中'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? '保存中...' : '保存'),
            ),
          ],
        ),
      ),
    );
  }
}
