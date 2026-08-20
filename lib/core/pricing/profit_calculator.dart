/// 利益計算ユーティリティ。
///
/// 販売時点の原価スナップショット(unitCostTotal、数量分の原価合計)を
/// order_items 保存時に確定させることで、後日の商品マスタ/原価変更が
/// 過去の販売記録に影響しないようにする（要件18, 38）。
class ProfitCalculator {
  const ProfitCalculator._();

  static int calcProfit({
    required int lineTotal,
    required int unitCostTotal,
    int additionalCost = 0,
  }) {
    return lineTotal - unitCostTotal - additionalCost;
  }

  /// 移動平均原価（商品の基本単位1つあたりの原価）から、
  /// 販売数量（同じ基本単位、例: 個数やg数そのもの）に対する原価合計を算出する。
  /// avgUnitCost・quantity はいずれも product_cost / purchase_items と同じ基本単位系で
  /// 揃っているため、最小販売単位で割り戻す必要はない（要件9, 18）。
  static int costTotalForQuantity({
    required int avgUnitCost,
    required double quantity,
  }) {
    return (avgUnitCost * quantity).round();
  }
}
