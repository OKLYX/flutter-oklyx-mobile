import 'package:equatable/equatable.dart';

import '../../data/models/internal_stage_result.dart';

/// 내부 단계 작업 종류 — [내부 발주처리](mark) · [내부 발주 해제](release).
enum InternalStageAction { mark, release }

/// 내부 발주처리·해제 전송 상태 (FEATURE_2609_75).
///
/// **선택 상태는 여기 없다** — 화면 로컬 state 다(발주처리 BLoC 과 같은 판단).
/// [submitting] = 지금 보내는 작업(null 이면 없음) · [lastAction] = [result] 가 어느 작업의 결과인지.
class OrderInternalStageState extends Equatable {
  final InternalStageAction? submitting;
  final InternalStageAction? lastAction;
  final InternalStageResult? result;
  final String? errorMessage;
  final bool forbidden;

  const OrderInternalStageState({
    required this.submitting,
    required this.lastAction,
    required this.result,
    required this.errorMessage,
    required this.forbidden,
  });

  const OrderInternalStageState.initial()
      : submitting = null,
        lastAction = null,
        result = null,
        errorMessage = null,
        forbidden = false;

  /// ⚠️ nullable 필드를 비우는 건 **불리언 플래그**로만 한다(발주처리 상태와 같은 함정).
  OrderInternalStageState copyWith({
    InternalStageAction? submitting,
    InternalStageAction? lastAction,
    InternalStageResult? result,
    String? errorMessage,
    bool? forbidden,
    bool clearSubmitting = false,
    bool clearResult = false,
    bool clearError = false,
  }) =>
      OrderInternalStageState(
        submitting: clearSubmitting ? null : (submitting ?? this.submitting),
        lastAction: lastAction ?? this.lastAction,
        result: clearResult ? null : (result ?? this.result),
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        forbidden: forbidden ?? this.forbidden,
      );

  @override
  List<Object?> get props =>
      [submitting, lastAction, result, errorMessage, forbidden];
}
