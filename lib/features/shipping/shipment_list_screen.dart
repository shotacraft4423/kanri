import 'package:flutter/material.dart';

import '../../core/util/formatters.dart';
import '../../models/customer.dart';
import '../../models/enums.dart';
import '../../models/order.dart';
import '../../models/shipment.dart';
import '../../repositories/customer_repository.dart';
import '../../repositories/sales_repository.dart';
import '../../repositories/shipment_repository.dart';
import 'shipment_detail_screen.dart';

class ShipmentListScreen extends StatefulWidget {
  final int initialTab;
  const ShipmentListScreen({super.key, this.initialTab = 0});

  @override
  State<ShipmentListScreen> createState() => _ShipmentListScreenState();
}

const _tabStatuses = [
  ShipmentStatus.notShipped,
  ShipmentStatus.shipped,
  ShipmentStatus.inTransit,
  ShipmentStatus.delivered,
];

class _ShipmentListScreenState extends State<ShipmentListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  List<_ShipmentRow> _all = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabStatuses.length, vsync: this, initialIndex: widget.initialTab);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final shipments = await ShipmentRepository.instance.listByStatus(null);
    final orders = {for (final o in await SalesRepository.instance.listAll()) o.id: o};
    final rows = <_ShipmentRow>[];
    for (final s in shipments) {
      final order = orders[s.orderId];
      if (order == null || order.isCancelled) continue;
      final customer = await CustomerRepository.instance.findById(order.customerId);
      rows.add(_ShipmentRow(shipment: s, order: order, customer: customer));
    }
    setState(() {
      _all = rows;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('発送'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabStatuses.map((s) => Tab(text: s.label)).toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _tabStatuses.map((status) {
                final rows = _all.where((r) => r.shipment.status == status).toList();
                return _ShipmentTab(rows: rows, onChanged: _load);
              }).toList(),
            ),
    );
  }
}

class _ShipmentRow {
  final Shipment shipment;
  final Order order;
  final Customer? customer;
  _ShipmentRow({required this.shipment, required this.order, required this.customer});
}

class _ShipmentTab extends StatelessWidget {
  final List<_ShipmentRow> rows;
  final VoidCallback onChanged;
  const _ShipmentTab({required this.rows, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const Center(child: Text('該当する注文はありません'));
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final r = rows[index];
        return ListTile(
          title: Text(r.order.orderNumber),
          subtitle: Text(
            '顧客: ${r.customer?.maskedName ?? '-'} ・ ${Formatters.date(r.order.orderDate)}\n'
            '追跡番号: ${r.shipment.trackingNumber ?? '未登録'}',
          ),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ShipmentDetailScreen(shipmentId: r.shipment.id)),
            );
            onChanged();
          },
        );
      },
    );
  }
}
