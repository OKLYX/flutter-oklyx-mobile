import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/exceptions.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/domain/entities/dashboard.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/domain/repositories/dashboard_repository.dart';

/// [DashboardRepository] implementation — where exceptions become [Failure]s
/// (FEATURE_2610_29).
class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;

  DashboardRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, DashboardLayout>> getLayout() =>
      _guard(remoteDataSource.getLayout);

  @override
  Future<Either<Failure, DashboardLayout>> saveMobileLayout(
          List<DashboardMobileCard> cards) =>
      _guard(() => remoteDataSource.saveMobileLayout(cards));

  static Future<Either<Failure, T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on DioException catch (e) {
      return Left(NetworkFailure(e.message ?? ''));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
