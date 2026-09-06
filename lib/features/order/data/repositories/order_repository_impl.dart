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
import '../models/cancel_reason_option.dart';
import '../models/order_acknowledge_result.dart';
import '../models/order_cancel_result.dart';

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

  @override
  Future<Either<Failure, List<CancelReasonOption>>> getCancelReasons() async {
    try {
      final reasons = await remoteDataSource.getCancelReasons();
      return Right(reasons);
    } on DioException catch (e) {
      // statusCode 를 살려 보낸다 — 이 조회도 ADMIN 전용이라 403 이 섹션 숨김 신호다.
      return Left(
        ServerFailure(
          e.message ?? 'Failed to fetch cancel reasons',
          statusCode: e.response?.statusCode,
        ),
      );
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrderCancelResult>> cancelOrders(
    List<Map<String, dynamic>> lines,
    String reason,
  ) async {
    try {
      final result = await remoteDataSource.cancelOrders(lines, reason);
      return Right(result);
    } on DioException catch (e) {
      // 400 은 사유가 여럿(수량 초과·빈 요청·라인 없음)이라 서버 본문 message 를 살린다.
      final body = e.response?.data;
      final message = body is Map && body['message'] != null
          ? body['message'].toString()
          : (e.message ?? 'Failed to cancel orders');
      return Left(
        ServerFailure(message, statusCode: e.response?.statusCode),
      );
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
