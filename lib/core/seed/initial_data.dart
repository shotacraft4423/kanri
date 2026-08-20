import '../../repositories/product_repository.dart';
import '../../repositories/supplier_repository.dart';

/// 初回起動時のみ、要件書セクション4/31のサンプル商品を投入する。
/// あくまで一例であり、アプリ上で自由に追加・変更・販売停止できる（要件3, 4, 31）。
class InitialDataSeeder {
  const InitialDataSeeder._();

  static Future<void> seedIfEmpty() async {
    final existing = await ProductRepository.instance.listAll();
    if (existing.isNotEmpty) return;

    await SupplierRepository.instance.ensureDefault();

    await ProductRepository.instance.create(
      name: 'M',
      purchaseUnit: '個',
      purchaseQty: 10,
      purchasePrice: 18000,
      minSaleUnit: 1,
      unitLabel: '個',
      priceX1: 3700,
      priceX3: 10500,
      priceX5: 16500,
      lowStockThreshold: 3,
    );

    await ProductRepository.instance.create(
      name: 'W',
      shortName: 'W(1個)',
      purchaseUnit: '個',
      purchaseQty: 10,
      purchasePrice: 15000,
      minSaleUnit: 1,
      unitLabel: '個',
      priceX1: 6000,
      priceX3: 17000,
      priceX5: 27500,
      lowStockThreshold: 3,
    );

    await ProductRepository.instance.create(
      name: 'W（特殊梱包）',
      shortName: 'W(0.5個)',
      purchaseUnit: '個',
      purchaseQty: 10,
      purchasePrice: 15000,
      minSaleUnit: 0.5,
      unitLabel: '個',
      priceX1: 3000,
      priceX3: 8500,
      priceX5: 13500,
      lowStockThreshold: 3,
    );

    await ProductRepository.instance.create(
      name: 'L',
      purchaseUnit: '枚',
      purchaseQty: 10,
      purchasePrice: 15000,
      minSaleUnit: 1,
      unitLabel: '枚',
      priceX1: 3000,
      priceX3: 8500,
      priceX5: 13500,
      lowStockThreshold: 3,
    );

    await ProductRepository.instance.create(
      name: 'K',
      purchaseUnit: 'g',
      purchaseQty: 1,
      purchasePrice: 9000,
      minSaleUnit: 0.1,
      unitLabel: 'g',
      priceX1: 1800,
      priceX3: 5000,
      priceX5: 8000,
      lowStockThreshold: 0.3,
      shippingNote: '数量の取り扱いに注意（0.1g単位）',
    );
  }
}
