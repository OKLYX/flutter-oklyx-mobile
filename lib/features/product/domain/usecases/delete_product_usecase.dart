import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/repositories/product_repository.dart';

class DeleteProductParams extends Equatable {
  final int productId;

  const DeleteProductParams(this.productId);

  @override
  List<Object?> get props => [productId];
}

class DeleteProductUseCase {
  final ProductRepository repository;

  DeleteProductUseCase(this.repository);

  Future<Either<Failure, void>> call(DeleteProductParams params) =>
      repository.deleteProduct(params.productId);
}
