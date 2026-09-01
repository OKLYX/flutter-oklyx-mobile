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
  final String? store;
  final Unit? netContentUnit;
  final double? packageHeight;
  final double? packageLength;
  final double? packageWidth;
  final double? netContent;

  const UpdateProductParams({
    required this.productId,
    required this.productName,
    this.brand,
    this.description,
    this.price,
    this.store,
    this.netContentUnit,
    this.packageHeight,
    this.packageLength,
    this.packageWidth,
    this.netContent,
  });

  Map<String, dynamic> toJson() => {
    'productName': productName,
    if (brand != null) 'brand': brand,
    if (description != null) 'description': description,
    if (price != null) 'price': price,
    if (store != null) 'store': store,
    if (netContentUnit != null) 'netContentUnit': netContentUnit!.serverValue,
    if (packageHeight != null) 'packageHeight': packageHeight,
    if (packageLength != null) 'packageLength': packageLength,
    if (packageWidth != null) 'packageWidth': packageWidth,
    if (netContent != null) 'netContent': netContent,
  };

  @override
  List<Object?> get props => [
    productId,
    productName,
    brand,
    description,
    price,
    store,
    netContentUnit,
    packageHeight,
    packageLength,
    packageWidth,
    netContent,
  ];
}

class UpdateProductUseCase {
  final ProductRepository repository;

  UpdateProductUseCase(this.repository);

  Future<Either<Failure, Product>> call(UpdateProductParams params) =>
      repository.updateProduct(params);
}
