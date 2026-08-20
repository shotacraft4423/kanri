enum PurchaseStatus {
  beforeOrder,
  ordered,
  shipped,
  inTransit,
  arrived,
  received,
  cancelled;

  String get label => switch (this) {
        PurchaseStatus.beforeOrder => '発注前',
        PurchaseStatus.ordered => '発注済み',
        PurchaseStatus.shipped => '発送済み',
        PurchaseStatus.inTransit => '配送中',
        PurchaseStatus.arrived => '到着',
        PurchaseStatus.received => '入荷処理済み',
        PurchaseStatus.cancelled => 'キャンセル',
      };

  static PurchaseStatus fromName(String name) =>
      PurchaseStatus.values.firstWhere((e) => e.name == name);
}

enum ShipmentStatus {
  notShipped,
  preparing,
  shipped,
  inTransit,
  delivered,
  onHold,
  cancelled;

  String get label => switch (this) {
        ShipmentStatus.notShipped => '未発送',
        ShipmentStatus.preparing => '発送準備中',
        ShipmentStatus.shipped => '発送済み',
        ShipmentStatus.inTransit => '配送中',
        ShipmentStatus.delivered => '配達完了',
        ShipmentStatus.onHold => '保留',
        ShipmentStatus.cancelled => 'キャンセル',
      };

  static ShipmentStatus fromName(String name) =>
      ShipmentStatus.values.firstWhere((e) => e.name == name);
}

enum InventoryAdjustmentReason {
  stocktake,
  damaged,
  lost,
  correction,
  other;

  String get label => switch (this) {
        InventoryAdjustmentReason.stocktake => '棚卸し',
        InventoryAdjustmentReason.damaged => '破損',
        InventoryAdjustmentReason.lost => '紛失',
        InventoryAdjustmentReason.correction => '入力ミス修正',
        InventoryAdjustmentReason.other => 'その他',
      };

  static InventoryAdjustmentReason fromName(String name) =>
      InventoryAdjustmentReason.values.firstWhere((e) => e.name == name);
}

enum PriceTier {
  x1,
  x3,
  x5,
  custom;

  int get multiplier => switch (this) {
        PriceTier.x1 => 1,
        PriceTier.x3 => 3,
        PriceTier.x5 => 5,
        PriceTier.custom => 0,
      };

  static PriceTier fromName(String name) =>
      PriceTier.values.firstWhere((e) => e.name == name);
}

enum CostStrategy {
  movingAverage,
  fifo;

  static CostStrategy fromName(String name) =>
      CostStrategy.values.firstWhere((e) => e.name == name);
}
