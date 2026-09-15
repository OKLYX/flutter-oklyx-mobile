/// 알림 배지 상태 (FEATURE_2609_49 / D9).
///
/// 🔴 **이 저장소의 `abstract class XState` + 하위 클래스(Initial/Loading/Error/Loaded)
/// 관례를 일부러 따르지 않는다.** 배지는 조회에 실패해도 직전 값을 유지해야 하는데, 상태를
/// 쪼개면 실패가 곧 숫자 소멸이 된다(Drawer 를 열 때마다 0 으로 깜빡인다).
/// 같은 판단의 선례가 이미 있다 — `InquiryListLoaded.isSearching`.
/// **관례로 되돌리지 말 것.**
class AlertSummaryState {
  /// 미완결 클레임 수. 조회 실패 시 직전 값이 그대로 남는다.
  final int openClaims;

  /// 미답변 고객문의 수. 조회 실패 시 직전 값이 그대로 남는다.
  final int unansweredInquiries;

  /// 조회 중 여부. 배지는 스피너를 그리지 않는다 — 디버깅·중복 호출 방지용이다.
  final bool isLoading;

  const AlertSummaryState({
    this.openClaims = 0,
    this.unansweredInquiries = 0,
    this.isLoading = false,
  });

  /// 주문관리 그룹 헤더(접혀 있을 때)의 합계.
  int get total => openClaims + unansweredInquiries;

  AlertSummaryState copyWith({
    int? openClaims,
    int? unansweredInquiries,
    bool? isLoading,
  }) =>
      AlertSummaryState(
        openClaims: openClaims ?? this.openClaims,
        unansweredInquiries: unansweredInquiries ?? this.unansweredInquiries,
        isLoading: isLoading ?? this.isLoading,
      );
}
