import 'package:equatable/equatable.dart';

/// [예약 발송] 결과 (POST /api/admin/reserved-shipments, FEATURE_2609_75 / D20·D27).
///
/// 🔴 [executeAt] 은 KST 벽시계 문자열('yyyy-MM-ddTHH:mm:ss')이다 — 시간대 계산을 하지 않는다.
class ReservationCreateResult extends Equatable {
  /// 새 예약 id. 새로 예약한 배송건이 없으면(송장 교체만·전부 제외) null.
  final int? reservationId;
  final String executeAt;

  /// 새로 예약한 배송건 수.
  final int reservedShipments;

  /// 송장만 바꾼 결과 수(D18 송장 수정).
  final int updatedInvoices;

  /// 예약하지 않은 주문 + 서버 사유 원문.
  final List<ExcludedOrder> excluded;

  const ReservationCreateResult({
    required this.reservationId,
    required this.executeAt,
    required this.reservedShipments,
    required this.updatedInvoices,
    required this.excluded,
  });

  factory ReservationCreateResult.fromJson(Map<String, dynamic> json) =>
      ReservationCreateResult(
        reservationId: (json['reservationId'] as num?)?.toInt(),
        executeAt: json['executeAt'] as String? ?? '',
        reservedShipments: json['reservedShipments'] as int? ?? 0,
        updatedInvoices: json['updatedInvoices'] as int? ?? 0,
        excluded: (json['excluded'] as List?)
                ?.map((e) => ExcludedOrder.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  @override
  List<Object?> get props =>
      [reservationId, executeAt, reservedShipments, updatedInvoices, excluded];
}

/// 예약 제외 주문 1건. [reason] 은 서버 문구 그대로 보여준다.
class ExcludedOrder extends Equatable {
  final String orderId;
  final String reason;

  const ExcludedOrder({required this.orderId, required this.reason});

  factory ExcludedOrder.fromJson(Map<String, dynamic> json) => ExcludedOrder(
        orderId: json['orderId'] as String? ?? '',
        reason: json['reason'] as String? ?? '',
      );

  @override
  List<Object?> get props => [orderId, reason];
}
