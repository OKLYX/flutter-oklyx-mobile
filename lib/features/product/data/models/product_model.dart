import 'package:flutter_oklyn_mobile/features/product/data/models/purchase_place_model.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.productName,
    super.barcodeId,
    super.brand,
    super.price,
    super.purchasePlaces,
    super.netContentUnit,
    super.packageHeight,
    super.packageLength,
    super.packageWidth,
    super.netContent,
    super.countQuantity,
    super.countUnit,
    super.description,
    super.name,
    super.imageUrl,
    required super.active,
    required super.createdDate,
    required super.modifiedDate,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int,
      productName: json['productName'] as String,
      barcodeId: json['barcodeId'] as String?,
      brand: json['brand'] as String?,
      price: _toInt(json['price']),
      // 🔴 사진 올리기·지우기 응답에는 purchasePlaces 가 없다(null) → 빈 목록으로 읽는다.
      purchasePlaces: ((json['purchasePlaces'] as List<dynamic>?) ?? const [])
          .map((item) => PurchasePlaceModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      netContentUnit: json['netContentUnit'] as String?,
      packageHeight: json['packageHeight'] as String?,
      packageLength: json['packageLength'] as String?,
      packageWidth: json['packageWidth'] as String?,
      netContent: json['netContent'] as String?,
      countQuantity: _toInt(json['countQuantity']),
      countUnit: json['countUnit'] as String?,
      description: json['description'] as String?,
      name: json['name'] as String?,
      imageUrl: json['imageUrl'] as String?,
      active: json['active'] as bool? ?? true,
      createdDate: json['createdDate'] as String,
      modifiedDate: json['modifiedDate'] as String,
    );
  }

  Product toDomain() => Product(
    id: id,
    productName: productName,
    barcodeId: barcodeId,
    brand: brand,
    price: price,
    purchasePlaces: purchasePlaces,
    netContentUnit: netContentUnit,
    packageHeight: packageHeight,
    packageLength: packageLength,
    packageWidth: packageWidth,
    netContent: netContent,
    countQuantity: countQuantity,
    countUnit: countUnit,
    description: description,
    name: name,
    imageUrl: imageUrl,
    active: active,
    createdDate: createdDate,
    modifiedDate: modifiedDate,
  );

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
