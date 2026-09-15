import 'package:equatable/equatable.dart';

import '../../data/models/order_refresh_result.dart';

/// 주문 최신화 전송 상태 (FEATURE_2609_50).
///
/// **선택 상태는 여기 없다** — 화면 로컬 state 다(D19). 이 상태가 아는 것은
/// "보내는 중 / 결과 / 실패"뿐이다.
///
/// 🔴 `forbidden` 필드가 **없다**(D18) — 발주처리 BLoC 의 403 게이트는 그 엔드포인트가
/// ADMIN 전용이라 있는 것이다. 최신화는 인증만 필요하다(D2).
///
/// - [result] 는 서버가 응답을 준 경우다. **부분 실패도 여기로 온다** —
///   성공 판정은 `result != null` 이 아니라 `result.refreshed > 0` 이다.
class OrderRefreshState extends Equatable {
  final bool submitting;
  final OrderRefreshResult? result;

  /// 요청 자체가 실패했을 때의 사용자 문구. 주문별 실패는 [result] 의 failed 로 간다.
  final String? errorMessage;

  const OrderRefreshState({
    required this.submitting,
    required this.result,
    required this.errorMessage,
  });

  const OrderRefreshState.initial()
      : submitting = false,
        result = null,
        errorMessage = null;

  /// ⚠️ nullable 필드를 비우는 건 **불리언 플래그**로만 한다 — `errorMessage: null` 을 넘기면
  /// `?? this.errorMessage` 로 기존 값이 승계된다(OrderAcknowledgeState 의 같은 함정).
  OrderRefreshState copyWith({
    bool? submitting,
    OrderRefreshResult? result,
    String? errorMessage,
    bool clearResult = false,
    bool clearError = false,
  }) =>
      OrderRefreshState(
        submitting: submitting ?? this.submitting,
        result: clearResult ? null : (result ?? this.result),
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [submitting, result, errorMessage];
}
