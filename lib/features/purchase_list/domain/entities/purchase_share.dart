/// One seller's share of a product on the purchase list (FEATURE_2610_09
/// D2 · D57 · D59 · D80).
///
/// [state] = `OPEN` (to buy) · `SKIPPED_TODAY` (「내일 매입」 today) ·
/// `PURCHASED` (「매입 완료」) · `NOT_NEEDED` (「필요 없음」) · `NEED_ZERO`
/// (「필요 0」). A share whose need has always been 0 is not sent (D80).
class PurchaseShare {
  final int sellerId;
  final String sellerName;
  final int neededQty;
  final int purchasedQty;
  final int remainingQty;

  /// purchasedQty ≥ neededQty — the 「목표 수량 매입 완료」 tag (D57 ①).
  final bool targetMet;
  final String state;

  /// Undo target of SKIPPED_TODAY · PURCHASED · NOT_NEEDED; null otherwise.
  final int? checkId;

  /// Processing day (yyyy-MM-dd) of PURCHASED · NOT_NEEDED · NEED_ZERO.
  final String? checkedOn;

  const PurchaseShare({
    required this.sellerId,
    required this.sellerName,
    required this.neededQty,
    required this.purchasedQty,
    required this.remainingQty,
    required this.targetMet,
    required this.state,
    this.checkId,
    this.checkedOn,
  });
}
