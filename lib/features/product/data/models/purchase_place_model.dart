import 'package:flutter_oklyn_mobile/features/product/domain/entities/purchase_place.dart';

class PurchasePlaceModel extends PurchasePlace {
  const PurchasePlaceModel({required super.id, required super.name});

  factory PurchasePlaceModel.fromJson(Map<String, dynamic> json) =>
      PurchasePlaceModel(
        id: json['id'] as int,
        name: json['name'] as String,
      );
}
