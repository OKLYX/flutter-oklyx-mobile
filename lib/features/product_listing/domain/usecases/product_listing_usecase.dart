import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/product_listing.dart';
import '../repositories/product_listing_repository.dart';
import '../repositories/product_listing_request.dart';

class ProductListingUseCase {
  final ProductListingRepository repository;

  ProductListingUseCase({required this.repository});

  Future<Either<Failure, List<ProductListing>>> getByPlatform(
    String platform, {
    required int page,
    required int size,
  }) {
    return repository.getByPlatform(platform, page: page, size: size);
  }

  Future<Either<Failure, ProductListing>> getById(int id) {
    return repository.getById(id);
  }

  Future<Either<Failure, ProductListing>> create(
    CreateProductListingRequest request,
  ) {
    return repository.create(request);
  }

  Future<Either<Failure, ProductListing>> update(
    int id,
    UpdateProductListingRequest request,
  ) {
    return repository.update(id, request);
  }

  Future<Either<Failure, void>> delete(int id) {
    return repository.delete(id);
  }
}
