import 'stock_enums.dart';

/// 실물 재고 원장 1행 (PLAN 2609_28 D5).
///
/// [quantity] 는 **저장된 부호 그대로**다 — 폐기·출고는 음수로 온다.
/// 화면에서 다시 뒤집지 않는다(부호는 서버가 정한다, D6).
class StockMovement {
  final int id;
  final int productId;
  final String productName;

  /// 누구의 재고가 움직였는지 (PLAN 2609_29 D4) — 항상 채워져 온다.
  final int sellerId;
  final String sellerName;

  final StockMovementType? movementType;
  final int quantity;
  final StockReason? reason;
  final String? reasonNote;
  final double? unitPrice;
  final int? orderLineId;
  final int? orderClaimId;
  final int? purchaseRecordId;

  /// YYYY-MM-DD
  final String movedOn;
  final String? createdBy;

  const StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sellerId,
    required this.sellerName,
    required this.movementType,
    required this.quantity,
    this.reason,
    this.reasonNote,
    this.unitPrice,
    this.orderLineId,
    this.orderClaimId,
    this.purchaseRecordId,
    required this.movedOn,
    this.createdBy,
  });
}
