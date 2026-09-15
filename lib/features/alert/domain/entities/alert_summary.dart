/// 처리 대기 건수 (GET /api/alerts/summary, FEATURE_2609_49 / D9).
///
/// 🔴 배지 숫자는 목록 화면의 행 수와 **일치하지 않는다 — 정상이다.** 서버가 세는 범위는
/// 미완결/미답변 **전부**(타입 무관·기간 무관)이고, 반품/교환·고객문의 화면의 기본값은
/// `반품` 탭 + 최근 2주다. 일치시키려고 배지를 좁히지 말 것.
class AlertSummary {
  /// 미완결 클레임 수(DONE·REJECTED·WITHDRAWN·STALE 이 아닌 것).
  final int openClaims;

  /// 미답변 고객문의 수.
  final int unansweredInquiries;

  const AlertSummary({
    required this.openClaims,
    required this.unansweredInquiries,
  });
}
