/// Result of one check-in (PLAN 2609_29 D1 · D17 · D19 · FEATURE_2610_09 D65).
///
/// ⚠️ [stockRecorded] == false has three causes — a negative correction (D17),
/// `recordStock=false` (D19) or the stock link setting is off (D65). The screen
/// shows its notice only while the stock link is on.
///
/// [lotId] = the stock row written (the 「채울까요?」 sheet asks for it,
/// FEATURE_2611_22 D3 ①); null when [stockRecorded] is false.
class PurchaseRecordResult {
  final int purchaseRecordId;
  final bool stockRecorded;
  final int? lotId;

  PurchaseRecordResult({
    required this.purchaseRecordId,
    required this.stockRecorded,
    required this.lotId,
  });
}
