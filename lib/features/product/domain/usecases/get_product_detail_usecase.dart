import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProductDetailUseCase {
  final ProductRepository repository;

  GetProductDetailUseCase(this.repository);

  Future<Either<Failure, Product>> call(GetProductDetailParams params) =>
      repository.getProduct(params.productId);
}

class GetProductDetailParams extends Equatable {
  final int productId;

  const GetProductDetailParams(this.productId);

  @override
  List<Object?> get props => [productId];
}
