import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/domain/entities/carrier_rate.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/domain/repositories/carrier_rate_repository.dart';
import '../datasources/carrier_rate_remote_datasource.dart';
import '../models/carrier_rate_model.dart';
import '../models/create_carrier_rate_params.dart';
import '../models/update_carrier_rate_params.dart';

class CarrierRateRepositoryImpl implements CarrierRateRepository {
  final CarrierRateRemoteDataSource remoteDataSource;

  CarrierRateRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<CarrierRate>>> getCarrierRates() async {
    try {
      final models = await remoteDataSource.getCarrierRates();
      return Right(models.cast<CarrierRate>());
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          e.message ?? 'Server error occurred',
          statusCode: e.response?.statusCode,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CarrierRate>> getCarrierRate(int id) async {
    try {
      final model = await remoteDataSource.getCarrierRate(id);
      return Right(model);
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          e.message ?? 'Server error occurred',
          statusCode: e.response?.statusCode,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CarrierRate>> createCarrierRate(
    String carrier,
    String type,
    double cost,
    String effectiveDate,
    bool isDefault,
  ) async {
    try {
      final params = CreateCarrierRateParams(
        carrier: carrier,
        type: type,
        cost: cost,
        effectiveDate: effectiveDate,
        isDefault: isDefault,
      );
      final model = await remoteDataSource.createCarrierRate(params);
      return Right(model);
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          e.message ?? 'Server error occurred',
          statusCode: e.response?.statusCode,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CarrierRate>> updateCarrierRate(
    int id,
    String carrier,
    String type,
    double cost,
    String effectiveDate,
    bool isDefault,
  ) async {
    try {
      final params = UpdateCarrierRateParams(
        id: id,
        carrier: carrier,
        type: type,
        cost: cost,
        effectiveDate: effectiveDate,
        isDefault: isDefault,
      );
      final model = await remoteDataSource.updateCarrierRate(id, params);
      return Right(model);
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          e.message ?? 'Server error occurred',
          statusCode: e.response?.statusCode,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
