import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/exceptions.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/category/data/datasources/category_remote_datasource.dart';
import 'package:flutter_oklyn_mobile/features/category/domain/entities/category.dart';
import 'package:flutter_oklyn_mobile/features/category/domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource remoteDataSource;

  CategoryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Category>>> getCategories() async {
    try {
      final categories = await remoteDataSource.getCategories();
      return Right(categories);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on SocketException {
      return Left(NetworkFailure('Network error'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Category>> createCategory({
    required String name,
    required String platform,
    required String platformCategoryId,
    int? parentId,
  }) async {
    try {
      final category = await remoteDataSource.createCategory(
        name: name,
        platform: platform,
        platformCategoryId: platformCategoryId,
        parentId: parentId,
      );
      return Right(category);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on SocketException {
      return Left(NetworkFailure('Network error'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Category>> getCategory(int id) async {
    try {
      final category = await remoteDataSource.getCategory(id);
      return Right(category);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on SocketException {
      return Left(NetworkFailure('Network error'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Category>> updateCategory({
    required int id,
    required String name,
    required String platform,
    required String platformCategoryId,
    required int? parentId,
  }) async {
    try {
      final category = await remoteDataSource.updateCategory(
        id: id,
        name: name,
        platform: platform,
        platformCategoryId: platformCategoryId,
        parentId: parentId,
      );
      return Right(category);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on SocketException {
      return Left(NetworkFailure('Network error'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(int id) async {
    try {
      await remoteDataSource.deleteCategory(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on SocketException {
      return Left(NetworkFailure('Network error'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
