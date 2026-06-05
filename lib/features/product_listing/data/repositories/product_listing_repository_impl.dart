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
      final models = await remoteDataSource.getByPlatform(
        platform,
        page: page,
        size: size,
      );
      return Right(models);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductListing>> getById(int id) async {
    try {
      final model = await remoteDataSource.getById(id);
      return Right(model);
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> delete(int id) async {
    try {
      await remoteDataSource.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
