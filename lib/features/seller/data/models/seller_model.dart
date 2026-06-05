import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';

class SellerModel extends Seller {
  const SellerModel({
    required int id,
    required String sellerName,
    required String businessRegistration,
    required String createdDate,
    required String modifiedDate,
  }) : super(
    id: id,
    sellerName: sellerName,
    businessRegistration: businessRegistration,
    createdDate: createdDate,
    modifiedDate: modifiedDate,
  );

  factory SellerModel.fromJson(Map<String, dynamic> json) => SellerModel(
    id: json['id'] as int,
    sellerName: json['sellerName'] as String,
    businessRegistration: json['businessRegistration'] as String,
    createdDate: json['createdDate'] as String? ?? 'N/A',
    modifiedDate: json['modifiedDate'] as String? ?? 'N/A',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sellerName': sellerName,
    'businessRegistration': businessRegistration,
    'createdDate': createdDate,
    'modifiedDate': modifiedDate,
  };
}
