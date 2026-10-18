/// A single purchase transaction (one check-in) recorded against a product.
///
/// 🔴 Recent purchases come for every seller unless the history box filters one
/// (PLAN 2609_29 D9 · FEATURE_2610_09 D7 · D25) — [sellerName] shows whose each
/// row is.
///
/// `quantity` may be negative for corrections.
/// `totalAmount`/`unitPrice` are null when the amount was not entered
/// (FEATURE_2610_18 D68 「미기입」) or the row predates FEATURE_2609_28 —
/// never zero (PLAN 2609_28 D1).
/// The server owns the derivation: whichever of total/unit was submitted, it
/// stores both, so both are non-null together on rows with an amount.
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

  /// Set = the purchase came in with a receipt → [영수증] (FEATURE_2610_18
  /// D93 ①). null = per-product check-in.
  final int? receiptId;

  PurchaseRecord({
    required this.id,
    required this.purchasedOn,
    required this.quantity,
    this.totalAmount,
    this.unitPrice,
    this.reflectToBasePrice = true,
    this.sellerName = '',
    this.receiptId,
  });
}
