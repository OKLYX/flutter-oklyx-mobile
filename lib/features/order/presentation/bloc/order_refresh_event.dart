import 'package:equatable/equatable.dart';

abstract class OrderRefreshEvent extends Equatable {
  const OrderRefreshEvent();

  @override
  List<Object?> get props => [];
}

/// 주문 최신화 요청. 라인 id 만 보낸다 — 주문번호 dedupe·계정 판정은 서버가 한다(D1).
///
/// ⚠️ 화면 진입·동기화 완료 같은 시점에 자동으로 발행하지 말 것 —
/// 쿠팡 단건 조회를 주문 수만큼 쓴다(호출 예산, FEATURE_2609_46).
class RefreshRequested extends OrderRefreshEvent {
  /// order_item PK 목록. 개별 최신화는 길이 1 이다(선택 최신화와 같은 엔드포인트, D6).
  final List<int> orderItemIds;

  const RefreshRequested(this.orderItemIds);

  @override
  List<Object?> get props => [orderItemIds];
}

/// 직전 결과·에러를 지운다(화면이 결과를 소비한 뒤).
class RefreshResultCleared extends OrderRefreshEvent {
  const RefreshResultCleared();
}
