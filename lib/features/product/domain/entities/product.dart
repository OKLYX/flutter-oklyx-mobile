import 'package:equatable/equatable.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/purchase_place.dart';

class Product extends Equatable {
  final int id;
  final String productName;
  final String? barcodeId;
  final String? brand;
  final int? price;
  /// 구매처(목록 순서, 현재 이름) — FEATURE_2609_76 / D3. 없으면 빈 목록.
  final List<PurchasePlace> purchasePlaces;
  final String? netContentUnit;
  final String? packageHeight;
  final String? packageLength;
  final String? packageWidth;
  final String? netContent;
  /// 개수(1 이상 정수) + 개수 단위(`kCountUnits`). 둘 다 있거나 둘 다 없다(D6).
  final int? countQuantity;
  final String? countUnit;
  final String? description;
  final String? name;
  final String? imageUrl;
  final bool active;
  final String createdDate;
  final String modifiedDate;

  const Product({
    required this.id,
    required this.productName,
    this.barcodeId,
    this.brand,
    this.price,
    this.purchasePlaces = const [],
    this.netContentUnit,
    this.packageHeight,
    this.packageLength,
    this.packageWidth,
    this.netContent,
    this.countQuantity,
    this.countUnit,
    this.description,
    this.name,
    this.imageUrl,
    required this.active,
    required this.createdDate,
    required this.modifiedDate,
  });

  @override
  List<Object?> get props => [
    id,
    productName,
    barcodeId,
    brand,
    price,
    purchasePlaces,
    netContentUnit,
    packageHeight,
    packageLength,
    packageWidth,
    netContent,
    countQuantity,
    countUnit,
    description,
    name,
    imageUrl,
    active,
    createdDate,
    modifiedDate,
  ];
}
