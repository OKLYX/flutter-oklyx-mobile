import 'package:equatable/equatable.dart';

/// 발송 전 주문 취소 결과 (POST /api/admin/orders/cancel).
///
/// 백엔드 `OrderCancelResult` record 와 1:1. 실패 사유는 쿠팡 원문 그대로 담는다
/// (PLAN 2609_25 D16) — 취소 불가 상태로 거절되면 200 + [failed] 로 온다.
///
/// ⚠️ 목록 4종이 **전부 라인 단위**다(D20) — 발주처리와 달리 `shipping_label` 의
/// `SkippedOrder` 를 재사용하지 않는다. 요청이 `lines` 배열이라 결과가 주문번호 단위면
/// 어느 라인이 걸러졌는지 화면이 맞출 수 없다.
class OrderCancelResult extends Equatable {
  /// 조회에 성공한 라인 수 (없는 id 는 세지 않는다).
  final int requestedLines;

  /// 취소에 성공한 라인 수.
  final int succeededLines;

  /// 취소에 성공한 수량 합.
  final int succeededQty;

  /// 성공 라인 상세 — 화면 즉시 갱신용(D14).
  final List<CancelledLine> cancelled;

  /// 실패 라인 상세 — 쿠팡 원문(D16).
  final List<FailedLine> failed;

  /// 상태·전량취소로 전송하지 않은 라인(D2).
  final List<SkippedLine> skipped;

  /// 비-COUPANG 이거나 박스번호가 없어 전송 불가한 라인(D10). [skipped] 와 같은 타입이다.
  final List<SkippedLine> unsupported;

  const OrderCancelResult({
    required this.requestedLines,
    required this.succeededLines,
    required this.succeededQty,
    required this.cancelled,
    required this.failed,
    required this.skipped,
    required this.unsupported,
  });

  factory OrderCancelResult.fromJson(Map<String, dynamic> json) =>
      OrderCancelResult(
        requestedLines: json['requestedLines'] as int? ?? 0,
        succeededLines: json['succeededLines'] as int? ?? 0,
        succeededQty: json['succeededQty'] as int? ?? 0,
        cancelled: (json['cancelled'] as List?)
                ?.map((e) => CancelledLine.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        failed: (json['failed'] as List?)
                ?.map((e) => FailedLine.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        skipped: (json['skipped'] as List?)
                ?.map((e) => SkippedLine.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        unsupported: (json['unsupported'] as List?)
                ?.map((e) => SkippedLine.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  @override
  List<Object?> get props => [
        requestedLines,
        succeededLines,
        succeededQty,
        cancelled,
        failed,
        skipped,
        unsupported,
      ];
}

/// 취소에 성공한 라인 1건.
///
/// ⚠️ **수량 필드가 둘이다** — `receiptType` 이 `CANCEL`(결제완료 즉시취소)이면
/// [resultCancelCount] 가, `STOP_SHIPMENT`(상품준비중 출고중지)면
/// [resultHoldCount] 가 는다(D7). 하나만 파싱하면 상품준비중 취소가 화면에 반영되지 않는다.
class CancelledLine extends Equatable {
  final int orderItemId;
  final int cancelledQty;
  final int resultCancelCount;
  final int resultHoldCount;

  /// 취소 후 남은 취소 가능 수량 = orderCount − (cancel + hold).
  final int resultPurchasableQty;

  /// 전량취소면 `CANCELLED`, 아니면 기존 status(취소해도 마켓 status 는 그대로다).
  final String resultStatus;

  /// 쿠팡 접수번호.
  final String? receiptId;

  /// `CANCEL`(즉시취소) / `STOP_SHIPMENT`(출고중지).
  final String? receiptType;

  const CancelledLine({
    required this.orderItemId,
    required this.cancelledQty,
    required this.resultCancelCount,
    required this.resultHoldCount,
    required this.resultPurchasableQty,
    required this.resultStatus,
    this.receiptId,
    this.receiptType,
  });

  factory CancelledLine.fromJson(Map<String, dynamic> json) => CancelledLine(
        orderItemId: json['orderItemId'] as int? ?? 0,
        cancelledQty: json['cancelledQty'] as int? ?? 0,
        resultCancelCount: json['resultCancelCount'] as int? ?? 0,
        resultHoldCount: json['resultHoldCount'] as int? ?? 0,
        resultPurchasableQty: json['resultPurchasableQty'] as int? ?? 0,
        resultStatus: json['resultStatus']?.toString() ?? '',
        receiptId: json['receiptId']?.toString(),
        receiptType: json['receiptType']?.toString(),
      );

  @override
  List<Object?> get props => [
        orderItemId,
        cancelledQty,
        resultCancelCount,
        resultHoldCount,
        resultPurchasableQty,
        resultStatus,
        receiptId,
        receiptType,
      ];
}

/// 취소에 실패한 라인 1건 — 쿠팡 원문 그대로(번역·요약 금지, D16).
class FailedLine extends Equatable {
  final int orderItemId;
  final String? externalItemId;
  final String? code;
  final String? message;

  const FailedLine({
    required this.orderItemId,
    this.externalItemId,
    this.code,
    this.message,
  });

  factory FailedLine.fromJson(Map<String, dynamic> json) => FailedLine(
        orderItemId: json['orderItemId'] as int? ?? 0,
        externalItemId: json['externalItemId']?.toString(),
        code: json['code']?.toString(),
        message: json['message']?.toString(),
      );

  @override
  List<Object?> get props => [orderItemId, externalItemId, code, message];
}

/// 전송하지 않은 라인 1건 — `skipped`(상태·전량취소)와 `unsupported`(비-쿠팡·박스 없음)가
/// **같은 타입**이다. [reason] 은 서버가 준 한글 1줄이며 화면은 그 원문을 그대로 쓴다.
class SkippedLine extends Equatable {
  final int orderItemId;
  final String? externalOrderId;
  final String? status;
  final String? reason;

  const SkippedLine({
    required this.orderItemId,
    this.externalOrderId,
    this.status,
    this.reason,
  });

  factory SkippedLine.fromJson(Map<String, dynamic> json) => SkippedLine(
        orderItemId: json['orderItemId'] as int? ?? 0,
        externalOrderId: json['externalOrderId']?.toString(),
        status: json['status']?.toString(),
        reason: json['reason']?.toString(),
      );

  @override
  List<Object?> get props => [orderItemId, externalOrderId, status, reason];
}
