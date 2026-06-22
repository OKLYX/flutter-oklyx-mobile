import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/domain/entities/purchase_list_item.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/domain/repositories/purchase_list_repository.dart';
import '../datasources/purchase_list_remote_datasource.dart';
import '../models/adjust_manual_qty_params.dart';
import '../models/record_purchase_params.dart';

class PurchaseListRepositoryImpl implements PurchaseListRepository {
  final PurchaseListRemoteDataSource remoteDataSource;

  PurchaseListRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<PurchaseListItem>>> getList(int? sellerId) async {
    try {
      final models = await remoteDataSource.getList(sellerId);
      return Right(models.cast<PurchaseListItem>());
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

  @override
  Future<Either<Failure, List<PurchaseListItem>>> extract(int? sellerId) async {
    try {
      final models = await remoteDataSource.extract(sellerId);
      return Right(models.cast<PurchaseListItem>());
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

  @override
  Future<Either<Failure, void>> recordPurchase(
    int itemId,
    String purchasedOn,
    int quantity,
  ) async {
    try {
      await remoteDataSource.recordPurchase(
        itemId,
        RecordPurchaseParams(purchasedOn: purchasedOn, quantity: quantity),
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          e.message ?? 'Failed to record purchase',
          statusCode: e.response?.statusCode,
        ),
      );
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
      return Left(
        ServerFailure(
          e.message ?? 'Failed to adjust quantity',
          statusCode: e.response?.statusCode,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
