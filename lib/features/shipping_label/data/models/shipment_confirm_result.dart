import 'package:equatable/equatable.dart';

/// 송장업로드 실패 박스 상세 (백엔드 FailedBox 대응).
class FailedBox extends Equatable {
  final String shipmentBoxId;
  final String resultCode;
  final String message;

  const FailedBox({
    required this.shipmentBoxId,
    required this.resultCode,
    required this.message,
  });

  factory FailedBox.fromJson(Map<String, dynamic> json) => FailedBox(
        shipmentBoxId: json['shipmentBoxId']?.toString() ?? '',
        resultCode: json['resultCode']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
      );

  @override
  List<Object?> get props => [shipmentBoxId, resultCode, message];
}

/// 전송 제외 주문 (백엔드 SkippedOrder 대응).
///
/// [status] 는 판정에 쓴 쿠팡 코드 원문(예: DEPARTURE) — 한글 라벨 변환은 화면 몫이다.
class SkippedOrder extends Equatable {
  final String orderId;
  final String status;

  const SkippedOrder({required this.orderId, required this.status});

  factory SkippedOrder.fromJson(Map<String, dynamic> json) => SkippedOrder(
        orderId: json['orderId']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
      );

  @override
  List<Object?> get props => [orderId, status];
}

/// 발송처리(운송장 업로드) 결과 (백엔드 ShipmentConfirmResult 대응).
class ShipmentConfirmResult extends Equatable {
  final int totalRows;
  final int matchedOrders;
  final List<String> unmatched;
  final int succeeded;
  final List<FailedBox> failed;
  final List<SkippedOrder> skipped;

  const ShipmentConfirmResult({
    required this.totalRows,
    required this.matchedOrders,
    required this.unmatched,
    required this.succeeded,
    required this.failed,
    // 구버전 백엔드 응답(필드 없음)에서도 터지지 않도록 기본값을 둔다.
    this.skipped = const [],
  });

  factory ShipmentConfirmResult.fromJson(Map<String, dynamic> json) =>
      ShipmentConfirmResult(
        totalRows: json['totalRows'] as int? ?? 0,
        matchedOrders: json['matchedOrders'] as int? ?? 0,
        unmatched: (json['unmatched'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        succeeded: json['succeeded'] as int? ?? 0,
        failed: (json['failed'] as List?)
                ?.map((e) => FailedBox.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        skipped: (json['skipped'] as List?)
                ?.map((e) => SkippedOrder.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  @override
  List<Object?> get props =>
      [totalRows, matchedOrders, unmatched, succeeded, failed, skipped];
}
