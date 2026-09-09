import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../domain/entities/outbound_order.dart';
import '../../domain/entities/purchase_candidate.dart';
import '../../domain/entities/return_candidate.dart';
import '../../domain/entities/stock_balance.dart';
import '../../domain/entities/stock_enums.dart';
import '../../domain/entities/stock_movement.dart';
import '../../domain/repositories/stock_ledger_repository.dart';
import '../datasources/stock_ledger_remote_datasource.dart';
import '../models/confirm_outbound_params.dart';
import '../models/record_movement_params.dart';

class StockLedgerRepositoryImpl implements StockLedgerRepository {
  final StockLedgerRemoteDataSource remoteDataSource;

  StockLedgerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<StockBalance>>> balances({
    int? productId,
    int? sellerId,
    String? keyword,
  }) async {
    try {
      final models = await remoteDataSource.balances(productId, sellerId, keyword);
      return Right(models.cast<StockBalance>());
    } on DioException catch (e) {
      return Left(_failure(e, 'Failed to load stock balances'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<StockMovement>>> movements({
    int? productId,
    int? sellerId,
    String? from,
    String? to,
  }) async {
    try {
      final models = await remoteDataSource.movements(productId, sellerId, from, to);
      return Right(models.cast<StockMovement>());
    } on DioException catch (e) {
      return Left(_failure(e, 'Failed to load stock movements'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, StockMovement>> record({
    required int productId,
    int? sellerId,
    required StockMovementType movementType,
    required int quantity,
    StockReason? reason,
    String? reasonNote,
    double? unitPrice,
    int? orderClaimId,
    int? purchaseRecordId,
    required String movedOn,
  }) async {
    try {
      final model = await remoteDataSource.record(RecordMovementParams(
        productId: productId,
        sellerId: sellerId,
        movementType: movementType,
        quantity: quantity,
        reason: reason,
        reasonNote: reasonNote,
        unitPrice: unitPrice,
        orderClaimId: orderClaimId,
        purchaseRecordId: purchaseRecordId,
        movedOn: movedOn,
      ));
      return Right(model);
    } on DioException catch (e) {
      return Left(_failure(e, 'Failed to record stock movement'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PurchaseCandidate>>> purchaseCandidates({
    int? productId,
  }) async {
    try {
      final models = await remoteDataSource.purchaseCandidates(productId);
      return Right(models.cast<PurchaseCandidate>());
    } on DioException catch (e) {
      return Left(_failure(e, 'Failed to load purchase candidates'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ReturnCandidate>>> returnCandidates() async {
    try {
      final models = await remoteDataSource.returnCandidates();
      return Right(models.cast<ReturnCandidate>());
    } on DioException catch (e) {
      return Left(_failure(e, 'Failed to load return candidates'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OutboundResult>> outbound({
    int? sellerId,
    String? status,
  }) async {
    try {
      return Right(await remoteDataSource.outbound(sellerId, status));
    } on DioException catch (e) {
      return Left(_failure(e, 'Failed to load outbound orders'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<StockMovement>>> confirmOutbound({
    required int orderLineId,
    required int productId,
    required int quantity,
    required String movedOn,
  }) async {
    try {
      final models = await remoteDataSource.confirmOutbound(ConfirmOutboundParams(
        orderLineId: orderLineId,
        productId: productId,
        quantity: quantity,
        movedOn: movedOn,
      ));
      return Right(models.cast<StockMovement>());
    } on DioException catch (e) {
      return Left(_failure(e, 'Failed to confirm outbound'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// 서버 원본 메시지를 우선 노출한다 — 조합 규칙 위반(400)의 사유가 그대로 보여야 한다.
  ServerFailure _failure(DioException e, String fallback) {
    final data = e.response?.data;
    final serverMessage =
        data is Map<String, dynamic> ? data['message'] as String? : null;
    return ServerFailure(
      serverMessage ?? e.message ?? fallback,
      statusCode: e.response?.statusCode,
    );
  }
}
