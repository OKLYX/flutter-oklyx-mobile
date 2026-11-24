import 'stock_enums.dart';

/// FEATURE_2611_34 stock work request lines.
///
/// One line sent by the 「출고 작업」 save (`POST /api/admin/stock/
/// outbound-work`). [quantity] is positive — the server flips the sign.
/// [reasonNote] is set only for [StockReason.etc] (R25).
class OutboundWorkLineRequest {
  final int productId;
  final int sellerId;
  final StockReason reason;
  final String? reasonNote;
  final int quantity;

  const OutboundWorkLineRequest({
    required this.productId,
    required this.sellerId,
    required this.reason,
    required this.quantity,
    this.reasonNote,
  });
}
