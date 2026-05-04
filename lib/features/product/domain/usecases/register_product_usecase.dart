import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/product.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/repositories/product_repository.dart';

class RegisterProductParams extends Equatable {
  final String productName;
  final String barcodeId;
  final String? brand;
  final String? description;
  final int? price;
  final String? store;
  final String? unit;
  final double? volumeHeight;
  final double? volumeLong;
  final double? volumeShort;
  final double? weight;
  final bool active;

  const RegisterProductParams({
    required this.productName,
    required this.barcodeId,
    this.brand,
    this.description,
    this.price,
    this.store,
    this.unit,
    this.volumeHeight,
    this.volumeLong,
    this.volumeShort,
    this.weight,
    this.active = true,
  });

  @override
  List<Object?> get props => [
    productName,
    barcodeId,
    brand,
    description,
    price,
    store,
    unit,
    volumeHeight,
    volumeLong,
    volumeShort,
    weight,
    active,
  ];

  Map<String, dynamic> toJson() => {
    'productName': productName,
    'barcodeId': barcodeId,
    if (brand != null) 'brand': brand,
    if (description != null) 'description': description,
    if (price != null) 'price': price,
    if (store != null) 'store': store,
    if (unit != null) 'unit': unit,
    if (volumeHeight != null) 'volumeHeight': volumeHeight,
    if (volumeLong != null) 'volumeLong': volumeLong,
    if (volumeShort != null) 'volumeShort': volumeShort,
    if (weight != null) 'weight': weight,
    'active': active,
  };
}

class RegisterProductUseCase {
  final ProductRepository repository;

  RegisterProductUseCase(this.repository);

  Future<Either<Failure, Product>> call(RegisterProductParams params) =>
      repository.registerProduct(params);
}
