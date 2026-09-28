import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart' hide Unit;
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/product.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/unit.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/repositories/product_repository.dart';

class RegisterProductParams extends Equatable {
  final String productName;
  final String? barcodeId;
  final String? brand;
  final String? description;
  final int? price;
  /// 구매처 id 목록(FEATURE_2609_76). 비어 있으면 구매처 없음.
  final List<int> purchasePlaceIds;
  final Unit? netContentUnit;
  final double? packageHeight;
  final double? packageLength;
  final double? packageWidth;
  final double? netContent;
  /// 개수 + 개수 단위 — 둘 다 있거나 둘 다 null(D6).
  final int? countQuantity;
  final String? countUnit;
  final bool active;

  const RegisterProductParams({
    required this.productName,
    this.barcodeId,
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
    this.active = true,
  });

  @override
  List<Object?> get props => [
    productName,
    barcodeId,
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
    active,
  ];

  Map<String, dynamic> toJson() => {
    'productName': productName,
    if (barcodeId != null) 'barcodeId': barcodeId,
    if (brand != null) 'brand': brand,
    if (description != null) 'description': description,
    if (price != null) 'price': price,
    'purchasePlaceIds': purchasePlaceIds,
    if (netContentUnit != null) 'netContentUnit': netContentUnit!.serverValue,
    if (packageHeight != null) 'packageHeight': packageHeight,
    if (packageLength != null) 'packageLength': packageLength,
    if (packageWidth != null) 'packageWidth': packageWidth,
    if (netContent != null) 'netContent': netContent,
    if (countQuantity != null) 'countQuantity': countQuantity,
    if (countUnit != null) 'countUnit': countUnit,
    'active': active,
  };
}

class RegisterProductUseCase {
  final ProductRepository repository;

  RegisterProductUseCase(this.repository);

  Future<Either<Failure, Product>> call(RegisterProductParams params) =>
      repository.registerProduct(params);
}
