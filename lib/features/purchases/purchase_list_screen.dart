import 'package:flutter/material.dart';

import '../../core/util/formatters.dart';
import '../../models/enums.dart';
import '../../models/purchase.dart';
import '../../repositories/purchase_repository.dart';
import 'purchase_detail_screen.dart';
import 'purchase_new_screen.dart';

class PurchaseListScreen extends StatefulWidget {
  const PurchaseListScreen({super.key});

  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Purchase> _purchases = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final purchases = await PurchaseRepository.instance.listAll();
    setState(() {
      _purchases = purchases;
      _loading = false;
    });
  }

  List<Purchase> get _awaitingArrival => _purchases
      .where((p) => [
            PurchaseStatus.beforeOrder,
            PurchaseStatus.ordered,
            PurchaseStatus.shipped,
            PurchaseStatus.inTransit,
            PurchaseStatus.arrived,
          ].contains(p.status))
      .toList();

  List<Purchase> get _received =>
      _purchases.where((p) => p.status == PurchaseStatus.received).toList();

  List<Purchase> get _cancelled =>
      _purchases.where((p) => p.status == PurchaseStatus.cancelled).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('仕入れ'),
        bottom: TabBar(controller: _tabController, tabs: const [
          Tab(text: '未到着'),
          Tab(text: '入荷済み'),
          Tab(text: 'キャンセル'),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const PurchaseNewScreen()));
          _load();
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _PurchaseList(purchases: _awaitingArrival, onChanged: _load),
                _PurchaseList(purchases: _received, onChanged: _load),
                _PurchaseList(purchases: _cancelled, onChanged: _load),
              ],
            ),
    );
  }
}

class _PurchaseList extends StatelessWidget {
  final List<Purchase> purchases;
  final VoidCallback onChanged;
  const _PurchaseList({required this.purchases, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    if (purchases.isEmpty) {
      return const Center(child: Text('該当する仕入れはありません'));
    }
    return ListView.builder(
      itemCount: purchases.length,
      itemBuilder: (context, index) {
        final p = purchases[index];
        return ListTile(
          title: Text(Formatters.date(p.purchaseDate)),
          subtitle: Text(p.trackingNumber != null ? '追跡番号: ${p.trackingNumber}' : '追跡番号未登録'),
          trailing: Chip(label: Text(p.status.label)),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PurchaseDetailScreen(purchaseId: p.id)),
            );
            onChanged();
          },
        );
      },
    );
  }
}
