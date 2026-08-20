import 'package:flutter/material.dart';

import '../../core/db/app_database.dart';
import '../../core/util/formatters.dart';

class MonthlyStat {
  final String month; // YYYY-MM
  final int sales;
  final int profit;
  final int orderCount;
  const MonthlyStat({required this.month, required this.sales, required this.profit, required this.orderCount});
}

/// 月別売上・利益の簡易集計画面（要件19, 20, 23）。
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  Future<List<MonthlyStat>> _load() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT substr(o.order_date, 1, 7) as month,
             COALESCE(SUM(oi.line_total), 0) as sales,
             COALESCE(SUM(oi.profit), 0) as profit,
             COUNT(DISTINCT o.id) as cnt
      FROM orders o
      JOIN order_items oi ON oi.order_id = o.id
      WHERE o.is_cancelled = 0
      GROUP BY month
      ORDER BY month DESC
      LIMIT 12
    ''');
    return rows
        .map((r) => MonthlyStat(
              month: r['month'] as String,
              sales: (r['sales'] as num).toInt(),
              profit: (r['profit'] as num).toInt(),
              orderCount: (r['cnt'] as num).toInt(),
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('集計')),
      body: FutureBuilder<List<MonthlyStat>>(
        future: _load(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final stats = snapshot.data!;
          if (stats.isEmpty) return const Center(child: Text('集計対象のデータがありません'));
          return ListView.builder(
            itemCount: stats.length,
            itemBuilder: (context, index) {
              final s = stats[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(s.month),
                  subtitle: Text('販売件数 ${s.orderCount}件'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('売上 ${Formatters.yen(s.sales)}'),
                      Text('利益 ${Formatters.yen(s.profit)}', style: const TextStyle(color: Colors.green)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
