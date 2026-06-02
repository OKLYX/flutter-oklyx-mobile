import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';

class SellerModel extends Seller {
  const SellerModel({
    required int id,
    required String sellerName,
    required String businessRegistration,
  }) : super(
    id: id,
    sellerName: sellerName,
    businessRegistration: businessRegistration,
  );

  factory SellerModel.fromJson(Map<String, dynamic> json) => SellerModel(
    id: json['id'] as int,
    sellerName: json['sellerName'] as String,
    businessRegistration: json['businessRegistration'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sellerName': sellerName,
    'businessRegistration': businessRegistration,
  };
}
