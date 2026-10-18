/// Result of one check-in (PLAN 2609_29 D1 · D17 · D19 · FEATURE_2610_09 D65).
///
/// ⚠️ [stockRecorded] == false has three causes — a negative correction (D17),
/// `recordStock=false` (D19) or the stock link setting is off (D65). The screen
/// shows its notice only while the stock link is on.
class PurchaseRecordResult {
  final int purchaseRecordId;
  final bool stockRecorded;

  PurchaseRecordResult({
    required this.purchaseRecordId,
    required this.stockRecorded,
  });
}
