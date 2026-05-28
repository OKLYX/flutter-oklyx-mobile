import 'package:flutter_oklyn_mobile/features/product/domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.productName,
    super.barcodeId,
    super.brand,
    super.price,
    super.store,
    super.unit,
    super.volumeHeight,
    super.volumeLong,
    super.volumeShort,
    super.weight,
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
      store: json['store'] as String?,
      unit: json['unit'] as String?,
      volumeHeight: json['volumeHeight'] as String?,
      volumeLong: json['volumeLong'] as String?,
      volumeShort: json['volumeShort'] as String?,
      weight: json['weight'] as String?,
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
    store: store,
    unit: unit,
    volumeHeight: volumeHeight,
    volumeLong: volumeLong,
    volumeShort: volumeShort,
    weight: weight,
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
