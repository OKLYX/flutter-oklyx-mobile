import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/exceptions.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/sales/data/datasources/sales_remote_datasource.dart';
import 'package:flutter_oklyn_mobile/features/sales/domain/entities/sales.dart';
import 'package:flutter_oklyn_mobile/features/sales/domain/repositories/sales_repository.dart';

/// [SalesRepository] implementation — the only place exceptions become
/// [Failure]s (FEATURE_2610_20).
///
/// 🔴 The status code travels in `ServerFailure.statusCode` — the screens tell
/// 403 apart by it (D20).
class SalesRepositoryImpl implements SalesRepository {
  final SalesRemoteDataSource remoteDataSource;

  SalesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<SellerSales>>> getSellerSummary(
          {required String from, required String to}) =>
      _guard(() => remoteDataSource.getSellerSummary(from: from, to: to));

  @override
  Future<Either<Failure, List<ChannelSales>>> getChannelSales(
          {required String from, required String to, int? sellerId}) =>
      _guard(() => remoteDataSource.getChannelSales(
          from: from, to: to, sellerId: sellerId));

  @override
  Future<Either<Failure, List<SalesLine>>> getSalesLines(
          {required String from, required String to, required int accountId}) =>
      _guard(() => remoteDataSource.getSalesLines(
          from: from, to: to, accountId: accountId));

  @override
  Future<Either<Failure, List<DailySales>>> getDailySales(
          {required String from, required String to, int? sellerId}) =>
      _guard(() => remoteDataSource.getDailySales(
          from: from, to: to, sellerId: sellerId));

  @override
  Future<Either<Failure, List<ProductProfit>>> getProductProfit({
    required String from,
    required String to,
    required bool crossChannel,
    int? sellerId,
  }) =>
      _guard(() => remoteDataSource.getProductProfit(
          from: from, to: to, crossChannel: crossChannel, sellerId: sellerId));

  @override
  Future<Either<Failure, SavingsSummary>> getSavingsSummary(
          {required String from, required String to}) =>
      _guard(() => remoteDataSource.getSavingsSummary(from: from, to: to));

  @override
  Future<Either<Failure, List<OptionSaving>>> getOptionSavings(
          {required String from, required String to, int? sellerId}) =>
      _guard(() => remoteDataSource.getOptionSavings(
          from: from, to: to, sellerId: sellerId));

  @override
  Future<Either<Failure, List<BoxSaving>>> getBoxSavings(
          {required String from, required String to}) =>
      _guard(() => remoteDataSource.getBoxSavings(from: from, to: to));

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
