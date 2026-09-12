/// 문의만 다시 가져오기 결과 1건 — `POST /api/inquiries/sync?accountId=` (PLAN M4).
///
/// **용도**: 채널 1개분 적재 결과. 목록 화면이 채널을 순회하며 합계를 만들어 SnackBar 에 쓴다.
/// **파일**: lib/features/inquiry/domain/entities/inquiry_sync_result.dart
///
/// ⚠️ 주문 동기화 결과(`OrderSyncResult`)와 합치지 말 것 — 서버도 응답을 분리해 뒀다.
class InquirySyncResult {
  final int? accountId;

  /// 이번에 가져와 저장한 문의 건수(이미 있던 건을 다시 읽은 것도 포함).
  final int fetched;

  /// 오래 방치돼 이번 회차에 자동 종결한 미답변 문의 건수.
  final int staleClosed;

  final DateTime? syncedAt;

  const InquirySyncResult({
    required this.fetched,
    required this.staleClosed,
    this.accountId,
    this.syncedAt,
  });
}
