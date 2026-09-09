/// 입고 1회 요청 본문 (PLAN 2609_29 D1·D3).
///
/// 🔴 주문 라인(itemId)이 아니라 **물품 × 판매자**에 붙는다 — 입고는 "이 주문 몫"이
/// 아니라 "이 판매자가 이만큼 들였다"이다.
class RecordPurchaseParams {
  final int productId;
  final int sellerId;
  final String purchasedOn; // YYYY-MM-DD
  final int quantity; // negative allowed for corrections
  final double? totalAmount; // total mode only
  final double? unitPrice; // unit mode only
  final bool reflectToBasePrice;

  /// 재고 즉시 반영 (PLAN 2609_29 D19) — 화면 체크박스는 체크 + 비활성이라
  /// 현재는 **항상 true** 로 전송한다. 계약만 미리 세우고 스위치는 잠근 상태다.
  final bool recordStock;

  RecordPurchaseParams({
    required this.productId,
    required this.sellerId,
    required this.purchasedOn,
    required this.quantity,
    this.totalAmount,
    this.unitPrice,
    this.reflectToBasePrice = true,
    this.recordStock = true,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'sellerId': sellerId,
        'purchasedOn': purchasedOn,
        'quantity': quantity,
        // Send exactly one of the two, and omit the key entirely when unknown —
        // the server rejects both-present with 400, and a null amount would be
        // read as "no amount" anyway (PLAN 2609_28 D1).
        if (totalAmount != null) 'totalAmount': totalAmount,
        if (unitPrice != null) 'unitPrice': unitPrice,
        'reflectToBasePrice': reflectToBasePrice,
        'recordStock': recordStock,
      };
}
