/// 처리 대기 건수 (GET /api/alerts/summary, FEATURE_2609_49 / D9 · FEATURE_2609_51 / D3·D7).
///
/// 🔴 [openClaims]·[unansweredInquiries] 는 목록 화면의 행 수와 **일치하지 않는다 — 정상이다.**
/// 서버가 세는 범위는 미완결/미답변 **전부**(타입 무관·기간 무관)이고, 반품/교환·고객문의
/// 화면의 기본값은 `반품` 탭 + 최근 2주다. 일치시키려고 배지를 좁히지 말 것.
///
/// 🔴 **숫자 4종은 서로 다른 질문의 답이다 — 맞추려 하지 말 것**(2609_51 D7):
/// | 값 | 세는 단위 | 기간 | 쓰는 자리 |
/// |----|----------|------|----------|
/// | [paidOrders] | 결제완료 **주문** 수 | 없음 | Drawer `출고관리` 배지 |
/// | [newOrders] | 새 **주문** 수 | 최근 14일 | 알림 목록의 새 주문 행 수 |
/// | [todoCount] | 알림 **행** 수 합계 | 목록과 같은 기간 | 바텀네비 종 배지 |
/// | [openClaims]·[unansweredInquiries] | 미완결·미답변 전부 | 없음 | Drawer 반품/교환·고객문의 |
class AlertSummary {
  /// 미완결 클레임 수(DONE·REJECTED·WITHDRAWN·STALE 이 아닌 것).
  final int openClaims;

  /// 미답변 고객문의 수.
  final int unansweredInquiries;

  /// 결제완료 **주문** 수 = `출고관리` 메뉴 배지(2026-09-16 단위 변경). 🔴 [newOrders] 와 같은
  /// 주문 단위지만 기간 상한이 없어, 14일이 지난 결제완료 주문이 있으면 더 크게 나온다(D7·D8).
  final int paidOrders;

  /// 새 주문 알림 건수 = **주문 단위**, 최근 14일(D5·D8).
  final int newOrders;

  /// 종 아이콘 배지 = 알림 목록의 **행 수와 정확히 같다**(D3). 서버가 계산해 준다 —
  /// 🔴 클라이언트가 다른 값들을 더해 만들지 말 것.
  final int todoCount;

  const AlertSummary({
    required this.openClaims,
    required this.unansweredInquiries,
    required this.paidOrders,
    required this.newOrders,
    required this.todoCount,
  });
}
