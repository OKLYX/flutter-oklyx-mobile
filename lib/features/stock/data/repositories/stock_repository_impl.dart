import 'package:fpdart/fpdart.dart';

import 'package:flutter_oklyn_mobile/core/error/exceptions.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/stock/data/datasources/stock_remote_datasource.dart';
import 'package:flutter_oklyn_mobile/features/stock/data/exceptions/stock_exceptions.dart';
import 'package:flutter_oklyn_mobile/features/stock/data/models/batch_stock_item_model.dart';
import 'package:flutter_oklyn_mobile/features/stock/data/models/batch_stock_request_model.dart';
import 'package:flutter_oklyn_mobile/features/stock/data/models/get_stock_logs_params_model.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/entities/batch_stock_request_entity.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/entities/batch_stock_response_entity.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/entities/get_stock_logs_params_entity.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/entities/get_stock_logs_response_entity.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/entities/stock.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/repositories/stock_repository.dart';

class StockRepositoryImpl implements StockRepository {
  final StockRemoteDatasource remoteDatasource;

  StockRepositoryImpl(this.remoteDatasource);

  @override
  Future<Either<Failure, GetStockResponse>> getCurrentStock(String barcodeId) async {
    try {
      final response = await remoteDatasource.getCurrentStock(barcodeId);
      return Right(response);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on StockInsufficientException {
      return Left(ServerFailure('재고가 부족합니다'));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CreateStockResponse>> createStock(
    CreateStockRequest data,
  ) async {
    try {
      final response = await remoteDatasource.createStock(data);
      return Right(response);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on StockInsufficientException {
      return Left(ServerFailure('재고가 부족합니다'));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BatchStockResponseEntity>> createBatchStock(
    BatchStockRequestEntity request,
  ) async {
    try {
      final requestModel = BatchStockRequestModel(
        type: request.type,
        items: request.items
            .map((item) => BatchStockItemModel(
              barcodeId: item.barcodeId,
              quantity: item.quantity,
              name: item.name,
            ))
            .toList(),
      );

      final response = await remoteDatasource.createBatchStock(requestModel);
      return Right(response);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GetStockLogsResponseEntity>> getStockLogs(
    GetStockLogsParamsEntity params,
  ) async {
    try {
      final paramsModel = GetStockLogsParamsModel(
        barcodeId: params.barcodeId,
        productName: params.productName,
        startDate: params.startDate,
        endDate: params.endDate,
        page: params.page,
        size: params.size,
      );

      final response = await remoteDatasource.getStockLogs(paramsModel);
      return Right(response);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

}
