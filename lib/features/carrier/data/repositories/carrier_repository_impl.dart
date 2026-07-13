import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/carrier/domain/entities/carrier.dart';
import 'package:flutter_oklyn_mobile/features/carrier/domain/entities/platform_carrier_code.dart';
import 'package:flutter_oklyn_mobile/features/carrier/domain/repositories/carrier_repository.dart';
import '../datasources/carrier_remote_datasource.dart';

class CarrierRepositoryImpl implements CarrierRepository {
  final CarrierRemoteDataSource remoteDataSource;

  CarrierRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Carrier>>> getCarriers() async {
    try {
      final models = await remoteDataSource.getCarriers();
      return Right(models.cast<Carrier>());
    } on DioException catch (e) {
      return Left(ServerFailure(
        e.message ?? 'Server error occurred',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Carrier>> createCarrier(String name, bool isActive) async {
    try {
      final model = await remoteDataSource.createCarrier(name, isActive);
      return Right(model);
    } on DioException catch (e) {
      return Left(ServerFailure(
        e.message ?? 'Server error occurred',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Carrier>> updateCarrier(int id, String name, bool isActive) async {
    try {
      final model = await remoteDataSource.updateCarrier(id, name, isActive);
      return Right(model);
    } on DioException catch (e) {
      return Left(ServerFailure(
        e.message ?? 'Server error occurred',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCarrier(int id) async {
    try {
      await remoteDataSource.deleteCarrier(id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(
        e.message ?? 'Failed to delete carrier',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(ServerFailure('Failed to delete carrier'));
    }
  }

  @override
  Future<Either<Failure, List<PlatformCarrierCode>>> getPlatformCodes(int carrierId) async {
    try {
      final models = await remoteDataSource.getPlatformCodes(carrierId);
      return Right(models.cast<PlatformCarrierCode>());
    } on DioException catch (e) {
      return Left(ServerFailure(
        e.message ?? 'Server error occurred',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PlatformCarrierCode>> createPlatformCode(
    int carrierId,
    String platform,
    String code,
  ) async {
    try {
      final model = await remoteDataSource.createPlatformCode(carrierId, platform, code);
      return Right(model);
    } on DioException catch (e) {
      return Left(ServerFailure(
        e.message ?? 'Server error occurred',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PlatformCarrierCode>> updatePlatformCode(
    int carrierId,
    int codeId,
    String platform,
    String code,
  ) async {
    try {
      final model =
          await remoteDataSource.updatePlatformCode(carrierId, codeId, platform, code);
      return Right(model);
    } on DioException catch (e) {
      return Left(ServerFailure(
        e.message ?? 'Server error occurred',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePlatformCode(int carrierId, int codeId) async {
    try {
      await remoteDataSource.deletePlatformCode(carrierId, codeId);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(
        e.message ?? 'Failed to delete platform code',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(ServerFailure('Failed to delete platform code'));
    }
  }
}
