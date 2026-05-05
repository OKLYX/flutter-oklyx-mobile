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
  final Unit? unit;
  final double? volumeHeight;
  final double? volumeLong;
  final double? volumeShort;
  final double? weight;

  const UpdateProductParams({
    required this.productId,
    required this.productName,
    this.brand,
    this.description,
    this.price,
    this.store,
    this.unit,
    this.volumeHeight,
    this.volumeLong,
    this.volumeShort,
    this.weight,
  });

  Map<String, dynamic> toJson() => {
    'productName': productName,
    if (brand != null) 'brand': brand,
    if (description != null) 'description': description,
    if (price != null) 'price': price,
    if (store != null) 'store': store,
    if (unit != null) 'unit': unit!.serverValue,
    if (volumeHeight != null) 'volumeHeight': volumeHeight,
    if (volumeLong != null) 'volumeLong': volumeLong,
    if (volumeShort != null) 'volumeShort': volumeShort,
    if (weight != null) 'weight': weight,
  };

  @override
  List<Object?> get props => [
    productId,
    productName,
    brand,
    description,
    price,
    store,
    unit,
    volumeHeight,
    volumeLong,
    volumeShort,
    weight,
  ];
}

class UpdateProductUseCase {
  final ProductRepository repository;

  UpdateProductUseCase(this.repository);

  Future<Either<Failure, Product>> call(UpdateProductParams params) =>
      repository.updateProduct(params);
}
