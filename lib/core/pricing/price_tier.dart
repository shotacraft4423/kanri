import '../../models/enums.dart';
import '../../models/product.dart';

class PriceTierSelection {
  final PriceTier tier;
  final double quantity; // 実数量（最小販売単位の倍数）
  final int unitPrice; // 選択した価格帯の合計価格（線形単価ではなく帯合計として扱う）

  const PriceTierSelection({
    required this.tier,
    required this.quantity,
    required this.unitPrice,
  });
}

/// 商品の最小販売単位を基準に ×1/×3/×5 の数量・価格を算出する。
class PriceTierCalculator {
  const PriceTierCalculator._();

  static double quantityFor(Product product, PriceTier tier) {
    return product.minSaleUnit * tier.multiplier;
  }

  static int priceFor(Product product, PriceTier tier) {
    return switch (tier) {
      PriceTier.x1 => product.priceX1,
      PriceTier.x3 => product.priceX3,
      PriceTier.x5 => product.priceX5,
      PriceTier.custom => 0,
    };
  }

  static PriceTierSelection select(Product product, PriceTier tier) {
    return PriceTierSelection(
      tier: tier,
      quantity: quantityFor(product, tier),
      unitPrice: priceFor(product, tier),
    );
  }

  static List<PriceTierSelection> allTiers(Product product) => [
        select(product, PriceTier.x1),
        select(product, PriceTier.x3),
        select(product, PriceTier.x5),
      ];
}
