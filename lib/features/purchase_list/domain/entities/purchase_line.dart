/// One line of the purchase list: either an order-derived line (source "ORDER")
/// or a user-added manual line (source "MANUAL").
///
/// 🔴 A line has no purchased quantity and no purchase history (PLAN 2609_29
/// D7 · D8) — purchase records do not know orders (D3). A line carries its
/// needed quantity and its channel only.
///
/// [sellerId] / [sellerName] are filled on both kinds (FEATURE_2610_09 D17). A
/// manual line keeps [marketplaceAccountId] / [platform] null and is drawn as
/// 「{sellerName}/수동」.
class PurchaseLine {
  final int itemId;
  final int? orderItemId;
  final String source; // "ORDER" | "MANUAL"
  final String? externalOrderId;

  /// 채널(판매자 × 플랫폼) 식별자 — 칩 dedupe 키. 수동 라인은 null.
  final int? marketplaceAccountId;

  /// The seller the line belongs to — order: its account's seller · manual:
  /// the stored seller (FEATURE_2610_09 D16 · D17).
  final int sellerId;
  final String sellerName;
  final String? platform; // "COUPANG" | "NAVER" | ...

  final int autoQty;
  final int manualQty;

  PurchaseLine({
    required this.itemId,
    required this.orderItemId,
    required this.source,
    required this.externalOrderId,
    this.marketplaceAccountId,
    required this.sellerId,
    required this.sellerName,
    this.platform,
    required this.autoQty,
    required this.manualQty,
  });

  bool get isManual => source == 'MANUAL';

  int get neededQty => autoQty + manualQty;
}

/// 플랫폼 코드 → 한글 라벨. 매핑에 없는 코드는 원문 그대로 쓴다
/// (새 플랫폼이 추가돼도 빈칸이 되지 않는다).
const Map<String, String> _platformLabel = {
  'COUPANG': '쿠팡',
  'NAVER': '네이버',
};

/// Channel label SSOT (PLAN 2609_29 D10) — channel = seller × platform.
///
/// 「A상사/쿠팡」. A manual line has no platform → 「A상사/수동」 (FEATURE_2610_09
/// D17).
/// ❌ No label table copy per screen — this function is the only Korean label
/// (the same rule as `getOrderStatusLabel`).
String channelLabel(PurchaseLine line) {
  if (line.platform == null) return '${line.sellerName}/수동';
  return '${line.sellerName}/${_platformLabel[line.platform] ?? line.platform}';
}
