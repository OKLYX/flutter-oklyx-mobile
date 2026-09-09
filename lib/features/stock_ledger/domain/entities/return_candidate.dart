/// 반품 입고 대기 클레임 1건 — `RETURN_IN` 이 참조할 반품 건 (PLAN 2609_28 04 Step 6-2).
///
/// 🔴 수거 상태로 거르지 않는다 — 상태 매핑이 실계정 검증 전이라 화이트리스트가 틀리면
/// 실제로 돌아온 물건을 입고하지 못한다. 상태는 보여주고 판단은 사람이 한다.
/// ⚠️ [orderLineId] 가 null 이면 주문 미매칭 건이라 판매자를 유도할 수 없다 —
/// 그때는 화면이 판매자를 함께 보내야 한다.
class ReturnCandidate {
  final int orderClaimId;
  final int? orderLineId;
  final String itemName;
  final String? externalOrderId;
  final int claimQty;
  final int receivedQty;
  final int remainingQty;
  final String? claimStatus;
  final String? collectStatus;
  final String? receivedAt;

  const ReturnCandidate({
    required this.orderClaimId,
    this.orderLineId,
    required this.itemName,
    this.externalOrderId,
    required this.claimQty,
    required this.receivedQty,
    required this.remainingQty,
    this.claimStatus,
    this.collectStatus,
    this.receivedAt,
  });
}
