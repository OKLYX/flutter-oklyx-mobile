import 'package:equatable/equatable.dart';

import 'package:flutter_oklyn_mobile/features/shipping_label/data/models/shipment_confirm_result.dart';

/// 발주처리 결과 (POST /api/admin/orders/acknowledge).
///
/// 백엔드 `OrderAcknowledgeResult` record 와 1:1. 실패 사유는 쿠팡 원문 그대로 담는다
/// (PLAN 2609_17 D8·D15) — 이미 상품준비중인 박스를 보내면 200 + [failed] 로 온다.
///
/// ⚠️ 실패·스킵 타입을 새로 만들지 않는다. 백엔드가 `ShipmentConfirmResult.FailedBox`/
/// `SkippedOrder` 를 그대로 재사용하므로 모바일도 shipping_label 모델을 import 한다.
class OrderAcknowledgeResult extends Equatable {
  /// 조회에 성공한 라인 수 (없는 id 는 세지 않는다).
  final int requestedLines;

  /// 실제 전송한 박스 수 (라인 → externalBoxId dedupe, D1).
  final int targetBoxes;

  /// 성공 박스 수.
  final int succeeded;

  /// 실패 박스 상세 — 쿠팡 resultCode/resultMessage 원문(D15).
  final List<FailedBox> failed;

  /// 결제완료가 아니라 전송하지 않은 주문(D2). 파싱만 한다 —
  /// 화면에 표시하지 않는다(체크박스가 이미 결제완료만 고르게 막는다).
  final List<SkippedOrder> skipped;

  /// 비-COUPANG 이거나 박스 ID 가 없어 전송 불가한 주문번호(D10). 파싱만 하고 표시하지 않는다.
  final List<String> unsupported;

  const OrderAcknowledgeResult({
    required this.requestedLines,
    required this.targetBoxes,
    required this.succeeded,
    required this.failed,
    required this.skipped,
    required this.unsupported,
  });

  factory OrderAcknowledgeResult.fromJson(Map<String, dynamic> json) =>
      OrderAcknowledgeResult(
        requestedLines: json['requestedLines'] as int? ?? 0,
        targetBoxes: json['targetBoxes'] as int? ?? 0,
        succeeded: json['succeeded'] as int? ?? 0,
        failed: (json['failed'] as List?)
                ?.map((e) => FailedBox.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        skipped: (json['skipped'] as List?)
                ?.map((e) => SkippedOrder.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        unsupported:
            (json['unsupported'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
      );

  @override
  List<Object?> get props =>
      [requestedLines, targetBoxes, succeeded, failed, skipped, unsupported];
}
