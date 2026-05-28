import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/commission_rate.dart';
import '../../domain/repositories/commission_rate_repository.dart';
import '../datasources/commission_rate_remote_datasource.dart';
import '../models/create_commission_rate_params.dart';
import '../models/update_commission_rate_params.dart';

class CommissionRateRepositoryImpl implements CommissionRateRepository {
  final CommissionRateRemoteDataSource _remoteDataSource;

  CommissionRateRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<CommissionRate>>> getCommissionRates() async {
    try {
      final models = await _remoteDataSource.getCommissionRates();
      return Right(models);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, CommissionRate>> getCommissionRate(int id) async {
    try {
      final model = await _remoteDataSource.getCommissionRate(id);
      return Right(model);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, CommissionRate>> createCommissionRate({
    required String platform,
    int? categoryId,
    required double rate,
  }) async {
    try {
      final params = CreateCommissionRateParams(
        platform: platform,
        categoryId: categoryId,
        rate: rate,
      );
      final model = await _remoteDataSource.createCommissionRate(params.toJson());
      return Right(model);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, CommissionRate>> updateCommissionRate({
    required int id,
    String? platform,
    int? categoryId,
    double? rate,
  }) async {
    try {
      final params = UpdateCommissionRateParams(
        platform: platform,
        categoryId: categoryId,
        rate: rate,
      );
      final model = await _remoteDataSource.updateCommissionRate(id, params.toJson());
      return Right(model);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCommissionRate(int id) async {
    try {
      await _remoteDataSource.deleteCommissionRate(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
