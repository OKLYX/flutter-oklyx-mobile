import 'package:equatable/equatable.dart';

import '../../domain/entities/order_item.dart';

/// Seller cancel result before shipping (POST /api/admin/orders/cancel).
///
/// 1:1 with the backend `OrderCancelResult` record. Failure reasons hold the
/// marketplace's original wording (Coupang PLAN 2609_25 D16 · 11st sale
/// refusal FEATURE_2610_17 / D61) — a refusal comes back as 200 + [failed].
///
/// ⚠️ All four lists are **per line** (D20) — unlike order confirmation, the
/// `shipping_label` `SkippedOrder` is not reused. The request is a `lines`
/// array, so per-order results would not tell the screen which line was left
/// out.
class OrderCancelResult extends Equatable {
  /// 조회에 성공한 라인 수 (없는 id 는 세지 않는다).
  final int requestedLines;

  /// 취소에 성공한 라인 수.
  final int succeededLines;

  /// 취소에 성공한 수량 합.
  final int succeededQty;

  /// 성공 라인 상세 — 화면 즉시 갱신용(D14).
  final List<CancelledLine> cancelled;

  /// Failed line details — the marketplace's original wording (D16 · D61).
  final List<FailedLine> failed;

  /// 상태·전량취소로 전송하지 않은 라인(D2).
  final List<SkippedLine> skipped;

  /// Lines that cannot be sent — neither Coupang nor 11st, or no box number
  /// (D10 · FEATURE_2610_17 / D61). Same type as [skipped].
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

  /// 전량취소면 [OrderStatus.cancelled], 아니면 취소 후의 중립 상태다.
  final OrderStatus resultStatus;

  /// 쿠팡 접수번호.
  final String? receiptId;

  /// Coupang `CANCEL` (instant cancel) / `STOP_SHIPMENT` (shipment stop) ·
  /// 11st `ELEVENST_SALE_REFUSAL` (FEATURE_2610_17 / D61).
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
        resultStatus: orderStatusFrom(json['resultStatus']?.toString()),
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

/// One failed line — the marketplace's original wording as given (never
/// translate or summarize, D16 · D61).
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

/// One line not sent — `skipped` (status · fully cancelled) and `unsupported`
/// (neither Coupang nor 11st · no box) are **the same type**. [reason] is the
/// server's one Korean line and the screen shows it as given.
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
