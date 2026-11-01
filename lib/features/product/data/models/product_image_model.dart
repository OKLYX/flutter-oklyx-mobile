import 'package:flutter_oklyn_mobile/features/product/domain/entities/product_image.dart';

class ProductImageModel extends ProductImage {
  const ProductImageModel({
    required super.id,
    required super.productId,
    required super.sortOrder,
    required super.imageUrl,
  });

  factory ProductImageModel.fromJson(Map<String, dynamic> json) =>
      ProductImageModel(
        id: json['id'] as int,
        productId: json['productId'] as int,
        sortOrder: json['sortOrder'] as int,
        imageUrl: json['imageUrl'] as String,
      );
}
