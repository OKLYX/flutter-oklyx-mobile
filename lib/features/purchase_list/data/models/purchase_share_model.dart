import 'package:flutter_oklyn_mobile/features/purchase_list/domain/entities/purchase_share.dart';

class PurchaseShareModel extends PurchaseShare {
  const PurchaseShareModel({
    required super.sellerId,
    required super.sellerName,
    required super.neededQty,
    required super.purchasedQty,
    required super.remainingQty,
    required super.targetMet,
    required super.state,
    super.checkId,
    super.checkedOn,
  });

  factory PurchaseShareModel.fromJson(Map<String, dynamic> json) {
    return PurchaseShareModel(
      sellerId: json['sellerId'] as int,
      sellerName: json['sellerName'] as String,
      neededQty: json['neededQty'] as int,
      purchasedQty: json['purchasedQty'] as int,
      remainingQty: json['remainingQty'] as int,
      targetMet: json['targetMet'] as bool,
      state: json['state'] as String,
      checkId: json['checkId'] as int?,
      checkedOn: json['checkedOn'] as String?,
    );
  }
}
