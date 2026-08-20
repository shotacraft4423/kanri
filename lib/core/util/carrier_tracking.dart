/// 配送方法ごとの追跡ページURL生成。将来的に配送方法が増えても
/// マップに追加するだけで対応できる構造にする（要件21, 30）。
class CarrierTracking {
  const CarrierTracking._();

  static final Map<String, String Function(String)> _urlBuilders = {
    'レターパックライト': (tracking) =>
        'https://trackings.post.japanpost.jp/services/srv/search/?requestNo=$tracking',
    '日本郵便': (tracking) =>
        'https://trackings.post.japanpost.jp/services/srv/search/?requestNo=$tracking',
  };

  static String? urlFor(String carrier, String? trackingNumber) {
    if (trackingNumber == null || trackingNumber.trim().isEmpty) return null;
    final builder = _urlBuilders[carrier];
    if (builder == null) return null;
    return builder(trackingNumber.trim());
  }
}
