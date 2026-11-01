import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/exceptions.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/barcode_scan_result.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/product.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/product_image.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/product_page.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/purchase_place.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/repositories/product_repository.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/update_product_usecase.dart';
import '../datasources/product_remote_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;

  ProductRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, ProductPage>> getProducts({
    required int page,
    int size = 20,
    String? search,
  }) async {
    try {
      final productPageModel = await remoteDataSource.getProducts(
        page: page,
        size: size,
        search: search,
      );
      return Right(productPageModel.toDomain());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> getProduct(int id) async {
    try {
      final productModel = await remoteDataSource.getProduct(id);
      return Right(productModel.toDomain());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> registerProduct(dynamic params) async {
    try {
      final productModel = await remoteDataSource.registerProduct(params);
      return Right(productModel.toDomain());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> checkBarcodeAvailable(String barcodeId) async {
    try {
      final isAvailable = await remoteDataSource.checkBarcodeAvailable(barcodeId);
      return Right(isAvailable);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BarcodeScanResult>> scanBarcodeFromImage(
    File image,
  ) async {
    try {
      final result = await remoteDataSource.scanBarcodeFromImage(image);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> updateProduct(UpdateProductParams params) async {
    try {
      final productModel = await remoteDataSource.updateProduct(params);
      return Right(productModel.toDomain());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(int productId) async {
    try {
      await remoteDataSource.deleteProduct(productId);
      return Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  Future<Either<Failure, T>> _guardImage<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProductImage>>> listProductImages(
    int productId,
  ) =>
      _guardImage(() => remoteDataSource.listProductImages(productId));

  @override
  Future<Either<Failure, List<ProductImage>>> addProductImages(
    int productId,
    List<File> files,
  ) =>
      _guardImage(() => remoteDataSource.addProductImages(productId, files));

  @override
  Future<Either<Failure, void>> replaceProductImage(
    int productId,
    int imageId,
    File file,
  ) =>
      _guardImage(
        () => remoteDataSource.replaceProductImage(productId, imageId, file),
      );

  @override
  Future<Either<Failure, List<ProductImage>>> reorderProductImages(
    int productId,
    List<int> imageIds,
  ) =>
      _guardImage(
        () => remoteDataSource.reorderProductImages(productId, imageIds),
      );

  @override
  Future<Either<Failure, void>> removeProductImage(int productId, int imageId) =>
      _guardImage(() => remoteDataSource.removeProductImage(productId, imageId));

  @override
  Future<Either<Failure, List<PurchasePlace>>> getPurchasePlaces() async {
    try {
      final models = await remoteDataSource.getPurchasePlaces();
      return Right(models);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
