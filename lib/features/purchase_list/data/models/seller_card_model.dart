import '../../domain/entities/seller_card.dart';

class SellerCardModel extends SellerCard {
  const SellerCardModel({
    required super.id,
    required super.sellerId,
    required super.sellerName,
    required super.alias,
    required super.maskedNumber,
  });

  factory SellerCardModel.fromJson(Map<String, dynamic> json) {
    return SellerCardModel(
      id: json['id'] as int,
      sellerId: json['sellerId'] as int,
      sellerName: json['sellerName'] as String? ?? '',
      alias: json['alias'] as String? ?? '',
      maskedNumber: json['maskedNumber'] as String? ?? '',
    );
  }
}
