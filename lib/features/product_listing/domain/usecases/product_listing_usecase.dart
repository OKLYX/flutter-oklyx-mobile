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

  Future<Either<Failure, List<ProductListingOption>>> getOptions(int listingId) {
    return repository.getOptions(listingId);
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

  // Lookup data methods (for form dropdowns)
  Future<Either<Failure, List<dynamic>>> getSellers() async {
    try {
      final sellers = await repository.getSellers();
      if (sellers.isEmpty) {
        return Left(ServerFailure('판매자 데이터가 없습니다'));
      }
      return Right(sellers);
    } on Exception catch (e) {
      return Left(ServerFailure('판매자 로드 실패: ${e.toString()}'));
    }
  }

  Future<Either<Failure, List<dynamic>>> getCategories() async {
    try {
      final categories = await repository.getCategories();
      return Right(categories);
    } on Exception catch (e) {
      return Left(ServerFailure('카테고리 로드 실패: ${e.toString()}'));
    }
  }

  Future<Either<Failure, List<dynamic>>> getCarrierRates() async {
    try {
      final carrierRates = await repository.getCarrierRates();
      return Right(carrierRates);
    } on Exception catch (e) {
      return Left(ServerFailure('배송사 로드 실패: ${e.toString()}'));
    }
  }

  Future<Either<Failure, List<dynamic>>> getPackages() async {
    try {
      final packages = await repository.getPackages();
      return Right(packages);
    } on Exception catch (e) {
      return Left(ServerFailure('패키지 로드 실패: ${e.toString()}'));
    }
  }

  Future<Either<Failure, List<dynamic>>> getCommissionRates() async {
    try {
      final rates = await repository.getCommissionRates();
      return Right(rates);
    } on Exception catch (e) {
      return Left(ServerFailure('수수료율 로드 실패: ${e.toString()}'));
    }
  }

  Future<Either<Failure, dynamic>> getProducts({int page = 0, int size = 50}) async {
    try {
      final products = await repository.getProducts(page: page, size: size);
      return Right(products);
    } on Exception catch (e) {
      return Left(ServerFailure('상품 로드 실패: ${e.toString()}'));
    }
  }

  Future<Either<Failure, dynamic>> searchProducts({
    required String query,
    int page = 0,
    int size = 50,
  }) async {
    try {
      final products = await repository.searchProducts(
        query: query,
        page: page,
        size: size,
      );
      return Right(products);
    } on Exception catch (e) {
      return Left(ServerFailure('상품 검색 실패: ${e.toString()}'));
    }
  }
}
