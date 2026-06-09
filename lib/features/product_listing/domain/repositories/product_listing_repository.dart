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

  /// 판매상품 옵션 목록 조회 (by listing ID)
  Future<Either<Failure, List<ProductListingOption>>> getOptions(int listingId);

  Future<Either<Failure, ProductListing>> create(
    CreateProductListingRequest request,
  );

  Future<Either<Failure, ProductListing>> update(
    int id,
    UpdateProductListingRequest request,
  );

  Future<Either<Failure, void>> delete(int id);

  // Lookup data methods
  Future<List<dynamic>> getSellers();
  Future<List<dynamic>> getCategories();
  Future<List<dynamic>> getCarrierRates();
  Future<List<dynamic>> getPackages();
  Future<List<dynamic>> getCommissionRates();
  Future<dynamic> getProducts({int page = 0, int size = 50});
  Future<dynamic> searchProducts({required String query, int page = 0, int size = 50});
}
