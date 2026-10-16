import 'package:equatable/equatable.dart';

import 'package:flutter_oklyn_mobile/features/shipping_label/data/models/shipment_confirm_result.dart';

/// Order-confirmation result (POST /api/admin/orders/acknowledge).
///
/// 1:1 with the backend `OrderAcknowledgeResult` record. Failure reasons hold
/// the marketplace's original text (PLAN 2609_17 D8·D15 · FEATURE_2610_17 /
/// D54) — a box already in preparing comes back as 200 + [failed].
///
/// ⚠️ Do not make new failure / skip types. The backend reuses
/// `ShipmentConfirmResult.FailedBox` / `SkippedOrder` as they are, so mobile
/// imports the shipping_label models too.
class OrderAcknowledgeResult extends Equatable {
  /// 조회에 성공한 라인 수 (없는 id 는 세지 않는다).
  final int requestedLines;

  /// Units actually sent — Coupang boxes (line → externalBoxId dedupe, D1) +
  /// 11st (delivery number, product number) groups (FEATURE_2610_17 / D54).
  final int targetBoxes;

  /// Succeeded units (same counting as [targetBoxes]).
  final int succeeded;

  /// Failed units — the marketplace's resultCode / message as given (D15).
  final List<FailedBox> failed;

  /// 결제완료가 아니라 전송하지 않은 주문(D2). 출고관리 결과 문구에 건수로 표시한다(웹과 같다).
  final List<SkippedOrder> skipped;

  /// Order numbers that cannot be sent: neither COUPANG nor ELEVENST, or no
  /// box id (D10 · FEATURE_2610_17 / D20). Shown as a count in the shipment
  /// page result.
  final List<String> unsupported;

  /// The same send split per marketplace — only marketplaces that had
  /// something to send, order COUPANG → ELEVENST (FEATURE_2610_17 / D57).
  /// The fields above stay the sum of both.
  final List<AcknowledgePlatformResult> byPlatform;

  const OrderAcknowledgeResult({
    required this.requestedLines,
    required this.targetBoxes,
    required this.succeeded,
    required this.failed,
    required this.skipped,
    required this.unsupported,
    this.byPlatform = const [],
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
        byPlatform: (json['byPlatform'] as List?)
                ?.map((e) => AcknowledgePlatformResult.fromJson(
                    e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  @override
  List<Object?> get props => [
        requestedLines,
        targetBoxes,
        succeeded,
        failed,
        skipped,
        unsupported,
        byPlatform,
      ];
}

/// One marketplace's share of an order-confirmation send (FEATURE_2610_17 /
/// D57). [succeeded] counts a Coupang box or an 11st (delivery number, product
/// number) group (D54).
class AcknowledgePlatformResult extends Equatable {
  /// `COUPANG` · `ELEVENST` as the server sends it.
  final String platform;
  final int succeeded;
  final List<FailedBox> failed;

  const AcknowledgePlatformResult({
    required this.platform,
    required this.succeeded,
    required this.failed,
  });

  factory AcknowledgePlatformResult.fromJson(Map<String, dynamic> json) =>
      AcknowledgePlatformResult(
        platform: json['platform']?.toString() ?? '',
        succeeded: json['succeeded'] as int? ?? 0,
        failed: (json['failed'] as List?)
                ?.map((e) => FailedBox.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  @override
  List<Object?> get props => [platform, succeeded, failed];
}
