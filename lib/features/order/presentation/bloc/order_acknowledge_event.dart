import 'package:equatable/equatable.dart';

abstract class OrderAcknowledgeEvent extends Equatable {
  const OrderAcknowledgeEvent();

  @override
  List<Object?> get props => [];
}

/// 발주처리 전송. 라인 id 만 보낸다 — 박스 dedupe·상태 필터는 서버가 한다(PLAN 2609_17 D1·D2).
///
/// ⚠️ 화면 진입·동기화 완료 같은 시점에 자동으로 발행하지 말 것(D4) —
/// 발주처리는 되돌릴 수 없고, 판매자 판단을 코드가 대신하지 않는다.
class AcknowledgeRequested extends OrderAcknowledgeEvent {
  /// order_item PK 목록. 개별 전송은 길이 1 이다(일괄과 같은 엔드포인트, D6).
  final List<int> orderItemIds;

  const AcknowledgeRequested(this.orderItemIds);

  @override
  List<Object?> get props => [orderItemIds];
}

/// 직전 결과·에러를 지운다(화면이 결과를 소비한 뒤).
class AcknowledgeResultCleared extends OrderAcknowledgeEvent {
  const AcknowledgeResultCleared();
}
