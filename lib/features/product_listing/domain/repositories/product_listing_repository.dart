import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'product_listing_request.dart';
import '../entities/product_listing.dart';

abstract class ProductListingRepository {
  /// 플랫폼별 판매상품 목록 조회 (페이지네이션)
  Future<Either<Failure, List<ProductListing>>> getByPlatform(
    String platform, {
    required int page,
    required int size,
  });

  /// 판매상품 상세 조회 (by ID)
  Future<Either<Failure, ProductListing>> getById(int id);

  Future<Either<Failure, ProductListing>> create(
    CreateProductListingRequest request,
  );

  Future<Either<Failure, ProductListing>> update(
    int id,
    UpdateProductListingRequest request,
  );

  Future<Either<Failure, void>> delete(int id);
}
