class AppSettingsKeys {
  static const costStrategy = 'cost_strategy';
  static const autoLockSeconds = 'auto_lock_seconds';
  static const lockOnBackground = 'lock_on_background';
  static const lockOnLaunch = 'lock_on_launch';
  static const notificationsEnabled = 'notifications_enabled';
  static const notifyUnshippedDays = 'notify_unshipped_days';
  static const notifyPurchaseOverdueDays = 'notify_purchase_overdue_days';
  static const defaultShippingCarrier = 'default_shipping_carrier';
  static const buyerShippingIncludedInPrice = 'buyer_shipping_included_in_price';
}

/// key-value 形式で app_settings テーブルに保持する設定値。
class AppSetting {
  final String key;
  final String value;

  const AppSetting({required this.key, required this.value});

  Map<String, Object?> toMap() => {'key': key, 'value': value};

  factory AppSetting.fromMap(Map<String, Object?> m) => AppSetting(
        key: m['key'] as String,
        value: m['value'] as String,
      );
}
