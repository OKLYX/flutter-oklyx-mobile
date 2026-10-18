/// A single purchase transaction (one check-in) recorded against a product.
///
/// 🔴 Recent purchases come for every seller unless the history box filters one
/// (PLAN 2609_29 D9 · FEATURE_2610_09 D7 · D25) — [sellerName] shows whose each
/// row is.
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
