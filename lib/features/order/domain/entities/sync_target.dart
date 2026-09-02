/// 동기화 대상 채널(마켓플레이스 계정) 1건.
///
/// GET /api/orders/sync/targets 응답에 매핑된다. 동기화는 이 목록을 순회하며
/// **계정 단위로** 호출하고, 마지막 동기화 상태([lastSyncStatus])는 목록 상단
/// 배너에 그대로 노출한다.
///
/// ⚠️ 자격증명(vendorId / accessKey / secretKey)은 서버가 내려주지 않는다 —
/// 이 화면은 ADMIN 이 아닌 사용자도 보기 때문. 계정 목록이 필요하다고
/// marketplace_account API 를 쓰면 안 된다(PLAN D2).
class SyncTarget {
  final int accountId;
  final int sellerId;
  final String sellerName;
  final String platform;
  final String? accountAlias;

  /// "SUCCESS" | "PARTIAL" | "FAILED" | null(기록 없음). 서버가 확정한 값.
  final String? lastSyncStatus;
  final String? lastSyncAt;
  final String? lastOrderSyncAt;
  final String? lastCancelSyncAt;

  /// 서버가 확정한 사유 문구. 클라이언트에서 가공하지 않고 그대로 노출한다(PLAN D18).
  final String? lastSyncError;

  const SyncTarget({
    required this.accountId,
    required this.sellerId,
    required this.sellerName,
    required this.platform,
    this.accountAlias,
    this.lastSyncStatus,
    this.lastSyncAt,
    this.lastOrderSyncAt,
    this.lastCancelSyncAt,
    this.lastSyncError,
  });
}
