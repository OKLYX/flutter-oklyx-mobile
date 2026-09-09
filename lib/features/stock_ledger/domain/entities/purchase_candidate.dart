/// 입고 대기 구매 1건 — `STOCK_IN + 매입` 이 참조할 구매기록 (PLAN 2609_28 04 Step 6-1).
///
/// ⚠️ [unitPrice] 는 null 일 수 있다("금액 미상") — 영수증보다 물건이 먼저 올 수 있다.
/// ⚠️ 구매목록 [입고] 한 번이 두 원장에 함께 쓰이므로(2609_29 D1) 이 목록은 정상적으로 비어 있을 수 있다.
class PurchaseCandidate {
  final int purchaseRecordId;
  final int productId;
  final String productName;
  final String sellerName;

  /// YYYY-MM-DD
  final String purchasedOn;
  final int purchasedQty;
  final int receivedQty;
  final int remainingQty;
  final double? unitPrice;

  const PurchaseCandidate({
    required this.purchaseRecordId,
    required this.productId,
    required this.productName,
    required this.sellerName,
    required this.purchasedOn,
    required this.purchasedQty,
    required this.receivedQty,
    required this.remainingQty,
    this.unitPrice,
  });
}
