import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/repositories/product_repository.dart';

class DeleteProductImageParams extends Equatable {
  final int productId;

  const DeleteProductImageParams({required this.productId});

  @override
  List<Object?> get props => [productId];
}

class DeleteProductImageUseCase {
  final ProductRepository repository;

  DeleteProductImageUseCase(this.repository);

  Future<Either<Failure, void>> call(DeleteProductImageParams params) =>
      repository.deleteProductImage(params.productId);
}
