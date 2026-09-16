/// 알림 배지 상태 (FEATURE_2609_49 / D9 · FEATURE_2609_51).
///
/// 🔴 **이 저장소의 `abstract class XState` + 하위 클래스(Initial/Loading/Error/Loaded)
/// 관례를 일부러 따르지 않는다.** 배지는 조회에 실패해도 직전 값을 유지해야 하는데, 상태를
/// 쪼개면 실패가 곧 숫자 소멸이 된다(Drawer 를 열 때마다 0 으로 깜빡인다).
/// 같은 판단의 선례가 이미 있다 — `InquiryListLoaded.isSearching`.
/// **관례로 되돌리지 말 것.** (목록 `AlertFeedBloc` 은 반대로 관례를 따른다 — 목록은 실패하면
/// 실패라고 말해야 한다.)
class AlertSummaryState {
  /// 미완결 클레임 수. 조회 실패 시 직전 값이 그대로 남는다.
  final int openClaims;

  /// 미답변 고객문의 수. 조회 실패 시 직전 값이 그대로 남는다.
  final int unansweredInquiries;

  /// 결제완료 상품(라인) 수 = Drawer `출고관리` 배지(2609_51 D7). 기간 제한이 없다.
  final int paidOrders;

  /// 새 주문(주문 단위, 최근 14일) 건수. 지금은 [todoCount] 안에 포함돼 배지로는 쓰지 않는다.
  final int newOrders;

  /// 바텀네비 종 배지 = 처리해야 할 일 건수(알림 목록의 행 수, D3).
  ///
  /// 🔴 [total] 과 **다른 숫자다** — 주문을 건수로, 그것도 최근 14일만 센다(D7·D8).
  ///    둘을 합치거나 맞추려 하지 말 것.
  final int todoCount;

  /// 조회 중 여부. 배지는 스피너를 그리지 않는다 — 디버깅·중복 호출 방지용이다.
  final bool isLoading;

  const AlertSummaryState({
    this.openClaims = 0,
    this.unansweredInquiries = 0,
    this.paidOrders = 0,
    this.newOrders = 0,
    this.todoCount = 0,
    this.isLoading = false,
  });

  /// 주문관리 그룹 헤더(접혀 있을 때)의 합계 = **항목 배지의 합**이다.
  ///
  /// 🔴 `출고관리` 에 배지(`paidOrders`)가 생겼으므로 여기에도 더한다(2609_51 Step 1) —
  ///    빼면 헤더 숫자가 펼친 항목들의 합보다 작아진다.
  /// 🔴 종 배지([todoCount])와 같아지지 않는다 — 세는 단위와 기간이 다르다(D7).
  int get total => openClaims + unansweredInquiries + paidOrders;

  AlertSummaryState copyWith({
    int? openClaims,
    int? unansweredInquiries,
    int? paidOrders,
    int? newOrders,
    int? todoCount,
    bool? isLoading,
  }) =>
      AlertSummaryState(
        openClaims: openClaims ?? this.openClaims,
        unansweredInquiries: unansweredInquiries ?? this.unansweredInquiries,
        paidOrders: paidOrders ?? this.paidOrders,
        newOrders: newOrders ?? this.newOrders,
        todoCount: todoCount ?? this.todoCount,
        isLoading: isLoading ?? this.isLoading,
      );
}
