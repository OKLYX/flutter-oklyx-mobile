import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart' hide Unit;

import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/product.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/unit.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/repositories/product_repository.dart';

class UpdateProductParams extends Equatable {
  final int productId;
  final String productName;
  final String? brand;
  final String? description;
  final int? price;
  /// 구매처 id 목록 — 항상 보낸다 = 이 목록으로 통째로 바뀐다(FEATURE_2609_76).
  final List<int> purchasePlaceIds;
  final Unit? netContentUnit;
  final double? packageHeight;
  final double? packageLength;
  final double? packageWidth;
  final double? netContent;
  /// 개수 쌍. 🔴 `countUnit` 을 항상 보낸다(없으면 '') — 서버는 `countUnit` 을 받으면 개수 쌍을 통째로 바꾼다.
  final int? countQuantity;
  final String? countUnit;

  const UpdateProductParams({
    required this.productId,
    required this.productName,
    this.brand,
    this.description,
    this.price,
    this.purchasePlaceIds = const [],
    this.netContentUnit,
    this.packageHeight,
    this.packageLength,
    this.packageWidth,
    this.netContent,
    this.countQuantity,
    this.countUnit,
  });

  Map<String, dynamic> toJson() => {
    'productName': productName,
    if (brand != null) 'brand': brand,
    if (description != null) 'description': description,
    if (price != null) 'price': price,
    'purchasePlaceIds': purchasePlaceIds,
    if (netContentUnit != null) 'netContentUnit': netContentUnit!.serverValue,
    if (packageHeight != null) 'packageHeight': packageHeight,
    if (packageLength != null) 'packageLength': packageLength,
    if (packageWidth != null) 'packageWidth': packageWidth,
    if (netContent != null) 'netContent': netContent,
    'countQuantity': countQuantity,
    'countUnit': countUnit ?? '',
  };

  @override
  List<Object?> get props => [
    productId,
    productName,
    brand,
    description,
    price,
    purchasePlaceIds,
    netContentUnit,
    packageHeight,
    packageLength,
    packageWidth,
    netContent,
    countQuantity,
    countUnit,
  ];
}

class UpdateProductUseCase {
  final ProductRepository repository;

  UpdateProductUseCase(this.repository);

  Future<Either<Failure, Product>> call(UpdateProductParams params) =>
      repository.updateProduct(params);
}
