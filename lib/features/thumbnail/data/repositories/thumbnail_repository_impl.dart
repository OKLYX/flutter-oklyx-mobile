import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/exceptions.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../domain/entities/product_thumbnail.dart';
import '../../domain/entities/template_field.dart';
import '../../domain/repositories/thumbnail_repository.dart';
import '../datasources/thumbnail_remote_datasource.dart';

class ThumbnailRepositoryImpl implements ThumbnailRepository {
  final ThumbnailRemoteDataSource remoteDataSource;

  ThumbnailRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<ProductThumbnail>>> getByProduct(
      int productId) async {
    try {
      final result = await remoteDataSource.getByProduct(productId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on DioException catch (e) {
      return Left(ServerFailure(
        e.message ?? '썸네일을 불러오지 못했습니다',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductThumbnail>> generate(
    int productId,
    int sellerId,
    Map<String, String> fieldValues,
  ) async {
    try {
      final result =
          await remoteDataSource.generate(productId, sellerId, fieldValues);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on DioException catch (e) {
      return Left(ServerFailure(
        e.message ?? '썸네일 생성에 실패했습니다',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductThumbnail>> overrideThumbnail(
    int productId,
    int sellerId,
    File file,
  ) async {
    try {
      final result =
          await remoteDataSource.overrideThumbnail(productId, sellerId, file);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on DioException catch (e) {
      return Left(ServerFailure(
        e.message ?? '이미지 업로드에 실패했습니다',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> delete(int productId, int sellerId) async {
    try {
      await remoteDataSource.delete(productId, sellerId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on DioException catch (e) {
      return Left(ServerFailure(
        e.message ?? '썸네일 삭제에 실패했습니다',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TemplateField>>> getDefaultTemplateFields() async {
    try {
      final result = await remoteDataSource.getDefaultTemplateFields();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on DioException catch (e) {
      return Left(ServerFailure(
        e.message ?? '템플릿 필드를 불러오지 못했습니다',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
