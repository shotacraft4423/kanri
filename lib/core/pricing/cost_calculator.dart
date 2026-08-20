/// 仕入れ原価計算ユーティリティ。
///
/// 仕様（要件5）:
///   仕入れ価格 = ceil((商品代金 + 送料) × 1.05 / 100) × 100
/// すなわち、消費税等5%を加算した金額を「100円未満切り上げ」する。
class CostCalculator {
  const CostCalculator._();

  static int estimatedPurchaseCost({
    required int itemCost,
    required int shippingCost,
    double taxRate = 1.05,
  }) {
    final raw = (itemCost + shippingCost) * taxRate;
    return (raw / 100).ceil() * 100;
  }
}
