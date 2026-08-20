import 'package:flutter/material.dart';

import '../../models/customer.dart';
import '../../repositories/customer_repository.dart';

class CustomerEditScreen extends StatefulWidget {
  final Customer? customer;
  const CustomerEditScreen({super.key, this.customer});

  @override
  State<CustomerEditScreen> createState() => _CustomerEditScreenState();
}

class _CustomerEditScreenState extends State<CustomerEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _postalCode;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _memo;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _name = TextEditingController(text: c?.name ?? '');
    _postalCode = TextEditingController(text: c?.postalCode ?? '');
    _address = TextEditingController(text: c?.address ?? '');
    _phone = TextEditingController(text: c?.phone ?? '');
    _memo = TextEditingController(text: c?.memo ?? '');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      Customer result;
      if (widget.customer != null) {
        result = widget.customer!.copyWith(
          name: _name.text.trim(),
          postalCode: _postalCode.text.trim(),
          address: _address.text.trim(),
          phone: _phone.text.trim(),
          memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
        );
        await CustomerRepository.instance.update(result);
      } else {
        result = await CustomerRepository.instance.create(
          name: _name.text.trim(),
          postalCode: _postalCode.text.trim().isEmpty ? null : _postalCode.text.trim(),
          address: _address.text.trim().isEmpty ? null : _address.text.trim(),
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop(result);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.customer != null ? '顧客編集' : '顧客追加')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('この情報は機密として扱われ、一覧では表示されません。',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: '顧客名 *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? '入力してください' : null,
            ),
            TextFormField(controller: _postalCode, decoration: const InputDecoration(labelText: '郵便番号')),
            TextFormField(controller: _address, decoration: const InputDecoration(labelText: '住所'), maxLines: 2),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(labelText: '電話番号'),
              keyboardType: TextInputType.phone,
            ),
            TextFormField(controller: _memo, decoration: const InputDecoration(labelText: 'メモ'), maxLines: 3),
            const SizedBox(height: 24),
            FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? '保存中...' : '保存')),
          ],
        ),
      ),
    );
  }
}
