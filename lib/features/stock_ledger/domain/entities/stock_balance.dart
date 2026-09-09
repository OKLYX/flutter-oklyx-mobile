/// (물품 × 판매자) 잔량 — 원장 합계로 유도된 값이다 (PLAN 2609_28 D14 / 2609_29 D5).
///
/// ⚠️ [onHand] 는 음수일 수 있다 = 입고 기록이 빠졌다는 뜻이다.
/// ❌ 화면에서 숨기거나 0 으로 깎지 않는다. 앱에서 다시 더하지도 않는다.
class StockBalance {
  final int productId;
  final String productName;
  final int sellerId;
  final String sellerName;
  final int onHand;

  const StockBalance({
    required this.productId,
    required this.productName,
    required this.sellerId,
    required this.sellerName,
    required this.onHand,
  });
}
