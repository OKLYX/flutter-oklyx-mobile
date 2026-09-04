import 'package:equatable/equatable.dart';

import '../../data/models/order_acknowledge_result.dart';

/// 발주처리 전송 상태.
///
/// **선택 상태는 여기 없다** — 화면 로컬 state 다(출고관리 채널 필터와 같은 판단, 2609_15 D3).
/// 이 상태가 아는 것은 "보내는 중 / 결과 / 실패"뿐이다.
///
/// - [result] 는 쿠팡이 응답을 준 경우다. **부분 실패도 여기로 온다** —
///   성공 판정은 `result != null` 이 아니라 `result.succeeded > 0` 이다(D15).
/// - [forbidden] 은 403(ADMIN 아님) → 화면이 진입점을 숨긴다.
class OrderAcknowledgeState extends Equatable {
  final bool submitting;
  final OrderAcknowledgeResult? result;

  /// 요청 자체가 실패했을 때의 사용자 문구. 쿠팡이 거절한 건은 [result] 의 failed 로 간다.
  final String? errorMessage;
  final bool forbidden;

  const OrderAcknowledgeState({
    required this.submitting,
    required this.result,
    required this.errorMessage,
    required this.forbidden,
  });

  const OrderAcknowledgeState.initial()
      : submitting = false,
        result = null,
        errorMessage = null,
        forbidden = false;

  /// ⚠️ nullable 필드를 비우는 건 **불리언 플래그**로만 한다 — `errorMessage: null` 을 넘기면
  /// `?? this.errorMessage` 로 기존 값이 승계된다(ManualShipmentState 의 같은 함정).
  OrderAcknowledgeState copyWith({
    bool? submitting,
    OrderAcknowledgeResult? result,
    String? errorMessage,
    bool? forbidden,
    bool clearResult = false,
    bool clearError = false,
  }) =>
      OrderAcknowledgeState(
        submitting: submitting ?? this.submitting,
        result: clearResult ? null : (result ?? this.result),
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        forbidden: forbidden ?? this.forbidden,
      );

  @override
  List<Object?> get props => [submitting, result, errorMessage, forbidden];
}
