/// One line of the purchase list: either an order-derived line (source "ORDER")
/// or a user-added manual line (source "MANUAL").
///
/// 🔴 라인에는 구매수량도 구매이력도 없다 (PLAN 2609_29 D7·D8) — 구매기록이 주문을
/// 모르므로(D3) 계산 자체가 불가능하다. 라인은 `필요 수량`과 채널 정보만 갖는다.
///
/// 채널 3필드([marketplaceAccountId]/[sellerName]/[platform])는 수동 라인에서
/// 전부 null 이다 — 화면은 그것을 '수동' 칩으로 그린다.
class PurchaseLine {
  final int itemId;
  final int? orderItemId;
  final String source; // "ORDER" | "MANUAL"
  final String? externalOrderId;

  /// 채널(판매자 × 플랫폼) 식별자 — 칩 dedupe 키. 수동 라인은 null.
  final int? marketplaceAccountId;
  final String? sellerName;
  final String? platform; // "COUPANG" | "NAVER" | ...

  final int autoQty;
  final int manualQty;

  PurchaseLine({
    required this.itemId,
    required this.orderItemId,
    required this.source,
    required this.externalOrderId,
    this.marketplaceAccountId,
    this.sellerName,
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

/// 채널 라벨 SSOT (PLAN 2609_29 D10) — 채널 = 판매자 × 플랫폼.
///
/// `A상사/쿠팡` 형태. 수동 라인은 채널 3필드가 null 이라 `수동`.
/// ❌ 화면마다 라벨표 사본을 두지 말 것 — 한글 라벨은 이 함수 하나뿐이다
/// (`getOrderStatusLabel` 과 같은 규칙).
String channelLabel(PurchaseLine line) {
  if (line.platform == null || line.sellerName == null) return '수동';
  return '${line.sellerName}/${_platformLabel[line.platform] ?? line.platform}';
}
