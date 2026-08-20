import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../models/product_cost.dart';

/// 原価計算方式のインターフェース。初期実装は移動平均原価法。
/// 将来のFIFO対応時は本インターフェースを実装したクラスを追加し、
/// app_settings の cost_strategy 値で切り替える。
abstract class CostStrategyEngine {
  Future<ProductCost> applyReceiving({
    required Transaction txn,
    required String productId,
    required double receivedQuantityDelta,
    required int costDelta,
  });
}

class MovingAverageCostStrategy implements CostStrategyEngine {
  @override
  Future<ProductCost> applyReceiving({
    required Transaction txn,
    required String productId,
    required double receivedQuantityDelta,
    required int costDelta,
  }) async {
    final rows = await txn.query('product_cost', where: 'product_id = ?', whereArgs: [productId]);
    final now = DateTime.now();

    double prevQty = 0;
    int prevCost = 0;
    if (rows.isNotEmpty) {
      prevQty = (rows.first['total_received_quantity'] as num).toDouble();
      prevCost = rows.first['total_received_cost'] as int;
    }

    final newQty = prevQty + receivedQuantityDelta;
    final newCost = prevCost + costDelta;
    final avgUnitCost = newQty > 0 ? (newCost / newQty).round() : 0;

    final updated = ProductCost(
      productId: productId,
      avgUnitCost: avgUnitCost,
      totalReceivedQuantity: newQty,
      totalReceivedCost: newCost,
      updatedAt: now,
    );

    await txn.insert(
      'product_cost',
      updated.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return updated;
  }
}
