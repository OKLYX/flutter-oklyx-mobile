import 'package:equatable/equatable.dart';

/// One open LotteON cancel request of an order line
/// (GET /api/orders/{orderItemId}/lotteon-cancel-requests,
/// FEATURE_2611_23 / D24 · D71).
///
/// **Purpose**: one row of the order detail's 「취소 요청」 section.
///
/// ⚠️ [reason] is the server-made 「사유 이름 — 사유 글」 (D71) — show it as is;
/// never map reason codes in the app.
/// ⚠️ [requestedAt] is a KST wall-clock string ('yyyy-MM-ddTHH:mm:ss').
class LotteonCancelRequest extends Equatable {
  /// Path key of [취소 승인] · [취소 거부].
  final int id;

  /// The requested quantity — the {n} of the approve confirm (D24).
  final int quantity;
  final String reason;
  final String? requestedAt;

  const LotteonCancelRequest({
    required this.id,
    required this.quantity,
    required this.reason,
    this.requestedAt,
  });

  factory LotteonCancelRequest.fromJson(Map<String, dynamic> json) =>
      LotteonCancelRequest(
        id: (json['id'] as num?)?.toInt() ?? 0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        reason: json['reason']?.toString() ?? '',
        requestedAt: json['requestedAt']?.toString(),
      );

  @override
  List<Object?> get props => [id, quantity, reason, requestedAt];
}
