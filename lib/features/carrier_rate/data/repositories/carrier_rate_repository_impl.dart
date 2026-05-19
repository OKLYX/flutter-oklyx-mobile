import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/domain/entities/carrier_rate.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/domain/repositories/carrier_rate_repository.dart';
import '../datasources/carrier_rate_remote_datasource.dart';

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
}
