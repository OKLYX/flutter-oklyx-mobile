import 'package:equatable/equatable.dart';

/// One open 11st cancel request of an order line
/// (GET /api/orders/{orderItemId}/elevenst-cancel-requests,
/// FEATURE_2610_17 / D19 · D40 · D41).
///
/// **Purpose**: one row of the order detail's 「취소 요청」 section.
///
/// ⚠️ [reason] is the server-made 「사유 이름 — 사유 글」 (D41) — show it as is;
/// never map reason codes in the app.
/// ⚠️ [requestedAt] is a KST wall-clock string ('yyyy-MM-ddTHH:mm:ss').
class ElevenstCancelRequest extends Equatable {
  /// Path key of [취소 승인] · [취소 거부].
  final int id;
  final int quantity;
  final String reason;
  final String? requestedAt;

  /// [책임사유 오류로 거부] is shown — the server decides it (a buyer request on
  /// a paid line, FEATURE_2610_17 / D62).
  final bool faultRejectable;

  const ElevenstCancelRequest({
    required this.id,
    required this.quantity,
    required this.reason,
    this.requestedAt,
    this.faultRejectable = false,
  });

  factory ElevenstCancelRequest.fromJson(Map<String, dynamic> json) =>
      ElevenstCancelRequest(
        id: (json['id'] as num?)?.toInt() ?? 0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        reason: json['reason']?.toString() ?? '',
        requestedAt: json['requestedAt']?.toString(),
        faultRejectable: json['faultRejectable'] as bool? ?? false,
      );

  @override
  List<Object?> get props =>
      [id, quantity, reason, requestedAt, faultRejectable];
}
