import '../../domain/entities/stock_enums.dart';
import '../../domain/entities/stock_movement.dart';

class StockMovementModel extends StockMovement {
  const StockMovementModel({
    required super.id,
    required super.productId,
    required super.productName,
    required super.sellerId,
    required super.sellerName,
    required super.movementType,
    required super.quantity,
    super.reason,
    super.reasonNote,
    super.unitPrice,
    super.orderLineId,
    super.orderClaimId,
    super.purchaseRecordId,
    required super.movedOn,
    super.createdBy,
  });

  factory StockMovementModel.fromJson(Map<String, dynamic> json) {
    return StockMovementModel(
      id: json['id'] as int,
      productId: json['productId'] as int,
      productName: json['productName'] as String? ?? '',
      sellerId: json['sellerId'] as int? ?? 0,
      sellerName: json['sellerName'] as String? ?? '',
      // 모르는 코드는 null 로 둔다 — 임의 유형으로 바꾸면 부호 해석이 틀어진다.
      movementType: StockMovementType.fromCode(json['movementType'] as String?),
      // 저장된 부호 그대로다(폐기·출고는 음수).
      quantity: json['quantity'] as int,
      reason: StockReason.fromCode(json['reason'] as String?),
      reasonNote: json['reasonNote'] as String?,
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
      orderLineId: json['orderLineId'] as int?,
      orderClaimId: json['orderClaimId'] as int?,
      purchaseRecordId: json['purchaseRecordId'] as int?,
      movedOn: json['movedOn'] as String? ?? '',
      createdBy: json['createdBy'] as String?,
    );
  }
}
