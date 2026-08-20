import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../repositories/purchase_repository.dart';
import '../../repositories/shipment_repository.dart';
import '../purchases/purchase_list_screen.dart';
import '../shipping/shipment_list_screen.dart';

/// 「物流センター」画面。仕入れ〜配達完了までの全ステータスを
/// 1画面で件数確認できるようにする（要件22, 39）。
class LogisticsScreen extends StatefulWidget {
  const LogisticsScreen({super.key});

  @override
  State<LogisticsScreen> createState() => _LogisticsScreenState();
}

class _LogisticsScreenState extends State<LogisticsScreen> {
  Map<PurchaseStatus, int> _purchaseCounts = {};
  Map<ShipmentStatus, int> _shipmentCounts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final purchases = await PurchaseRepository.instance.listAll();
    final shipments = await ShipmentRepository.instance.listByStatus(null);

    final pCounts = <PurchaseStatus, int>{};
    for (final status in PurchaseStatus.values) {
      pCounts[status] = purchases.where((p) => p.status == status).length;
    }
    final sCounts = <ShipmentStatus, int>{};
    for (final status in ShipmentStatus.values) {
      sCounts[status] = shipments.where((s) => s.status == status).length;
    }

    setState(() {
      _purchaseCounts = pCounts;
      _shipmentCounts = sCounts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('物流センター')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('仕入れ', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...PurchaseStatus.values.map((s) => _StatusRow(
                        label: s.label,
                        count: _purchaseCounts[s] ?? 0,
                        onTap: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => const PurchaseListScreen())),
                      )),
                  const SizedBox(height: 24),
                  Text('発送', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...ShipmentStatus.values.asMap().entries.map((entry) => _StatusRow(
                        label: entry.value.label,
                        count: _shipmentCounts[entry.value] ?? 0,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => ShipmentListScreen(
                                  initialTab: entry.key < 4 ? entry.key : 0)),
                        ),
                      )),
                ],
              ),
            ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback onTap;
  const _StatusRow({required this.label, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text('$count件', style: Theme.of(context).textTheme.titleMedium),
        onTap: onTap,
      ),
    );
  }
}
