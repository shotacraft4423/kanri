import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/util/carrier_tracking.dart';
import '../../core/util/formatters.dart';
import '../../models/enums.dart';
import '../../models/order.dart';
import '../../models/shipment.dart';
import '../../repositories/sales_repository.dart';
import '../../repositories/shipment_repository.dart';

class ShipmentDetailScreen extends StatefulWidget {
  final String shipmentId;
  const ShipmentDetailScreen({super.key, required this.shipmentId});

  @override
  State<ShipmentDetailScreen> createState() => _ShipmentDetailScreenState();
}

class _ShipmentDetailScreenState extends State<ShipmentDetailScreen> {
  Shipment? _shipment;
  Order? _order;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final shipments = await ShipmentRepository.instance.listByStatus(null);
    final shipment = shipments.firstWhere((s) => s.id == widget.shipmentId);
    final order = (await SalesRepository.instance.listAll())
        .firstWhere((o) => o.id == shipment.orderId);
    setState(() {
      _shipment = shipment;
      _order = order;
      _loading = false;
    });
  }

  Future<void> _changeStatus(ShipmentStatus status) async {
    if (status == ShipmentStatus.shipped && _shipment!.trackingNumber == null) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('確認'),
          content: const Text('追跡番号が未登録です。このまま発送済みにしますか？'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('発送済みにする')),
          ],
        ),
      );
      if (proceed != true) return;
    }
    await ShipmentRepository.instance.updateStatus(shipmentId: widget.shipmentId, status: status);
    _load();
  }

  Future<void> _registerTracking() async {
    final controller = TextEditingController(text: _shipment?.trackingNumber ?? '');
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
      await ShipmentRepository.instance.registerTracking(widget.shipmentId, result.trim());
      _load();
    }
  }

  Future<void> _openTrackingPage() async {
    final url = CarrierTracking.urlFor(_shipment!.carrier, _shipment!.trackingNumber);
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _shipment == null || _order == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final s = _shipment!;
    final trackingUrl = CarrierTracking.urlFor(s.carrier, s.trackingNumber);

    return Scaffold(
      appBar: AppBar(title: Text('発送詳細 ${_order!.orderNumber}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('ステータス', style: Theme.of(context).textTheme.titleSmall),
          Wrap(
            spacing: 8,
            children: ShipmentStatus.values
                .map((status) => ChoiceChip(
                      label: Text(status.label),
                      selected: s.status == status,
                      onSelected: (_) => _changeStatus(status),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          Text('配送方法: ${s.carrier}'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('追跡番号'),
            subtitle: Text(s.trackingNumber ?? '未登録'),
            trailing: const Icon(Icons.edit),
            onTap: _registerTracking,
          ),
          if (trackingUrl != null)
            OutlinedButton.icon(
              onPressed: _openTrackingPage,
              icon: const Icon(Icons.open_in_new),
              label: const Text('配送状況を確認（オンライン）'),
            ),
          if (s.shippedAt != null)
            ListTile(contentPadding: EdgeInsets.zero, title: const Text('発送日'), subtitle: Text(Formatters.date(s.shippedAt))),
          if (s.arrivedAt != null)
            ListTile(contentPadding: EdgeInsets.zero, title: const Text('到着日'), subtitle: Text(Formatters.date(s.arrivedAt))),
        ],
      ),
    );
  }
}
