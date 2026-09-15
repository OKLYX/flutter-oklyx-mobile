import 'package:equatable/equatable.dart';

/// 주문 상태 갱신 결과 (POST /api/orders/refresh, FEATURE_2609_50 / D6).
///
/// 백엔드 `OrderRefreshResult` record 와 1:1.
///
/// 🔴 모든 목록이 **주문번호 단위**다 — 사용자가 체크한 건 라인이지만 조회·보고 단위는 주문이다(D1).
/// 같은 주문의 옵션 3줄을 체크해도 결과는 1건이다.
class OrderRefreshResult extends Equatable {
  /// dedupe 후 실제 조회를 시도한 주문 수.
  final int requestedOrders;

  /// 박스를 1개 이상 반영한 주문 수 — 성공 판정은 이 값이다.
  final int refreshed;

  /// 쿠팡이 0박스를 돌려준 주문번호 — 전량 취소로 추정(D7). **실패가 아니다.**
  final List<String> empty;

  /// 조회·파싱 실패 주문 (사유 원문 포함).
  final List<FailedOrder> failed;

  /// 비-COUPANG 계정이라 조회할 수 없는 주문번호.
  final List<String> unsupported;

  const OrderRefreshResult({
    required this.requestedOrders,
    required this.refreshed,
    required this.empty,
    required this.failed,
    required this.unsupported,
  });

  factory OrderRefreshResult.fromJson(Map<String, dynamic> json) =>
      OrderRefreshResult(
        requestedOrders: json['requestedOrders'] as int? ?? 0,
        refreshed: json['refreshed'] as int? ?? 0,
        empty: (json['empty'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
        failed: (json['failed'] as List?)
                ?.map((e) => FailedOrder.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        unsupported:
            (json['unsupported'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
      );

  @override
  List<Object?> get props =>
      [requestedOrders, refreshed, empty, failed, unsupported];
}

/// 상태 갱신 실패 1건 — 사유는 서버가 준 원문 그대로 보여준다(고칠 수 있는 정보가 여기 담긴다).
class FailedOrder extends Equatable {
  final String externalOrderId;
  final String reason;

  const FailedOrder({required this.externalOrderId, required this.reason});

  factory FailedOrder.fromJson(Map<String, dynamic> json) => FailedOrder(
        externalOrderId: json['externalOrderId']?.toString() ?? '',
        reason: json['reason']?.toString() ?? '',
      );

  @override
  List<Object?> get props => [externalOrderId, reason];
}
