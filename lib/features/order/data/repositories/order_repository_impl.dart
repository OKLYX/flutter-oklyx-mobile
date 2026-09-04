import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/order_period.dart';
import '../../domain/entities/order_sync_result.dart';
import '../../domain/entities/order_sync_scope.dart';
import '../../domain/entities/sync_target.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_datasource.dart';
import '../models/order_acknowledge_result.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;

  OrderRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<OrderItem>>> getOrders({
    int? sellerId,
    String? from,
    String? to,
  }) async {
    try {
      final orders = await remoteDataSource.getOrders(
        sellerId: sellerId,
        from: from,
        to: to,
      );
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
    OrderSyncScope scope = OrderSyncScope.full,
  }) async {
    try {
      final result = await remoteDataSource.syncOrders(
        sellerId: sellerId,
        accountId: accountId,
        scope: scope,
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
  Future<Either<Failure, OrderSyncResult>> syncPeriod({
    required int accountId,
    required String from,
    required String to,
  }) async {
    try {
      final result = await remoteDataSource.syncPeriod(
        accountId: accountId,
        from: from,
        to: to,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          e.message ?? 'Failed to sync period',
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

  @override
  Future<Either<Failure, List<OrderMonth>>> getOrderMonths() async {
    try {
      final months = await remoteDataSource.getOrderMonths();
      return Right(months.cast<OrderMonth>());
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          e.message ?? 'Failed to fetch order months',
          statusCode: e.response?.statusCode,
        ),
      );
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrderAcknowledgeResult>> acknowledgeOrders(
    List<int> orderItemIds,
  ) async {
    try {
      final result = await remoteDataSource.acknowledgeOrders(orderItemIds);
      return Right(result);
    } on DioException catch (e) {
      // statusCode 를 살려 보낸다 — BLoC 이 403(ADMIN 아님)을 여기서만 알 수 있다.
      return Left(
        ServerFailure(
          e.message ?? 'Failed to acknowledge orders',
          statusCode: e.response?.statusCode,
        ),
      );
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
