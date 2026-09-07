import 'package:equatable/equatable.dart';

import 'package:flutter_oklyn_mobile/features/order/domain/entities/order_item.dart';
import 'shipment_confirm_result.dart';

/// 단건 발송처리 결과 (백엔드 ManualShipmentResult 대응).
///
/// [mode] 는 서버가 주문 상태로 정한다(PLAN 2609_11 D3): 'CREATE'(신규 업로드) | 'UPDATE'(송장수정).
/// [resultStatus] 는 CREATE 성공 시 [OrderStatus.shipped], 그 외 null → 상세 화면의 상태 행
/// 갱신에 쓴다(D4).
/// [failed] 는 일괄 발송처리와 같은 [FailedBox] 를 재사용한다(쿠팡 원문 그대로, D6).
class ManualShipmentResult extends Equatable {
  final String orderId;
  final String shipmentBoxId;
  final String mode;
  final int sentLines;
  final int succeeded;
  final List<FailedBox> failed;
  final OrderStatus? resultStatus;

  const ManualShipmentResult({
    required this.orderId,
    required this.shipmentBoxId,
    required this.mode,
    required this.sentLines,
    required this.succeeded,
    required this.failed,
    this.resultStatus,
  });

  factory ManualShipmentResult.fromJson(Map<String, dynamic> json) =>
      ManualShipmentResult(
        orderId: json['orderId']?.toString() ?? '',
        shipmentBoxId: json['shipmentBoxId']?.toString() ?? '',
        mode: json['mode']?.toString() ?? '',
        sentLines: (json['sentLines'] as num?)?.toInt() ?? 0,
        succeeded: (json['succeeded'] as num?)?.toInt() ?? 0,
        failed: (json['failed'] as List? ?? [])
            .map((e) => FailedBox.fromJson(e as Map<String, dynamic>))
            .toList(),
        resultStatus: json['resultStatus'] == null
            ? null
            : orderStatusFrom(json['resultStatus']?.toString()),
      );

  /// 송장 수정 모드 여부 — 성공 배너 문구를 가른다.
  bool get isUpdateMode => mode == 'UPDATE';

  @override
  List<Object?> get props =>
      [orderId, shipmentBoxId, mode, sentLines, succeeded, failed, resultStatus];
}
