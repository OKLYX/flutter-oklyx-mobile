import 'package:equatable/equatable.dart';

import '../../data/models/cancel_reason_option.dart';
import '../../data/models/order_cancel_result.dart';

/// 발송 전 주문 취소 상태 (사유 목록 + 전송).
///
/// 사유·수량 입력값은 여기 두지 않는다 — 화면 로컬 state 다(발주처리·발송처리와 같은 판단).
/// 이 상태가 아는 것은 "사유 목록 / 보내는 중 / 결과 / 실패"뿐이다.
///
/// - [result] 는 서버가 응답을 준 경우다. **부분 실패도 여기로 온다** —
///   성공 판정은 `result != null` 이 아니라 `result.cancelled.isNotEmpty` 다(D16).
/// - [forbidden] 은 403(ADMIN 아님) → 화면이 섹션을 숨긴다. **사유 조회 403 도 같은 플래그**다.
/// - [reasonsFailed] 는 403 이 아닌 실패다 — 임의의 기본 사유를 채우지 않고
///   [다시 시도] 버튼을 띄운다(D4).
class OrderCancelState extends Equatable {
  final List<CancelReasonOption> reasons;
  final bool loadingReasons;
  final bool reasonsFailed;
  final bool submitting;
  final OrderCancelResult? result;

  /// 요청 자체가 실패했을 때의 사용자 문구. 쿠팡이 거절한 건은 [result] 의 failed 로 간다.
  final String? errorMessage;
  final bool forbidden;

  const OrderCancelState({
    required this.reasons,
    required this.loadingReasons,
    required this.reasonsFailed,
    required this.submitting,
    required this.result,
    required this.errorMessage,
    required this.forbidden,
  });

  const OrderCancelState.initial()
      : reasons = const [],
        loadingReasons = false,
        reasonsFailed = false,
        submitting = false,
        result = null,
        errorMessage = null,
        forbidden = false;

  /// ⚠️ nullable 필드를 비우는 건 **불리언 플래그**로만 한다 — `errorMessage: null` 을 넘기면
  /// `?? this.errorMessage` 로 기존 값이 승계된다(형제 BLoC 과 같은 규격).
  OrderCancelState copyWith({
    List<CancelReasonOption>? reasons,
    bool? loadingReasons,
    bool? reasonsFailed,
    bool? submitting,
    OrderCancelResult? result,
    String? errorMessage,
    bool? forbidden,
    bool clearResult = false,
    bool clearError = false,
  }) =>
      OrderCancelState(
        reasons: reasons ?? this.reasons,
        loadingReasons: loadingReasons ?? this.loadingReasons,
        reasonsFailed: reasonsFailed ?? this.reasonsFailed,
        submitting: submitting ?? this.submitting,
        result: clearResult ? null : (result ?? this.result),
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        forbidden: forbidden ?? this.forbidden,
      );

  @override
  List<Object?> get props => [
        reasons,
        loadingReasons,
        reasonsFailed,
        submitting,
        result,
        errorMessage,
        forbidden,
      ];
}
