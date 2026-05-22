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
  }) async {
    try {
      final category = await remoteDataSource.createCategory(
        name: name,
        platform: platform,
        platformCategoryId: platformCategoryId,
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
}
