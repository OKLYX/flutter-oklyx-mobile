import 'package:equatable/equatable.dart';

abstract class OrderCancelEvent extends Equatable {
  const OrderCancelEvent();

  @override
  List<Object?> get props => [];
}

/// 취소 사유 목록 조회. 섹션(Provider) 생성 시 1회 + [다시 시도] 버튼에서만 발행한다.
/// ⚠️ 실패해도 자동 재시도하지 않는다(PLAN 2609_25 D4).
class CancelReasonsRequested extends OrderCancelEvent {
  const CancelReasonsRequested();
}

/// 취소 전송. 라인×수량 배열 + 사유 코드.
///
/// ⚠️ 화면 진입·동기화 같은 시점에 자동으로 발행하지 말 것(D12) —
/// 취소는 되돌릴 수 없고 쿠팡 판매자 점수가 하락한다.
class CancelRequested extends OrderCancelEvent {
  /// `[{orderItemId, quantity}]` — 주문 상세는 길이 1 이다(계약은 배열, D1).
  final List<Map<String, dynamic>> lines;

  /// 서버가 내려준 사유 `code` (모바일에 라벨 상수를 두지 않는다, D4).
  final String reason;

  const CancelRequested(this.lines, this.reason);

  @override
  List<Object?> get props => [lines, reason];
}

/// 직전 결과·에러를 지운다(화면이 결과를 소비한 뒤).
class CancelResultCleared extends OrderCancelEvent {
  const CancelResultCleared();
}
