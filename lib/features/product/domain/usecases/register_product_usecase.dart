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
  final String? store;
  final Unit? netContentUnit;
  final double? packageHeight;
  final double? packageLength;
  final double? packageWidth;
  final double? netContent;
  final bool active;

  const RegisterProductParams({
    required this.productName,
    this.barcodeId,
    this.brand,
    this.description,
    this.price,
    this.store,
    this.netContentUnit,
    this.packageHeight,
    this.packageLength,
    this.packageWidth,
    this.netContent,
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
    netContentUnit,
    packageHeight,
    packageLength,
    packageWidth,
    netContent,
    active,
  ];

  Map<String, dynamic> toJson() => {
    'productName': productName,
    if (barcodeId != null) 'barcodeId': barcodeId,
    if (brand != null) 'brand': brand,
    if (description != null) 'description': description,
    if (price != null) 'price': price,
    if (store != null) 'store': store,
    if (netContentUnit != null) 'netContentUnit': netContentUnit!.serverValue,
    if (packageHeight != null) 'packageHeight': packageHeight,
    if (packageLength != null) 'packageLength': packageLength,
    if (packageWidth != null) 'packageWidth': packageWidth,
    if (netContent != null) 'netContent': netContent,
    'active': active,
  };
}

class RegisterProductUseCase {
  final ProductRepository repository;

  RegisterProductUseCase(this.repository);

  Future<Either<Failure, Product>> call(RegisterProductParams params) =>
      repository.registerProduct(params);
}
