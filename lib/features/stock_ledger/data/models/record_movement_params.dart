import '../../domain/entities/stock_enums.dart';

/// `POST /api/admin/stock/movements` 요청 본문 (PLAN 2609_28 D5~D10).
///
/// ⚠️ null 키는 **아예 생략**한다 — 서버는 유형별로 "참조가 있으면 400" 규칙을 갖고 있어
/// null 을 실어 보내는 것과 안 보내는 것이 다르게 취급될 수 있다(구매목록 params 와 같은 관례).
/// ⚠️ [quantity] 는 양수로 보낸다. 폐기 부호는 서버가 뒤집고, 조정만 음수를 그대로 쓴다.
class RecordMovementParams {
  final int productId;
  final int? sellerId;
  final StockMovementType movementType;
  final int quantity;
  final StockReason? reason;
  final String? reasonNote;
  final double? unitPrice;
  final int? orderClaimId;
  final int? purchaseRecordId;

  /// YYYY-MM-DD
  final String movedOn;

  const RecordMovementParams({
    required this.productId,
    this.sellerId,
    required this.movementType,
    required this.quantity,
    this.reason,
    this.reasonNote,
    this.unitPrice,
    this.orderClaimId,
    this.purchaseRecordId,
    required this.movedOn,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        if (sellerId != null) 'sellerId': sellerId,
        'movementType': movementType.code,
        'quantity': quantity,
        if (reason != null) 'reason': reason!.code,
        if (reasonNote != null && reasonNote!.trim().isNotEmpty)
          'reasonNote': reasonNote!.trim(),
        if (unitPrice != null) 'unitPrice': unitPrice,
        if (orderClaimId != null) 'orderClaimId': orderClaimId,
        if (purchaseRecordId != null) 'purchaseRecordId': purchaseRecordId,
        'movedOn': movedOn,
      };
}
