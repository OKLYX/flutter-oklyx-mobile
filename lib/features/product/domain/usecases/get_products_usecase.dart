import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/product_page.dart';
import '../repositories/product_repository.dart';

class GetProductsUseCase {
  final ProductRepository repository;

  GetProductsUseCase(this.repository);

  Future<Either<Failure, ProductPage>> call(GetProductsParams params) =>
      repository.getProducts(
        page: params.page,
        size: params.size,
        search: params.search,
      );
}

class GetProductsParams extends Equatable {
  final int page;
  final int size;
  final String? search;

  const GetProductsParams({
    required this.page,
    this.size = 20,
    this.search,
  });

  @override
  List<Object?> get props => [page, size, search];
}
