import 'package:equatable/equatable.dart';

/// 내부 발주·해제·예약 취소 결과 (FEATURE_2609_75 / PLAN §4-3).
///
/// 백엔드 `InternalStageResult` record 와 1:1. 쿠팡에 보내지 않는 작업이라 실패 사유 목록이 없다.
/// 목록은 **주문번호 단위**다.
class InternalStageResult extends Equatable {
  /// 조회에 성공한 라인 수.
  final int requestedLines;

  /// 단계를 바꾼 배송건(박스) 수.
  final int changedShipments;

  /// 대상이 아니라 건너뛴 주문번호.
  final List<String> skippedOrderIds;

  /// 비-쿠팡이거나 박스가 없어 처리할 수 없는 주문번호.
  final List<String> unsupported;

  const InternalStageResult({
    required this.requestedLines,
    required this.changedShipments,
    required this.skippedOrderIds,
    required this.unsupported,
  });

  factory InternalStageResult.fromJson(Map<String, dynamic> json) =>
      InternalStageResult(
        requestedLines: json['requestedLines'] as int? ?? 0,
        changedShipments: json['changedShipments'] as int? ?? 0,
        skippedOrderIds: (json['skippedOrderIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        unsupported:
            (json['unsupported'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
      );

  @override
  List<Object?> get props =>
      [requestedLines, changedShipments, skippedOrderIds, unsupported];
}
