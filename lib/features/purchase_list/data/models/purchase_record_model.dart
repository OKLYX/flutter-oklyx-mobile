import 'package:flutter_oklyn_mobile/features/purchase_list/domain/entities/purchase_record.dart';

class PurchaseRecordModel extends PurchaseRecord {
  PurchaseRecordModel({
    required int id,
    required String purchasedOn,
    required int quantity,
    double? totalAmount,
    double? unitPrice,
    bool reflectToBasePrice = true,
    String sellerName = '',
  }) : super(
          id: id,
          purchasedOn: purchasedOn,
          quantity: quantity,
          totalAmount: totalAmount,
          unitPrice: unitPrice,
          reflectToBasePrice: reflectToBasePrice,
          sellerName: sellerName,
        );

  factory PurchaseRecordModel.fromJson(Map<String, dynamic> json) {
    return PurchaseRecordModel(
      id: json['id'] as int,
      purchasedOn: json['purchasedOn'] as String,
      quantity: json['quantity'] as int,
      // ⚠️ Do NOT default to 0 — null is "amount unknown" (PLAN 2609_28 D1).
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
      reflectToBasePrice: json['reflectToBasePrice'] as bool? ?? true,
      sellerName: json['sellerName'] as String? ?? '',
    );
  }
}
