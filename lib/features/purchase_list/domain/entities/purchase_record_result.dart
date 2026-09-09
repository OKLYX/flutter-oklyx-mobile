/// 입고 1회의 결과 (PLAN 2609_29 D1·D17·D19).
///
/// ⚠️ [stockRecorded] == false 는 두 가지 뜻이다 — 음수 정정(D17) 또는
/// `recordStock=false`(D19). 화면 문구가 같으므로 사유를 나누지 않는다.
class PurchaseRecordResult {
  final int purchaseRecordId;
  final bool stockRecorded;

  PurchaseRecordResult({
    required this.purchaseRecordId,
    required this.stockRecorded,
  });
}
