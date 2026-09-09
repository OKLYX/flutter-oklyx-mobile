import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/domain/entities/purchase_list_item.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/domain/entities/purchase_list_result.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/domain/entities/purchase_record.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/domain/entities/purchase_record_result.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/domain/repositories/purchase_list_repository.dart';
import '../datasources/purchase_list_remote_datasource.dart';
import '../models/add_manual_params.dart';
import '../models/adjust_manual_qty_params.dart';
import '../models/record_purchase_params.dart';

class PurchaseListRepositoryImpl implements PurchaseListRepository {
  final PurchaseListRemoteDataSource remoteDataSource;

  PurchaseListRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, PurchaseListResult>> getList() async {
    try {
      return Right(await remoteDataSource.getList());
    } on DioException catch (e) {
      return Left(_failure(e, 'Server error occurred'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PurchaseListResult>> extract() async {
    try {
      return Right(await remoteDataSource.extract());
    } on DioException catch (e) {
      return Left(_failure(e, 'Server error occurred'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PurchaseListItem>>> getCompleted(
    String? from,
    String? to,
  ) async {
    try {
      final models = await remoteDataSource.getCompleted(from, to);
      return Right(models.cast<PurchaseListItem>());
    } on DioException catch (e) {
      return Left(_failure(e, 'Server error occurred'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PurchaseRecordResult>> recordPurchase(
    int productId,
    int sellerId,
    String purchasedOn,
    int quantity, {
    double? totalAmount,
    double? unitPrice,
    bool reflectToBasePrice = true,
    bool recordStock = true,
  }) async {
    try {
      final result = await remoteDataSource.recordPurchase(
        RecordPurchaseParams(
          productId: productId,
          sellerId: sellerId,
          purchasedOn: purchasedOn,
          quantity: quantity,
          totalAmount: totalAmount,
          unitPrice: unitPrice,
          reflectToBasePrice: reflectToBasePrice,
          recordStock: recordStock,
        ),
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(_failure(e, 'Failed to record purchase'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PurchaseRecord>>> recentPurchases(
    int productId, {
    int limit = 5,
  }) async {
    try {
      final models = await remoteDataSource.recentPurchases(productId, limit);
      return Right(models.cast<PurchaseRecord>());
    } on DioException catch (e) {
      return Left(_failure(e, 'Failed to load recent purchases'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> adjustManualQty(int itemId, int manualQty) async {
    try {
      await remoteDataSource.adjustManualQty(
        itemId,
        AdjustManualQtyParams(manualQty: manualQty),
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(_failure(e, 'Failed to adjust quantity'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addManual(int productId, int quantity) async {
    try {
      await remoteDataSource.addManual(
        AddManualParams(productId: productId, quantity: quantity),
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(_failure(e, 'Failed to add manual item'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// 서버 원본 메시지를 우선 노출한다(입고 실패 사유가 그대로 보여야 한다).
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
