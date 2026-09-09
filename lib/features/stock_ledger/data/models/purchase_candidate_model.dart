import '../../domain/entities/purchase_candidate.dart';

class PurchaseCandidateModel extends PurchaseCandidate {
  const PurchaseCandidateModel({
    required super.purchaseRecordId,
    required super.productId,
    required super.productName,
    required super.sellerName,
    required super.purchasedOn,
    required super.purchasedQty,
    required super.receivedQty,
    required super.remainingQty,
    super.unitPrice,
  });

  factory PurchaseCandidateModel.fromJson(Map<String, dynamic> json) {
    return PurchaseCandidateModel(
      purchaseRecordId: json['purchaseRecordId'] as int,
      productId: json['productId'] as int,
      productName: json['productName'] as String? ?? '',
      sellerName: json['sellerName'] as String? ?? '',
      purchasedOn: json['purchasedOn'] as String? ?? '',
      purchasedQty: json['purchasedQty'] as int? ?? 0,
      receivedQty: json['receivedQty'] as int? ?? 0,
      remainingQty: json['remainingQty'] as int? ?? 0,
      // null = 금액 미상. 0 으로 바꾸면 공짜로 받은 것처럼 보인다.
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
    );
  }
}
