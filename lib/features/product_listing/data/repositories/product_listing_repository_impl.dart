import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../domain/entities/product_listing.dart';
import '../../domain/repositories/product_listing_repository.dart';
import '../../domain/repositories/product_listing_request.dart';
import '../datasources/product_listing_remote_datasource.dart';

class ProductListingRepositoryImpl implements ProductListingRepository {
  final ProductListingRemoteDataSource remoteDataSource;

  ProductListingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<ProductListing>>> getByPlatform(
    String platform, {
    required int page,
    required int size,
  }) async {
    try {
      final pageModel = await remoteDataSource.getByPlatform(
        platform,
        page: page,
        size: size,
      );
      return Right(pageModel.content.cast<ProductListing>());
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          e.message ?? 'Failed to fetch product listings',
          statusCode: e.response?.statusCode,
        ),
      );
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductListing>> getById(int id) async {
    try {
      final model = await remoteDataSource.getById(id);
      return Right(model);
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          e.message ?? 'Failed to fetch product listing',
          statusCode: e.response?.statusCode,
        ),
      );
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProductListingOption>>> getOptions(
    int listingId,
  ) async {
    try {
      final options = await remoteDataSource.getOptions(listingId);
      return Right(options.cast<ProductListingOption>());
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          e.message ?? 'Failed to fetch product listing options',
          statusCode: e.response?.statusCode,
        ),
      );
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductListing>> create(
    CreateProductListingRequest request,
  ) async {
    try {
      final model = await remoteDataSource.create(request);
      return Right(model);
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          e.message ?? 'Failed to create product listing',
          statusCode: e.response?.statusCode,
        ),
      );
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductListing>> update(
    int id,
    UpdateProductListingRequest request,
  ) async {
    try {
      final model = await remoteDataSource.update(id, request);
      return Right(model);
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          e.message ?? 'Failed to update product listing',
          statusCode: e.response?.statusCode,
        ),
      );
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> delete(int id) async {
    try {
      await remoteDataSource.delete(id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          e.message ?? 'Failed to delete product listing',
          statusCode: e.response?.statusCode,
        ),
      );
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<List<dynamic>> getSellers() async {
    return remoteDataSource.getSellers();
  }

  @override
  Future<List<dynamic>> getCategories() async {
    return remoteDataSource.getCategories();
  }

  @override
  Future<List<dynamic>> getCarrierRates() async {
    return remoteDataSource.getCarrierRates();
  }

  @override
  Future<List<dynamic>> getPackages() async {
    return remoteDataSource.getPackages();
  }

  @override
  Future<List<dynamic>> getCommissionRates() async {
    return remoteDataSource.getCommissionRates();
  }

  @override
  Future<dynamic> getProducts({int page = 0, int size = 50}) async {
    return remoteDataSource.getProducts(page: page, size: size);
  }

  @override
  Future<dynamic> searchProducts({required String query, int page = 0, int size = 50}) async {
    return remoteDataSource.searchProducts(query: query, page: page, size: size);
  }
}
