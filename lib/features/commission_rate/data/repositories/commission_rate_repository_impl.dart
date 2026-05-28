import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../../category/data/datasources/category_remote_datasource.dart';
import '../../domain/entities/commission_rate.dart';
import '../../domain/repositories/commission_rate_repository.dart';
import '../datasources/commission_rate_remote_datasource.dart';
import '../models/create_commission_rate_params.dart';
import '../models/commission_rate_model.dart';
import '../models/update_commission_rate_params.dart';

class CommissionRateRepositoryImpl implements CommissionRateRepository {
  final CommissionRateRemoteDataSource _remoteDataSource;
  final CategoryRemoteDataSource _categoryRemoteDataSource;

  CommissionRateRepositoryImpl(this._remoteDataSource, this._categoryRemoteDataSource);

  @override
  Future<Either<Failure, List<CommissionRate>>> getCommissionRates() async {
    try {
      final models = await _remoteDataSource.getCommissionRates();

      // Enrich models with category names
      final enrichedModels = await Future.wait(
        models.map((model) async {
          if (model.categoryId != null) {
            try {
              final category = await _categoryRemoteDataSource.getCategory(model.categoryId!);
              return CommissionRateModel(
                id: model.id,
                platform: model.platform,
                categoryId: model.categoryId,
                categoryName: category.name,
                rate: model.rate,
                isDefault: model.isDefault,
              );
            } catch (e) {
              return model;
            }
          }
          return model;
        }),
      );

      return Right(enrichedModels);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, CommissionRate>> getCommissionRate(int id) async {
    try {
      final model = await _remoteDataSource.getCommissionRate(id);

      // Enrich model with category name if categoryId is present
      if (model.categoryId != null) {
        try {
          final category = await _categoryRemoteDataSource.getCategory(model.categoryId!);
          final enrichedModel = CommissionRateModel(
            id: model.id,
            platform: model.platform,
            categoryId: model.categoryId,
            categoryName: category.name,
            rate: model.rate,
            isDefault: model.isDefault,
          );
          return Right(enrichedModel);
        } catch (e) {
          return Right(model);
        }
      }

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
