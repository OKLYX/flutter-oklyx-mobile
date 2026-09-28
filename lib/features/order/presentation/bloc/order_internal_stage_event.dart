import 'package:equatable/equatable.dart';

import 'order_internal_stage_state.dart';

abstract class OrderInternalStageEvent extends Equatable {
  const OrderInternalStageEvent();

  @override
  List<Object?> get props => [];
}

/// 내부 발주처리·해제 전송(FEATURE_2609_75 / D1·D18). 라인 id 만 보낸다 — 대상 판정은 서버가 한다.
class InternalStageRequested extends OrderInternalStageEvent {
  final InternalStageAction action;
  final List<int> orderItemIds;

  const InternalStageRequested(this.action, this.orderItemIds);

  @override
  List<Object?> get props => [action, orderItemIds];
}

/// 직전 결과·에러를 지운다(화면이 결과를 소비한 뒤).
class InternalStageResultCleared extends OrderInternalStageEvent {
  const InternalStageResultCleared();
}
