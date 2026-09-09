/// A single purchase transaction (입고 1건) recorded against a product.
///
/// 🔴 판매자 무관 조회다 (PLAN 2609_29 D9) — 물품 기준 최근 구매이력에 여러 판매자
/// 건이 섞여 나오므로 [sellerName] 으로 각 줄이 누구 것인지 보여야 한다.
///
/// `quantity` may be negative for corrections.
/// `totalAmount`/`unitPrice` are null for rows recorded before FEATURE_2609_28 —
/// null means "unknown", NOT zero (PLAN 2609_28 D1).
/// The server owns the derivation: whichever of total/unit was submitted, it
/// stores both, so both are non-null together on newer rows.
class PurchaseRecord {
  final int id;
  final String purchasedOn; // YYYY-MM-DD
  final int quantity;
  final double? totalAmount;
  final double? unitPrice;

  /// false = this purchase price stays out of the product base price
  /// (PLAN 2609_28 D3).
  final bool reflectToBasePrice;

  /// 귀속 판매자명 (PLAN 2609_29 D3).
  final String sellerName;

  PurchaseRecord({
    required this.id,
    required this.purchasedOn,
    required this.quantity,
    this.totalAmount,
    this.unitPrice,
    this.reflectToBasePrice = true,
    this.sellerName = '',
  });
}
