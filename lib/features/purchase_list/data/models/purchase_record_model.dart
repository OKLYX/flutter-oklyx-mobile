import 'package:flutter_oklyn_mobile/features/purchase_list/domain/entities/purchase_record.dart';

class PurchaseRecordModel extends PurchaseRecord {
  PurchaseRecordModel({
    required int id,
    required String purchasedOn,
    required int quantity,
  }) : super(id: id, purchasedOn: purchasedOn, quantity: quantity);

  factory PurchaseRecordModel.fromJson(Map<String, dynamic> json) {
    return PurchaseRecordModel(
      id: json['id'] as int,
      purchasedOn: json['purchasedOn'] as String,
      quantity: json['quantity'] as int,
    );
  }
}
