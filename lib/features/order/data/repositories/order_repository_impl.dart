import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/order_sync_result.dart';
import '../../domain/entities/sync_target.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_datasource.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;

  OrderRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<OrderItem>>> getOrders({int? sellerId}) async {
    try {
      final orders = await remoteDataSource.getOrders(sellerId: sellerId);
      return Right(orders.cast<OrderItem>());
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          e.message ?? 'Failed to fetch orders',
          statusCode: e.response?.statusCode,
        ),
      );
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrderSyncResult>> syncOrders({
    int? sellerId,
    int? accountId,
  }) async {
    try {
      final result = await remoteDataSource.syncOrders(
        sellerId: sellerId,
        accountId: accountId,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          e.message ?? 'Failed to sync orders',
          statusCode: e.response?.statusCode,
        ),
      );
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SyncTarget>>> getSyncTargets({int? sellerId}) async {
    try {
      final targets = await remoteDataSource.getSyncTargets(sellerId: sellerId);
      return Right(targets.cast<SyncTarget>());
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          e.message ?? 'Failed to fetch sync targets',
          statusCode: e.response?.statusCode,
        ),
      );
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
