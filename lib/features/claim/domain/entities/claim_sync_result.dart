/// 반품·교환만 다시 가져오기 결과 1건 — `POST /api/claims/sync?accountId=` (FEATURE_2609_70 / D14).
///
/// **용도**: 채널 1개분 적재 결과. 목록 화면이 채널을 순회하며 결과를 모아 SnackBar 에 쓴다.
/// **파일**: lib/features/claim/domain/entities/claim_sync_result.dart
///
/// 🔴 **건수가 없다.** 클레임 적재 경로가 세는 것은 조회한 페이지뿐이라 서버가 「신규 N건」을
/// 내려주지 않는다(D16) — 화면에서 숫자를 지어내지 말 것.
/// ⚠️ `InquirySyncResult`·`OrderSyncResult` 와 합치지 말 것 — 서버도 응답을 분리해 뒀다.
class ClaimSyncResult {
  final int? accountId;

  /// 같은 채널이 이미 동기화 중이라 마켓을 치지 않고 건너뛴 회차인가(D15).
  /// 🔴 **실패가 아니다** — 화면은 실패와 따로 세어 알린다.
  final bool skipped;

  /// 이 회차의 시각. 건너뛴 회차도 채워진다.
  final DateTime? syncedAt;

  const ClaimSyncResult({
    this.accountId,
    this.skipped = false,
    this.syncedAt,
  });
}
