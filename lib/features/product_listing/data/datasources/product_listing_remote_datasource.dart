import 'package:dio/dio.dart';
import '../models/product_listing_model.dart';
import '../../domain/repositories/product_listing_request.dart';

abstract class ProductListingRemoteDataSource {
  /// GET /api/product-listings?platform={platform}&page={page}&size={size}
  Future<List<ProductListingModel>> getByPlatform(
    String platform, {
    required int page,
    required int size,
  });

  /// GET /api/product-listings/{id}
  Future<ProductListingModel> getById(int id);

  /// POST /api/product-listings
  Future<ProductListingModel> create(CreateProductListingRequest request);

  /// PUT /api/product-listings/{id}
  Future<ProductListingModel> update(int id, UpdateProductListingRequest request);

  /// DELETE /api/product-listings/{id}
  Future<void> delete(int id);
}

class ProductListingRemoteDataSourceImpl implements ProductListingRemoteDataSource {
  final Dio dio;

  ProductListingRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<ProductListingModel>> getByPlatform(
    String platform, {
    required int page,
    required int size,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ProductListingModel> getById(int id) {
    throw UnimplementedError();
  }

  @override
  Future<ProductListingModel> create(CreateProductListingRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<ProductListingModel> update(int id, UpdateProductListingRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(int id) {
    throw UnimplementedError();
  }
}
